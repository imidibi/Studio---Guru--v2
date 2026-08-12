//
//  WorkDetailEditViews.swift
//  Studio Guru
//
//  Work/Song detail and edit views

import SwiftUI
import SwiftData

// MARK: - Work Detail View

struct WorkDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let work: Work
    
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var sessions: [Session] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(work.title)
                        .font(.title.bold())
                    
                    if !work.versionName.isEmpty {
                        Text(work.versionName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !work.artistName.isEmpty {
                        Label(work.artistName, systemImage: "person")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(12)
                
                // Musical Information
                GroupBox("Musical Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let bpm = work.bpm {
                            LabeledContent("BPM", value: "\(Int(bpm))")
                        }
                        if !work.key.isEmpty {
                            LabeledContent("Key", value: work.key)
                        }
                        if !work.timeSignature.isEmpty {
                            LabeledContent("Time Signature", value: work.timeSignature)
                        }
                    }
                }
                
                // Metadata
                if !work.isrc.isEmpty || !work.iswc.isEmpty || !work.proWorkID.isEmpty {
                    GroupBox("Metadata") {
                        VStack(alignment: .leading, spacing: 8) {
                            if !work.isrc.isEmpty {
                                LabeledContent("ISRC", value: work.isrc)
                            }
                            if !work.iswc.isEmpty {
                                LabeledContent("ISWC", value: work.iswc)
                            }
                            if !work.proWorkID.isEmpty {
                                LabeledContent("PRO Work ID", value: work.proWorkID)
                            }
                        }
                    }
                }
                
                // Sessions
                GroupBox("Session History (\(sessions.count))") {
                    if sessions.isEmpty {
                        Text("Not recorded yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(sessions.prefix(5)) { session in
                                SessionRowCompact(session: session)
                            }
                            if sessions.count > 5 {
                                Text("+ \(sessions.count - 5) more sessions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Notes
                if !work.notes.isEmpty {
                    GroupBox("Notes") {
                        Text(work.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(work.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isEditing = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            WorkEditView(work: work)
        }
        .alert("Delete Song?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                work.isArchived = true
                work.markAsModified()
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(work)
            }
        }
        .task {
            loadSessions()
        }
    }
    
    private func loadSessions() {
        do {
            sessions = try SessionMigrationHelper.sessionsForWork(workID: work.id, modelContext: modelContext)
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
}

// MARK: - Work Edit View

struct WorkEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var projects: [Project]
    
    let work: Work?
    
    @State private var title = ""
    @State private var versionName = ""
    @State private var artistName = ""
    @State private var bpm: Double?
    @State private var key = ""
    @State private var timeSignature = ""
    @State private var isrc = ""
    @State private var iswc = ""
    @State private var proWorkID = ""
    @State private var notes = ""
    @State private var selectedProjectID: UUID?
    @State private var hasBPM = false
    
    var isEditing: Bool { work != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    TextField("Version", text: $versionName)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    TextField("Artist", text: $artistName)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    
                    Picker("Project", selection: $selectedProjectID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(projects.filter { !$0.isArchived }) { project in
                            Text(project.name).tag(project.id as UUID?)
                        }
                    }
                }
                
                Section("Musical Details") {
                    Toggle("BPM", isOn: $hasBPM)
                    if hasBPM {
                        HStack {
                            TextField("BPM", value: Binding(
                                get: { bpm ?? 120 },
                                set: { bpm = $0 }
                            ), format: .number)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            Stepper("", value: Binding(
                                get: { bpm ?? 120 },
                                set: { bpm = $0 }
                            ), in: 20...300, step: 1)
                        }
                    }
                    
                    TextField("Key", text: $key)
                    TextField("Time Signature", text: $timeSignature)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                Section("Metadata") {
                    TextField("ISRC", text: $isrc)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                    TextField("ISWC", text: $iswc)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        #endif
                    TextField("PRO Work ID", text: $proWorkID)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Song" : "New Song")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWork() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear { loadWorkData() }
        }
    }
    
    private func loadWorkData() {
        guard let work = work else { return }
        title = work.title
        versionName = work.versionName
        artistName = work.artistName
        bpm = work.bpm
        key = work.key
        timeSignature = work.timeSignature
        isrc = work.isrc
        iswc = work.iswc
        proWorkID = work.proWorkID
        notes = work.notes
        selectedProjectID = work.projectID
        hasBPM = work.bpm != nil
    }
    
    private func saveWork() {
        if let work = work {
            work.title = title
            work.versionName = versionName
            work.artistName = artistName
            work.bpm = hasBPM ? bpm : nil
            work.key = key
            work.timeSignature = timeSignature
            work.isrc = isrc
            work.iswc = iswc
            work.proWorkID = proWorkID
            work.notes = notes
            work.projectID = selectedProjectID
            work.markAsModified()
        } else {
            let newWork = Work(title: title, projectID: selectedProjectID)
            newWork.versionName = versionName
            newWork.artistName = artistName
            newWork.bpm = hasBPM ? bpm : nil
            newWork.key = key
            newWork.timeSignature = timeSignature
            newWork.isrc = isrc
            newWork.iswc = iswc
            newWork.proWorkID = proWorkID
            newWork.notes = notes
            modelContext.insert(newWork)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        WorkDetailView(work: Work(title: "My Song"))
    }
    .modelContainer(for: Work.self, inMemory: true)
}
