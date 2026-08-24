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
        
        // Maps for translating IDs from template to session studio
        var deviceIDMap: [UUID: UUID] = [:]
        var portIDMap: [UUID: UUID] = [:]
        var channelIDMap: [UUID: UUID] = [:]

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

            // Map device IDs
            deviceIDMap[templateDevice.id] = deviceCopy.id

            // Copy ports and build port/channel ID maps
            for port in templateDevice.ports ?? [] {
                let portCopy = Port(
                    name: port.name,
                    type: port.type,
                    direction: port.direction
                )
                portCopy.device = deviceCopy
                deviceCopy.ports?.append(portCopy)
                modelContext.insert(portCopy)

                // Map port IDs
                portIDMap[port.id] = portCopy.id

                // Copy channels and map their IDs
                for channel in port.channels ?? [] {
                    let channelCopy = Channel(
                        index: channel.index,
                        nameLong: channel.nameLong,
                        nameShort: channel.nameShort,
                        signal: channel.signal,
                        grouping: channel.grouping
                    )
                    channelCopy.port = portCopy
                    portCopy.channels?.append(channelCopy)

                    // Map channel IDs
                    channelIDMap[channel.id] = channelCopy.id
                }
            }

            sessionStudio.devices?.append(deviceCopy)
            modelContext.insert(deviceCopy)
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
        
        // Copy connection bundles from template studio to session studio
        // Connection bundles are stored in SwiftData separately from the Studio model
        let templateStudioId = templateStudio.id
        let bundleDescriptor = FetchDescriptor<ConnectionBundleModel>(
            predicate: #Predicate { $0.studioId == templateStudioId }
        )

        if let templateBundles = try? modelContext.fetch(bundleDescriptor) {
            #if DEBUG
            print("📦 SessionStudioHelper: Found \(templateBundles.count) connection bundles to copy from template studio")
            #endif

            for templateBundle in templateBundles {
                // Map device IDs in the bundle
                guard let newFromDeviceID = deviceIDMap[templateBundle.fromDeviceId],
                      let newToDeviceID = deviceIDMap[templateBundle.toDeviceId] else {
                    continue
                }

                // Create new bundle for session studio
                let sessionBundle = ConnectionBundleModel(
                    id: UUID(), // New ID for the session bundle
                    studioId: sessionStudio.id,
                    fromDeviceId: newFromDeviceID,
                    toDeviceId: newToDeviceID
                )

                // Copy edges with mapped device, port, and channel IDs
                for templateEdge in templateBundle.edges ?? [] {
                    guard let newFromDevID = deviceIDMap[templateEdge.fromDeviceId],
                          let newToDevID = deviceIDMap[templateEdge.toDeviceId],
                          let newFromPortID = portIDMap[templateEdge.fromPortId],
                          let newToPortID = portIDMap[templateEdge.toPortId],
                          let newFromChannelID = channelIDMap[templateEdge.fromChannelId],
                          let newToChannelID = channelIDMap[templateEdge.toChannelId] else {
                        #if DEBUG
                        print("⚠️ Skipping edge - missing ID mapping")
                        #endif
                        continue
                    }

                    let sessionEdge = ConnectionEdgeModel(
                        id: UUID(),
                        fromDeviceId: newFromDevID,
                        fromPortId: newFromPortID,
                        fromChannelId: newFromChannelID,
                        fromDirection: templateEdge.fromDirection,
                        toDeviceId: newToDevID,
                        toPortId: newToPortID,
                        toChannelId: newToChannelID,
                        toDirection: templateEdge.toDirection,
                        fromName: templateEdge.fromName,
                        toName: templateEdge.toName
                    )
                    sessionBundle.edges?.append(sessionEdge)
                    modelContext.insert(sessionEdge)
                }

                // Copy endpoint names
                for templateName in templateBundle.endpointNames ?? [] {
                    let sessionName = EndpointNameModel(
                        endpointKey: templateName.endpointKey,
                        name: templateName.name
                    )
                    sessionBundle.endpointNames?.append(sessionName)
                    modelContext.insert(sessionName)
                }

                modelContext.insert(sessionBundle)

                #if DEBUG
                print("📦 SessionStudioHelper: Created connection bundle with \(sessionBundle.edges?.count ?? 0) edges for session studio")
                #endif
            }

            #if DEBUG
            print("📦 SessionStudioHelper: Finished copying connection bundles to session studio")
            #endif
        } else {
            #if DEBUG
            print("📦 SessionStudioHelper: No connection bundles found in template studio")
            #endif
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
