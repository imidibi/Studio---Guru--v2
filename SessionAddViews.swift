//
//  SessionAddViews.swift
//  Studio Guru
//
//  Views for adding people, works, and gear to sessions

import SwiftUI
import SwiftData

// MARK: - Add Session Participant

struct AddSessionParticipantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allPeople: [Person]
    
    let session: Session
    
    @State private var selectedPersonID: UUID?
    @State private var role = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Person Selection
                    GroupBox("Person") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select participant")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Person", selection: $selectedPersonID) {
                                Text("Select Person").tag(nil as UUID?)
                                ForEach(allPeople.filter { !$0.isArchived }) { person in
                                    Text(person.displayName).tag(person.id as UUID?)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    
                    // Role
                    GroupBox("Role") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Participant's role")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("e.g., Producer, Engineer, Artist", text: $role)
                                .textFieldStyle(.roundedBorder)
                                #if os(iOS)
                                .textInputAutocapitalization(.words)
                                #endif
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any notes about this participant...")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                            }
                            #if os(macOS)
                            .background(Color(nsColor: .controlBackgroundColor))
                            #else
                            .background(Color(.systemBackground))
                            #endif
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Participant")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addParticipant() }
                        .disabled(selectedPersonID == nil)
                }
            }
        }
    }
    
    private func addParticipant() {
        guard let personID = selectedPersonID else { return }
        
        let participant = SessionParticipant(sessionID: session.id, personID: personID, role: role)
        participant.notes = notes
        participant.session = session
        
        modelContext.insert(participant)
        dismiss()
    }
}

// MARK: - Add Session Work

struct AddSessionWorkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allWorks: [Work]
    
    let session: Session
    
    @State private var selectedWorkID: UUID?
    @State private var notes = ""
    @State private var sequenceNumber = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Song Selection
                    GroupBox("Song") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select song to add")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Song", selection: $selectedWorkID) {
                                Text("Select Song").tag(nil as UUID?)
                                ForEach(allWorks.filter { !$0.isArchived }) { work in
                                    VStack(alignment: .leading) {
                                        Text(work.title)
                                        if !work.artistName.isEmpty {
                                            Text(work.artistName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(work.id as UUID?)
                                }
                            }
                            .labelsHidden()
                        }
                    }
                    
                    // Sequence Number
                    GroupBox("Sequence") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Order in session")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Stepper("Sequence: \(sequenceNumber)", value: $sequenceNumber, in: 0...100)
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any notes about this song in the session...")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                            }
                            #if os(macOS)
                            .background(Color(nsColor: .controlBackgroundColor))
                            #else
                            .background(Color(.systemBackground))
                            #endif
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Song")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addWork() }
                        .disabled(selectedWorkID == nil)
                }
            }
        }
    }
    
    private func addWork() {
        guard let workID = selectedWorkID else { return }
        
        let sessionWork = SessionWork(sessionID: session.id, workID: workID, sequenceNumber: sequenceNumber)
        sessionWork.notes = notes
        sessionWork.session = session
        
        modelContext.insert(sessionWork)
        dismiss()
    }
}

// MARK: - Session Edit View

struct SessionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var studios: [Studio]
    @Query private var projects: [Project]
    
    let session: Session
    
    @State private var name = ""
    @State private var selectedStudioID: UUID = UUID()
    @State private var previousStudioID: UUID = UUID()  // Track studio changes
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
    @State private var expandedTimeField: TimeField?
    @FocusState private var focusedField: SessionFormField?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session Name")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Enter session name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .name)
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
                                    ForEach(studios.filter { !$0.isSystemStudio }) { studio in
                                        Text(studio.name).tag(studio.id)
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
                                        Text(type.rawValue.capitalized).tag(type)
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
                    GroupBox("Project") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Associated project")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Picker("Project", selection: $selectedProjectID) {
                                Text("None").tag(nil as UUID?)
                                ForEach(projects.filter { !$0.isArchived }) { project in
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
                                #if os(iOS)
                                CollapsibleTimePicker(label: "Start Time", time: $startTime, field: .start, expandedField: $expandedTimeField)
                                #else
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Start Time")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                #endif
                            }

                            Toggle("Include End Time", isOn: $hasEndTime)
                            if hasEndTime {
                                #if os(iOS)
                                CollapsibleTimePicker(label: "End Time", time: $endTime, field: .end, expandedField: $expandedTimeField)
                                #else
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("End Time")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                                #endif
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
                                    .focused($focusedField, equals: .artist)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Client or label name", text: $clientName)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($focusedField, equals: .client)
                            }
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Session notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ZStack(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Add any notes about this session...")
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                TextEditor(text: $notes)
                                    .frame(minHeight: 100)
                                    .scrollContentBackground(.hidden)
                                    .focused($focusedField, equals: .notes)
                            }
                            #if os(macOS)
                            .background(Color(nsColor: .controlBackgroundColor))
                            #else
                            .background(Color(.systemBackground))
                            #endif
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: focusedField) { _, newValue in
                // Withdraw any open time wheel when the user moves to a text field
                if newValue != nil {
                    withAnimation { expandedTimeField = nil }
                }
            }
            .navigationTitle("Edit Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadSessionData() }
        }
    }
    
    private func loadSessionData() {
        name = session.name
        selectedStudioID = session.studioID
        previousStudioID = session.studioID  // Track original studio
        selectedProjectID = session.projectID
        sessionDate = session.sessionDate
        sessionType = session.sessionType
        status = session.status
        artistName = session.artistName
        clientName = session.clientName
        hasStartTime = session.startTime != nil
        startTime = session.startTime ?? Date()
        hasEndTime = session.endTime != nil
        endTime = session.endTime ?? Date()
        notes = session.notes
    }
    
    private func saveSession() {
        // Check if studio has changed
        let studioChanged = selectedStudioID != previousStudioID
        
        session.name = name
        session.studioID = selectedStudioID
        session.projectID = selectedProjectID
        session.sessionDate = sessionDate
        session.sessionType = sessionType
        session.status = status
        session.artistName = artistName
        session.clientName = clientName
        session.startTime = hasStartTime ? startTime : nil
        session.endTime = hasEndTime ? endTime : nil
        session.notes = notes
        session.markAsModified()
        
        // Create dedicated session studio from template if studio was assigned or changed
        if studioChanged, let studio = studios.first(where: { $0.id == selectedStudioID }) {
            do {
                let _ = try SessionStudioHelper.getOrCreateSessionStudio(
                    for: session,
                    templateStudio: studio,
                    modelContext: modelContext
                )
                print("✅ Created session canvas from studio: \(studio.name)")
            } catch {
                print("❌ Error creating session studio: \(error)")
            }
        }
        
        dismiss()
    }
}

#Preview {
    AddSessionParticipantView(session: Session(studioID: UUID(), name: "Test"))
        .modelContainer(for: [Session.self, Person.self], inMemory: true)
}
