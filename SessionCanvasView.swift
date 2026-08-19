//
//  SessionCanvasView.swift
//  Studio Guru
//
//  Canvas view for editing session setup - wrapper around StudioCanvasView
//  that operates on SessionConfigurationSnapshot
//

import SwiftUI
import SwiftData

struct SessionCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager
    
    let session: Session
    
    @State private var showingAddGear = false
    @State private var showingAddArtistGear = false
    @State private var showingDuplicateOptions = false
    @State private var sessionsForDuplication: [Session] = []
    
    var snapshot: SessionConfigurationSnapshot? {
        session.configurationSnapshot
    }
    
    var body: some View {
        NavigationStack {
            if let snapshot = snapshot {
                SessionCanvasContent(session: session, snapshot: snapshot)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { dismiss() }
                        }
                        
                        ToolbarItemGroup(placement: .primaryAction) {
                            Menu {
                                Button {
                                    showingAddGear = true
                                } label: {
                                    Label("Add from Gear Locker", systemImage: "archivebox")
                                }
                                
                                Button {
                                    showingAddArtistGear = true
                                } label: {
                                    Label("Add Artist Gear", systemImage: "person.badge.plus")
                                }
                                
                                Divider()
                                
                                Button {
                                    loadSessionsForDuplication()
                                    showingDuplicateOptions = true
                                } label: {
                                    Label("Duplicate from Session", systemImage: "doc.on.doc")
                                }
                            } label: {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
            } else {
                ContentUnavailableView(
                    "No Canvas Available",
                    systemImage: "square.grid.3x3",
                    description: Text("Assign a studio to this session to create a canvas")
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGear) {
            AddSessionGearView(session: session, onGearAdded: {})
        }
        .sheet(isPresented: $showingAddArtistGear) {
            AddArtistGearView(session: session, onGearAdded: {})
        }
        .sheet(isPresented: $showingDuplicateOptions) {
            DuplicateSessionCanvasView(
                session: session,
                availableSessions: sessionsForDuplication,
                onDuplicated: { dismiss() }
            )
        }
    }
    
    private func loadSessionsForDuplication() {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        
        if let allSessions = try? modelContext.fetch(descriptor) {
            // Filter to sessions that have a snapshot and aren't this session
            sessionsForDuplication = allSessions.filter {
                $0.id != session.id && $0.configurationSnapshot != nil
            }
        }
    }
}

// MARK: - Canvas Content View

struct SessionCanvasContent: View {
    @Environment(\.modelContext) private var modelContext
    
    let session: Session
    let snapshot: SessionConfigurationSnapshot
    
    @State private var selectedDeviceId: UUID?
    @State private var dragOffset: CGSize = .zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var showingDeviceDetail = false
    
    var devices: [SnapshotDevice] {
        snapshot.devices ?? []
    }
    
    var connections: [SnapshotConnection] {
        snapshot.connections ?? []
    }
    
    var body: some View {
        if devices.isEmpty {
            ContentUnavailableView(
                "No Devices on Canvas",
                systemImage: "square.dashed",
                description: Text("Add gear from the locker or artist gear using the Add menu")
            )
            .navigationTitle("Session Canvas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        } else {
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    CanvasGridBackground()
                    
                    // Connections layer
                    ForEach(connections) { connection in
                        ConnectionLine(
                            connection: connection,
                            devices: devices,
                            scale: canvasScale
                        )
                    }
                    
                    // Devices layer
                    ForEach(devices) { device in
                        SessionDeviceView(
                            device: device,
                            isSelected: selectedDeviceId == device.id,
                            scale: canvasScale
                        )
                        .position(
                            x: device.posX * canvasScale,
                            y: device.posY * canvasScale
                        )
                        .onTapGesture {
                            selectedDeviceId = device.id
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            canvasScale = min(max(value, 0.5), 2.0)
                        }
                )
            }
            .navigationTitle("Session Canvas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - Device View

struct SessionDeviceView: View {
    let device: SnapshotDevice
    let isSelected: Bool
    let scale: CGFloat
    
    private var deviceColor: Color {
        switch device.ownershipType {
        case .studioOwned: return .blue
        case .gearLocker: return .purple
        case .artistProvided: return .orange
        case .rental: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Device icon
            Image(systemName: iconForCategory(device.category))
                .font(.title2)
                .foregroundStyle(deviceColor)
            
            // Device name
            Text(device.nickname.isEmpty ? device.model : device.nickname)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 100 * scale)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(deviceColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? deviceColor : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(scale)
    }
    
    private func iconForCategory(_ category: DeviceCategory) -> String {
        switch category {
        case .microphone: return "mic"
        case .preamp: return "waveform.circle"
        case .audioInterface: return "hifispeaker.2"
        case .mixer: return "dial.medium"
        case .monitor: return "speaker.wave.2"
        case .keyboard: return "pianokeys"
        case .synth: return "waveform.and.person.filled"
        case .computer: return "desktopcomputer"
        default: return "shippingbox"
        }
    }
}

// MARK: - Connection Line

struct ConnectionLine: View {
    let connection: SnapshotConnection
    let devices: [SnapshotDevice]
    let scale: CGFloat
    
    var sourceDevice: SnapshotDevice? {
        devices.first { $0.id == connection.fromDeviceId }
    }
    
    var destinationDevice: SnapshotDevice? {
        devices.first { $0.id == connection.toDeviceId }
    }
    
    var body: some View {
        if let source = sourceDevice, let dest = destinationDevice {
            Path { path in
                let start = CGPoint(x: source.posX * scale, y: source.posY * scale)
                let end = CGPoint(x: dest.posX * scale, y: dest.posY * scale)
                
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
        }
    }
}

// MARK: - Canvas Grid Background

struct CanvasGridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 50
                
                // Vertical lines
                for x in stride(from: 0, through: geometry.size.width, by: gridSize) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for y in stride(from: 0, through: geometry.size.height, by: gridSize) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        }
        .background(Color(#colorLiteral(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)))
    }
}

// MARK: - Duplicate Session Canvas View

struct DuplicateSessionCanvasView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: Session
    let availableSessions: [Session]
    let onDuplicated: () -> Void
    
    @State private var selectedSession: Session?
    
    var body: some View {
        NavigationStack {
            List {
                if availableSessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions Available",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("There are no other sessions with canvas setups to duplicate from")
                    )
                } else {
                    ForEach(availableSessions) { sourceSession in
                        Button {
                            selectedSession = sourceSession
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sourceSession.name)
                                        .font(.headline)
                                    
                                    Text(formatDate(sourceSession.sessionDate))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    if let deviceCount = sourceSession.configurationSnapshot?.devices?.count {
                                        Text("\(deviceCount) devices")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedSession?.id == sourceSession.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Duplicate Canvas From")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Duplicate") {
                        duplicateCanvas()
                    }
                    .disabled(selectedSession == nil)
                }
            }
        }
    }
    
    private func duplicateCanvas() {
        guard let sourceSession = selectedSession,
              let sourceSnapshot = sourceSession.configurationSnapshot else {
            return
        }
        
        // Create new snapshot for target session or clear existing
        let newSnapshot = SessionConfigurationSnapshot(
            sessionID: session.id
        )
        
        // Copy all devices
        for sourceDevice in sourceSnapshot.devices ?? [] {
            let deviceCopy = SnapshotDevice(
                originalDeviceID: sourceDevice.originalDeviceID,
                manufacturer: sourceDevice.manufacturer,
                model: sourceDevice.model,
                nickname: sourceDevice.nickname,
                ownershipType: sourceDevice.ownershipType
            )
            
            deviceCopy.ownerName = sourceDevice.ownerName
            deviceCopy.settingsNotes = sourceDevice.settingsNotes
            deviceCopy.categoryRaw = sourceDevice.categoryRaw
            deviceCopy.posX = sourceDevice.posX
            deviceCopy.posY = sourceDevice.posY
            deviceCopy.scale = sourceDevice.scale
            deviceCopy.zIndex = sourceDevice.zIndex
            deviceCopy.snapshot = newSnapshot
            
            newSnapshot.devices?.append(deviceCopy)
            modelContext.insert(deviceCopy)
        }
        
        // Copy all connections
        for sourceConnection in sourceSnapshot.connections ?? [] {
            let connectionCopy = SnapshotConnection(
                originalConnectionID: sourceConnection.originalConnectionID,
                fromDeviceId: sourceConnection.fromDeviceId,
                fromPortId: sourceConnection.fromPortId,
                fromChannelId: sourceConnection.fromChannelId,
                toDeviceId: sourceConnection.toDeviceId,
                toPortId: sourceConnection.toPortId,
                toChannelId: sourceConnection.toChannelId,
                label: sourceConnection.label
            )
            
            connectionCopy.notes = sourceConnection.notes
            connectionCopy.snapshot = newSnapshot
            
            newSnapshot.connections?.append(connectionCopy)
            modelContext.insert(connectionCopy)
        }
        
        // Delete old snapshot if it exists
        if let oldSnapshot = session.configurationSnapshot {
            modelContext.delete(oldSnapshot)
        }
        
        session.configurationSnapshot = newSnapshot
        modelContext.insert(newSnapshot)
        
        do {
            try modelContext.save()
            onDuplicated()
            dismiss()
        } catch {
            print("❌ Failed to duplicate canvas: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
