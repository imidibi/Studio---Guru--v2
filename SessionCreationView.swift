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
            Form {
                Section("Basic Information") {
                    TextField("Session Name", text: $name)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    
                    if name.isEmpty {
                        Text("e.g., \"Vocal Tracking\", \"Mix Session\", \"Band Rehearsal\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Location & Type") {
                    Picker("Studio", selection: $selectedStudioID) {
                        Text("Select Studio").tag(nil as UUID?)
                        ForEach(regularStudios) { studio in
                            Text(studio.name).tag(studio.id as UUID?)
                        }
                    }
                    
                    Picker("Session Type", selection: $sessionType) {
                        ForEach(SessionType.allCases, id: \.self) { type in
                            Label(type.rawValue.capitalized, systemImage: iconForType(type))
                                .tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(SessionStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                Section("Project (Optional)") {
                    Picker("Project", selection: $selectedProjectID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(projects.filter { !$0.isArchived && $0.status == .active }) { project in
                            VStack(alignment: .leading) {
                                Text(project.name)
                                if !project.artistName.isEmpty {
                                    Text(project.artistName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tag(project.id as UUID?)
                        }
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Session Date", selection: $sessionDate, displayedComponents: .date)
                    
                    Toggle("Start Time", isOn: $hasStartTime)
                    if hasStartTime {
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle("End Time", isOn: $hasEndTime)
                    if hasEndTime {
                        DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }
                
                Section("Client Information") {
                    TextField("Artist Name", text: $artistName)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    TextField("Client Name", text: $clientName)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                }
                
                Section("Setup") {
                    Toggle("Capture Studio Setup Snapshot", isOn: $createSnapshot)
                    
                    if createSnapshot {
                        Text("This will save the current studio configuration for this session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
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
