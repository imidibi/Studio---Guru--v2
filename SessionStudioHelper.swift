//
//  SessionStudioHelper.swift
//  Studio Guru
//
//  Helper for managing session-specific studio canvases
//

import Foundation
import SwiftData

struct SessionStudioHelper {
    
    /// Get or create a dedicated studio for this session
    /// This studio is a copy of the template studio that can be edited independently
    @MainActor
    static func getOrCreateSessionStudio(
        for session: Session,
        templateStudio: Studio,
        modelContext: ModelContext
    ) throws -> Studio {
        // If session already has a studio, return it
        if let sessionStudioID = session.sessionStudioID {
            let descriptor = FetchDescriptor<Studio>(
                predicate: #Predicate { $0.id == sessionStudioID }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                return existing
            }
        }
        
        // Create new session studio as a copy of the template
        let sessionStudio = Studio(name: "Session: \(session.name)")
        sessionStudio.isSystemStudio = true
        sessionStudio.systemStudioType = "session_studio"
        sessionStudio.layoutMode = templateStudio.layoutMode
        sessionStudio.gridSize = templateStudio.gridSize
        sessionStudio.showGridOverlay = templateStudio.showGridOverlay
        sessionStudio.canvasDrawingData = templateStudio.canvasDrawingData
        
        // Copy all devices from template studio
        for templateDevice in templateStudio.devices ?? [] {
            let deviceCopy = DeviceInstance(
                manufacturer: templateDevice.manufacturer,
                model: templateDevice.model,
                nickname: templateDevice.nickname,
                category: templateDevice.category,
                serialNumber: templateDevice.serialNumber,
                location: templateDevice.location,
                audioInputsCount: templateDevice.audioInputsCount,
                audioOutputsCount: templateDevice.audioOutputsCount,
                posX: templateDevice.posX,
                posY: templateDevice.posY
            )
            
            deviceCopy.scale = templateDevice.scale
            deviceCopy.zIndex = templateDevice.zIndex
            deviceCopy.categoryRaw = templateDevice.categoryRaw
            deviceCopy.studio = sessionStudio
            
            // Copy ports
            for port in templateDevice.ports ?? [] {
                let portCopy = Port(
                    name: port.name,
                    type: port.type,
                    direction: port.direction
                )
                portCopy.device = deviceCopy
                deviceCopy.ports?.append(portCopy)
                modelContext.insert(portCopy)
            }
            
            sessionStudio.devices?.append(deviceCopy)
            modelContext.insert(deviceCopy)
        }
        
        // Copy all connections from template studio
        // We need to map old device IDs to new device IDs
        var deviceIDMap: [UUID: UUID] = [:]
        for (index, templateDevice) in (templateStudio.devices ?? []).enumerated() {
            if let newDevice = sessionStudio.devices?[index] {
                deviceIDMap[templateDevice.id] = newDevice.id
            }
        }
        
        for templateConnection in templateStudio.connections ?? [] {
            guard let newFromDeviceID = deviceIDMap[templateConnection.fromDeviceId],
                  let newToDeviceID = deviceIDMap[templateConnection.toDeviceId] else {
                continue
            }
            
            let connectionCopy = Connection(
                fromDeviceId: newFromDeviceID,
                fromPortId: templateConnection.fromPortId,
                fromChannelId: templateConnection.fromChannelId,
                toDeviceId: newToDeviceID,
                toPortId: templateConnection.toPortId,
                toChannelId: templateConnection.toChannelId
            )
            
            connectionCopy.cableRaw = templateConnection.cableRaw
            connectionCopy.label = templateConnection.label
            connectionCopy.notes = templateConnection.notes
            connectionCopy.studio = sessionStudio
            
            sessionStudio.connections?.append(connectionCopy)
            modelContext.insert(connectionCopy)
        }
        
        // Save the session studio
        modelContext.insert(sessionStudio)
        
        // Link it to the session
        session.sessionStudioID = sessionStudio.id
        
        try modelContext.save()
        
        return sessionStudio
    }
    
    /// Save session studio changes back (if needed for cleanup/archiving)
    @MainActor
    static func archiveSessionStudio(
        for session: Session,
        modelContext: ModelContext
    ) throws {
        guard let sessionStudioID = session.sessionStudioID else { return }
        
        let descriptor = FetchDescriptor<Studio>(
            predicate: #Predicate { $0.id == sessionStudioID }
        )
        
        if let sessionStudio = try? modelContext.fetch(descriptor).first {
            // Could add archiving logic here if needed
            // For now, the studio remains in the database
            sessionStudio.markAsModified()
        }
    }
}
