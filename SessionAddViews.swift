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
            Form {
                Picker("Person", selection: $selectedPersonID) {
                    Text("Select Person").tag(nil as UUID?)
                    ForEach(allPeople.filter { !$0.isArchived }) { person in
                        Text(person.displayName).tag(person.id as UUID?)
                    }
                }
                
                TextField("Role (e.g., Producer, Engineer, Artist)", text: $role)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
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
            Form {
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
                
                Stepper("Sequence: \(sequenceNumber)", value: $sequenceNumber, in: 0...100)
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Session Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Location & Type
                    GroupBox("Location & Type") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Studio", selection: $selectedStudioID) {
                                ForEach(studios.filter { !$0.isSystemStudio }) { studio in
                                    Text(studio.name).tag(studio.id)
                                }
                            }
                            
                            Picker("Session Type", selection: $sessionType) {
                                ForEach(SessionType.allCases, id: \.self) { type in
                                    Text(type.rawValue.capitalized).tag(type)
                                }
                            }
                            
                            Picker("Status", selection: $status) {
                                ForEach(SessionStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue.capitalized).tag(status)
                                }
                            }
                        }
                    }
                    
                    // Project
                    GroupBox("Project") {
                        Picker("Project", selection: $selectedProjectID) {
                            Text("None").tag(nil as UUID?)
                            ForEach(projects.filter { !$0.isArchived }) { project in
                                Text(project.name).tag(project.id as UUID?)
                            }
                        }
                    }
                    
                    // Date & Time
                    GroupBox("Date & Time") {
                        VStack(alignment: .leading, spacing: 12) {
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
                    }
                    
                    // Client Information
                    GroupBox("Client Information") {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Artist Name", text: $artistName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Client Name", text: $clientName)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .overlay(alignment: .topLeading) {
                                if notes.isEmpty {
                                    Text("Session notes...")
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                }
                .padding()
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
        
        dismiss()
    }
}

#Preview {
    AddSessionParticipantView(session: Session(studioID: UUID(), name: "Test"))
        .modelContainer(for: [Session.self, Person.self], inMemory: true)
}
