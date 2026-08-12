//
//  SessionMigrationHelper.swift
//  Studio Guru
//
//  Session management migration and utility functions

import Foundation
import SwiftData

/// Helper utilities for migrating existing Studio Guru data to the new Session management system
struct SessionMigrationHelper {
    
    /// Creates a configuration snapshot from a studio's current state
    /// This captures devices, connections, and canvas annotations for historical preservation
    static func createSnapshotFromStudio(
        session: Session,
        studio: Studio,
        modelContext: ModelContext
    ) throws -> SessionConfigurationSnapshot {
        
        let snapshot = SessionConfigurationSnapshot(sessionID: session.id)
        
        // Copy devices to snapshot
        if let devices = studio.devices {
            for device in devices {
                let snapshotDevice = SnapshotDevice(
                    originalDeviceID: device.id,
                    manufacturer: device.manufacturer,
                    model: device.model,
                    nickname: device.nickname
                )
                snapshotDevice.categoryRaw = device.categoryRaw
                snapshotDevice.serialNumber = device.serialNumber
                snapshotDevice.location = device.location
                snapshotDevice.posX = device.posX
                snapshotDevice.posY = device.posY
                snapshotDevice.scale = device.scale
                snapshotDevice.zIndex = device.zIndex
                snapshotDevice.snapshot = snapshot
                
                modelContext.insert(snapshotDevice)
            }
        }
        
        // Copy connections to snapshot
        if let connections = studio.connections {
            for connection in connections {
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
                
                modelContext.insert(snapshotConnection)
            }
        }
        
        // Copy canvas annotations
        snapshot.canvasDrawingData = studio.canvasDrawingData
        
        // Store complete studio state as serialized data for future reference
        let exportableStudio = ExportableStudio(from: studio)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        snapshot.snapshotData = try encoder.encode(exportableStudio)
        
        modelContext.insert(snapshot)
        
        return snapshot
    }
    
    /// Restore a session's configuration snapshot to a studio
    /// This allows users to recall a previous session setup
    static func restoreSnapshotToStudio(
        snapshot: SessionConfigurationSnapshot,
        targetStudio: Studio,
        modelContext: ModelContext
    ) throws {
        
        // Clear existing studio setup (optional - could be a parameter)
        // For now, we'll just add the snapshot devices/connections
        
        // Map of snapshot device IDs to new device instances
        var deviceMapping: [UUID: DeviceInstance] = [:]
        
        // Restore devices from snapshot
        if let snapshotDevices = snapshot.devices {
            for snapshotDevice in snapshotDevices {
                let newDevice = DeviceInstance(
                    manufacturer: snapshotDevice.manufacturer,
                    model: snapshotDevice.model,
                    nickname: snapshotDevice.nickname
                )
                newDevice.categoryRaw = snapshotDevice.categoryRaw
                newDevice.serialNumber = snapshotDevice.serialNumber
                newDevice.location = snapshotDevice.location
                newDevice.posX = snapshotDevice.posX
                newDevice.posY = snapshotDevice.posY
                newDevice.scale = snapshotDevice.scale
                newDevice.zIndex = snapshotDevice.zIndex
                newDevice.studio = targetStudio
                
                deviceMapping[snapshotDevice.originalDeviceID] = newDevice
                modelContext.insert(newDevice)
            }
        }
        
        // Restore connections from snapshot
        if let snapshotConnections = snapshot.connections {
            for snapshotConnection in snapshotConnections {
                let newConnection = Connection(
                    fromDeviceId: snapshotConnection.fromDeviceId,
                    fromPortId: snapshotConnection.fromPortId,
                    fromChannelId: snapshotConnection.fromChannelId,
                    toDeviceId: snapshotConnection.toDeviceId,
                    toPortId: snapshotConnection.toPortId,
                    toChannelId: snapshotConnection.toChannelId,
                    label: snapshotConnection.label
                )
                newConnection.cableRaw = snapshotConnection.cableRaw
                newConnection.notes = snapshotConnection.notes
                newConnection.studio = targetStudio
                
                modelContext.insert(newConnection)
            }
        }
        
        // Restore canvas annotations
        targetStudio.canvasDrawingData = snapshot.canvasDrawingData
        targetStudio.markAsModified()
    }
    
    /// Add gear locker equipment to a session
    static func addGearToSession(
        session: Session,
        equipment: DeviceInstance,
        purpose: String = "",
        modelContext: ModelContext
    ) -> SessionEquipment {
        
        let sessionEquipment = SessionEquipment(
            sessionID: session.id,
            equipmentID: equipment.id,
            purpose: purpose
        )
        sessionEquipment.session = session
        
        modelContext.insert(sessionEquipment)
        
        return sessionEquipment
    }
    
    /// Create a session template from an existing session
    /// This allows users to reuse successful session configurations
    static func duplicateSessionConfiguration(
        sourceSession: Session,
        targetSession: Session,
        includeParticipants: Bool = true,
        includeEquipment: Bool = true,
        modelContext: ModelContext
    ) throws {
        
        // Copy configuration snapshot
        if let sourceSnapshot = sourceSession.configurationSnapshot {
            let newSnapshot = SessionConfigurationSnapshot(sessionID: targetSession.id)
            newSnapshot.snapshotData = sourceSnapshot.snapshotData
            newSnapshot.canvasDrawingData = sourceSnapshot.canvasDrawingData
            newSnapshot.snapshotVersion = sourceSnapshot.snapshotVersion
            
            modelContext.insert(newSnapshot)
            targetSession.configurationSnapshot = newSnapshot
            
            // Copy snapshot devices
            if let devices = sourceSnapshot.devices {
                for device in devices {
                    let newDevice = SnapshotDevice(
                        originalDeviceID: device.originalDeviceID,
                        manufacturer: device.manufacturer,
                        model: device.model,
                        nickname: device.nickname
                    )
                    newDevice.categoryRaw = device.categoryRaw
                    newDevice.serialNumber = device.serialNumber
                    newDevice.location = device.location
                    newDevice.posX = device.posX
                    newDevice.posY = device.posY
                    newDevice.scale = device.scale
                    newDevice.zIndex = device.zIndex
                    newDevice.configurationData = device.configurationData
                    newDevice.snapshot = newSnapshot
                    
                    modelContext.insert(newDevice)
                }
            }
            
            // Copy snapshot connections
            if let connections = sourceSnapshot.connections {
                for connection in connections {
                    let newConnection = SnapshotConnection(
                        originalConnectionID: connection.originalConnectionID,
                        fromDeviceId: connection.fromDeviceId,
                        fromPortId: connection.fromPortId,
                        fromChannelId: connection.fromChannelId,
                        toDeviceId: connection.toDeviceId,
                        toPortId: connection.toPortId,
                        toChannelId: connection.toChannelId,
                        label: connection.label
                    )
                    newConnection.cableRaw = connection.cableRaw
                    newConnection.notes = connection.notes
                    newConnection.snapshot = newSnapshot
                    
                    modelContext.insert(newConnection)
                }
            }
        }
        
        // Copy participants if requested
        if includeParticipants, let participants = sourceSession.participants {
            for participant in participants {
                let newParticipant = SessionParticipant(
                    sessionID: targetSession.id,
                    personID: participant.personID,
                    role: participant.role
                )
                newParticipant.notes = participant.notes
                newParticipant.session = targetSession
                
                modelContext.insert(newParticipant)
            }
        }
        
        // Copy equipment if requested
        if includeEquipment, let equipment = sourceSession.equipment {
            for item in equipment {
                let newEquipment = SessionEquipment(
                    sessionID: targetSession.id,
                    equipmentID: item.equipmentID,
                    purpose: item.purpose
                )
                newEquipment.workID = item.workID
                newEquipment.personID = item.personID
                newEquipment.settings = item.settings
                newEquipment.notes = item.notes
                newEquipment.session = targetSession
                
                modelContext.insert(newEquipment)
            }
        }
    }
}

// MARK: - Query Helpers

extension SessionMigrationHelper {
    
    /// Get all sessions for a specific studio
    static func sessionsForStudio(studioID: UUID, modelContext: ModelContext) throws -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.studioID == studioID },
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get all sessions for a specific project
    static func sessionsForProject(projectID: UUID, modelContext: ModelContext) throws -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get all sessions where a person participated
    static func sessionsForPerson(personID: UUID, modelContext: ModelContext) throws -> [Session] {
        let participantDescriptor = FetchDescriptor<SessionParticipant>(
            predicate: #Predicate { $0.personID == personID }
        )
        let participants = try modelContext.fetch(participantDescriptor)
        let sessionIDs = Set(participants.map { $0.sessionID })
        
        let sessionDescriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        let allSessions = try modelContext.fetch(sessionDescriptor)
        
        return allSessions.filter { sessionIDs.contains($0.id) }
    }
    
    /// Get all sessions where a work was recorded
    static func sessionsForWork(workID: UUID, modelContext: ModelContext) throws -> [Session] {
        let workDescriptor = FetchDescriptor<SessionWork>(
            predicate: #Predicate { $0.workID == workID }
        )
        let sessionWorks = try modelContext.fetch(workDescriptor)
        let sessionIDs = Set(sessionWorks.map { $0.sessionID })
        
        let sessionDescriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        let allSessions = try modelContext.fetch(sessionDescriptor)
        
        return allSessions.filter { sessionIDs.contains($0.id) }
    }
    
    /// Get all sessions where specific equipment was used
    static func sessionsForEquipment(equipmentID: UUID, modelContext: ModelContext) throws -> [Session] {
        let equipmentDescriptor = FetchDescriptor<SessionEquipment>(
            predicate: #Predicate { $0.equipmentID == equipmentID }
        )
        let equipment = try modelContext.fetch(equipmentDescriptor)
        let sessionIDs = Set(equipment.map { $0.sessionID })
        
        let sessionDescriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        let allSessions = try modelContext.fetch(sessionDescriptor)
        
        return allSessions.filter { sessionIDs.contains($0.id) }
    }
}
