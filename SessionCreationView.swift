//
//  SessionCreationView.swift
//  Studio Guru
//
//  Session creation workflow

import SwiftUI
import SwiftData

struct SessionCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var studios: [Studio]
    @Query private var projects: [Project]
    
    @State private var name = ""
    @State private var selectedStudioID: UUID?
    @State private var selectedProjectID: UUID?
    @State private var sessionDate = Date()
    @State private var sessionType: SessionType = .tracking
    @State private var status: SessionStatus = .planned
    @State private var artistName = ""
    @State private var clientName = ""
    @State private var hasStartTime = false
    @State private var startTime = Date()
    @State private var hasEndTime = false
    @State private var endTime = Date()
    @State private var notes = ""
    @State private var createSnapshot = true
    
    var regularStudios: [Studio] {
        studios.filter { !$0.isSystemStudio }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("e.g., Vocal Tracking, Mix Session", text: $name)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                        }
                    }
                    
                    // Location & Type
                    GroupBox("Location & Type") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Studio")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Picker("Studio", selection: $selectedStudioID) {
                                    Text("Select Studio").tag(nil as UUID?)
                                    ForEach(regularStudios) { studio in
                                        Text(studio.name).tag(studio.id as UUID?)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Type")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Picker("Session Type", selection: $sessionType) {
                                    ForEach(SessionType.allCases, id: \.self) { type in
                                        Label(type.rawValue.capitalized, systemImage: iconForType(type))
                                            .tag(type)
                                    }
                                }
                                .labelsHidden()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Status")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Picker("Status", selection: $status) {
                                    ForEach(SessionStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue.capitalized).tag(status)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                    
                    // Project
                    GroupBox("Project (Optional)") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Link to Project")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Project", selection: $selectedProjectID) {
                                Text("None").tag(nil as UUID?)
                                ForEach(projects.filter { !$0.isArchived && $0.status == .active }) { project in
                                    Text(project.name).tag(project.id as UUID?)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    
                    // Date & Time
                    GroupBox("Date & Time") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Date")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                DatePicker("Session Date", selection: $sessionDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .datePickerStyle(.graphical)
                            }
                            
                            Divider()
                            
                            Toggle("Include Start Time", isOn: $hasStartTime)
                            if hasStartTime {
                                DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            
                            Toggle("Include End Time", isOn: $hasEndTime)
                            if hasEndTime {
                                DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    // Client Information
                    GroupBox("Client Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Artist Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Artist or band name", text: $artistName)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Label, producer, or client", text: $clientName)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                        }
                    }
                    
                    // Studio Configuration
                    GroupBox("Studio Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Capture Studio Snapshot", isOn: $createSnapshot)
                            
                            if createSnapshot {
                                Text("Saves the current studio configuration (devices and connections) with this session for historical reference.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .overlay(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Add any notes about this session...")
                                            .foregroundStyle(.tertiary)
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("New Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createSession() }
                        .disabled(name.isEmpty || selectedStudioID == nil)
                }
            }
        }
    }
    
    private func iconForType(_ type: SessionType) -> String {
        switch type {
        case .tracking: return "waveform.circle"
        case .overdub: return "waveform.badge.plus"
        case .songwriting: return "pencil.and.outline"
        case .rehearsal: return "figure.walk"
        case .editing: return "scissors"
        case .mixing: return "slider.horizontal.3"
        case .mastering: return "sparkles"
        case .podcast: return "mic"
        case .liveRecording: return "record.circle"
        case .other: return "ellipsis.circle"
        }
    }
    
    private func createSession() {
        guard let studioID = selectedStudioID else { return }
        
        // Create session
        let session = Session(studioID: studioID, name: name, sessionDate: sessionDate)
        session.projectID = selectedProjectID
        session.sessionType = sessionType
        session.status = status
        session.artistName = artistName
        session.clientName = clientName
        session.startTime = hasStartTime ? startTime : nil
        session.endTime = hasEndTime ? endTime : nil
        session.notes = notes
        
        modelContext.insert(session)
        
        // Create snapshot if requested
        if createSnapshot {
            if let studio = studios.first(where: { $0.id == studioID }) {
                do {
                    _ = try SessionMigrationHelper.createSnapshotFromStudio(
                        session: session,
                        studio: studio,
                        modelContext: modelContext
                    )
                } catch {
                    print("Error creating snapshot: \(error)")
                }
            }
        }
        
        dismiss()
    }
}

#Preview {
    SessionCreationView()
        .modelContainer(for: [Session.self, Studio.self, Project.self], inMemory: true)
}
