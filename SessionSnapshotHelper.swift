//
//  SessionSnapshotHelper.swift
//  Studio Guru
//
//  Helper functions for creating and managing session configuration snapshots

import Foundation
import SwiftData

enum SessionSnapshotHelper {
    
    /// Create or update a session's configuration snapshot from a studio template
    /// This captures the studio's current state for use in the session
    @MainActor
    static func createOrUpdateSnapshot(
        for session: Session,
        from studio: Studio,
        modelContext: ModelContext
    ) throws {
        // Get or create the snapshot
        let snapshot: SessionConfigurationSnapshot
        
        if let existing = session.configurationSnapshot {
            // Update existing snapshot
            snapshot = existing
            // Clear existing devices and connections
            snapshot.devices?.removeAll()
            snapshot.connections?.removeAll()
        } else {
            // Create new snapshot
            snapshot = SessionConfigurationSnapshot(sessionID: session.id)
            snapshot.session = session
            session.configurationSnapshot = snapshot
            modelContext.insert(snapshot)
        }
        
        // Copy all devices from the studio
        if let studioDevices = studio.devices {
            for device in studioDevices {
                let snapshotDevice = SnapshotDevice(
                    originalDeviceID: device.id,
                    manufacturer: device.manufacturer,
                    model: device.model,
                    nickname: device.nickname,
                    ownershipType: device.isInGearLocker ? .gearLocker : .studioOwned
                )
                
                // Copy positioning and metadata
                snapshotDevice.posX = device.posX
                snapshotDevice.posY = device.posY
                snapshotDevice.scale = device.scale
                snapshotDevice.zIndex = device.zIndex
                snapshotDevice.categoryRaw = device.categoryRaw
                snapshotDevice.serialNumber = device.serialNumber
                snapshotDevice.location = device.location
                
                snapshotDevice.snapshot = snapshot
                snapshot.devices?.append(snapshotDevice)
                modelContext.insert(snapshotDevice)
            }
        }
        
        // Copy all connections from the studio
        if let studioConnections = studio.connections {
            for connection in studioConnections {
                let snapshotConnection = SnapshotConnection(
                    originalConnectionID: connection.id,
                    fromDeviceId: connection.fromDeviceId,
                    fromPortId: connection.fromPortId,
                    fromChannelId: connection.fromChannelId,
                    toDeviceId: connection.toDeviceId,
                    toPortId: connection.toPortId,
                    toChannelId: connection.toChannelId,
                    label: connection.label
                )
                
                snapshotConnection.cableRaw = connection.cableRaw
                snapshotConnection.notes = connection.notes ?? ""
                snapshotConnection.snapshot = snapshot
                snapshot.connections?.append(snapshotConnection)
                modelContext.insert(snapshotConnection)
            }
        }
        
        snapshot.markAsModified()
        
        try modelContext.save()
    }
    
    /// Add a device from the gear locker to a session's snapshot
    /// Creates a reservation for the gear
    @MainActor
    static func addGearLockerDevice(
        device: DeviceInstance,
        to session: Session,
        startDateTime: Date,
        endDateTime: Date,
        modelContext: ModelContext
    ) throws {
        // Check for conflicts
        if let conflicts = try checkReservationConflicts(
            for: device,
            start: startDateTime,
            end: endDateTime,
            excluding: nil,
            modelContext: modelContext
        ), !conflicts.isEmpty {
            let conflictSession = conflicts.first!
            throw ReservationError.conflict(
                deviceName: "\(device.manufacturer) \(device.model)",
                sessionName: conflictSession.name,
                startTime: conflictSession.sessionDate
            )
        }
        
        // Create reservation
        let reservation = GearReservation(
            deviceID: device.id,
            sessionID: session.id,
            studioID: session.studioID,
            startDateTime: startDateTime,
            endDateTime: endDateTime
        )
        reservation.device = device
        reservation.session = session
        modelContext.insert(reservation)
        
        // Add to snapshot
        guard let snapshot = session.configurationSnapshot else {
            throw ReservationError.noSnapshot
        }
        
        let snapshotDevice = SnapshotDevice(
            originalDeviceID: device.id,
            manufacturer: device.manufacturer,
            model: device.model,
            nickname: device.nickname,
            ownershipType: .gearLocker
        )
        
        snapshotDevice.categoryRaw = device.categoryRaw
        snapshotDevice.serialNumber = device.serialNumber
        snapshotDevice.snapshot = snapshot
        snapshot.devices?.append(snapshotDevice)
        modelContext.insert(snapshotDevice)
        
        try modelContext.save()
    }
    
    /// Add artist-provided gear to a session snapshot
    @MainActor
    static func addArtistGear(
        manufacturer: String,
        model: String,
        nickname: String,
        category: DeviceCategory,
        ownerName: String,
        settingsNotes: String,
        to session: Session,
        modelContext: ModelContext
    ) throws {
        guard let snapshot = session.configurationSnapshot else {
            throw ReservationError.noSnapshot
        }
        
        let snapshotDevice = SnapshotDevice(
            originalDeviceID: UUID(), // New UUID for artist gear
            manufacturer: manufacturer,
            model: model,
            nickname: nickname,
            ownershipType: .artistProvided
        )
        
        snapshotDevice.ownerName = ownerName
        snapshotDevice.settingsNotes = settingsNotes
        snapshotDevice.categoryRaw = category.rawValue
        snapshotDevice.snapshot = snapshot
        snapshot.devices?.append(snapshotDevice)
        modelContext.insert(snapshotDevice)
        
        try modelContext.save()
    }
    
    /// Check if a device has reservation conflicts for a given time range
    @MainActor
    static func checkReservationConflicts(
        for device: DeviceInstance,
        start: Date,
        end: Date,
        excluding reservationID: UUID? = nil,
        modelContext: ModelContext
    ) throws -> [Session]? {
        let deviceID = device.id
        
        let reservedStatus = ReservationStatus.reserved.rawValue
        let activeStatus = ReservationStatus.active.rawValue
        
        let descriptor = FetchDescriptor<GearReservation>(
            predicate: #Predicate { reservation in
                reservation.deviceID == deviceID &&
                (reservation.statusRaw == reservedStatus ||
                 reservation.statusRaw == activeStatus)
            }
        )
        
        let reservations = try modelContext.fetch(descriptor)
        
        // Filter out the reservation being edited (if any)
        let activeReservations = reservations.filter { reservation in
            if let excludeID = reservationID {
                return reservation.id != excludeID
            }
            return true
        }
        
        // Check for conflicts
        let conflicts = activeReservations.filter { reservation in
            reservation.conflictsWith(start: start, end: end)
        }
        
        if conflicts.isEmpty {
            return nil
        }
        
        // Fetch the conflicting sessions
        var conflictingSessions: [Session] = []
        for conflict in conflicts {
            let conflictSessionID = conflict.sessionID
            let sessionDescriptor = FetchDescriptor<Session>(
                predicate: #Predicate { $0.id == conflictSessionID }
            )
            if let session = try modelContext.fetch(sessionDescriptor).first {
                conflictingSessions.append(session)
            }
        }
        
        return conflictingSessions.isEmpty ? nil : conflictingSessions
    }
    
    /// Mark completed sessions' reservations as complete (auto-return to gear locker)
    @MainActor
    static func autoReturnCompletedReservations(modelContext: ModelContext) throws {
        let now = Date()
        
        let completedStatus = ReservationStatus.completed.rawValue
        let cancelledStatus = ReservationStatus.cancelled.rawValue
        
        let descriptor = FetchDescriptor<GearReservation>(
            predicate: #Predicate { reservation in
                reservation.endDateTime < now &&
                reservation.statusRaw != completedStatus &&
                reservation.statusRaw != cancelledStatus
            }
        )
        
        let expiredReservations = try modelContext.fetch(descriptor)
        
        for reservation in expiredReservations {
            reservation.status = .completed
            reservation.markAsModified()
        }
        
        if !expiredReservations.isEmpty {
            try modelContext.save()
            print("✅ Auto-returned \(expiredReservations.count) gear items to locker")
        }
    }
}

// MARK: - Errors

enum ReservationError: LocalizedError {
    case conflict(deviceName: String, sessionName: String, startTime: Date)
    case noSnapshot
    
    var errorDescription: String? {
        switch self {
        case .conflict(let deviceName, let sessionName, let startTime):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "'\(deviceName)' is already reserved for '\(sessionName)' starting \(formatter.string(from: startTime))"
        case .noSnapshot:
            return "Session must be assigned to a studio before adding gear"
        }
    }
}
