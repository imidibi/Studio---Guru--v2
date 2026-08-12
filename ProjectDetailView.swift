//
//  ProjectDetailView.swift
//  Studio Guru
//
//  Project detail view

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project
    
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var sessions: [Session] = []
    @State private var works: [Work] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.title.bold())
                            
                            if !project.artistName.isEmpty {
                                Text(project.artistName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        StatusBadge(status: project.status)
                    }
                    
                    if !project.clientName.isEmpty && project.clientName != project.artistName {
                        Label(project.clientName, systemImage: "building.2")
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
                
                // Dates
                GroupBox("Timeline") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let startDate = project.startDate {
                            LabeledContent("Start Date") {
                                Text(startDate, style: .date)
                            }
                        }
                        
                        if let endDate = project.endDate {
                            LabeledContent("End Date") {
                                Text(endDate, style: .date)
                            }
                        }
                        
                        if project.startDate == nil && project.endDate == nil {
                            Text("No dates set")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Sessions
                GroupBox("Sessions (\(sessions.count))") {
                    if sessions.isEmpty {
                        Text("No sessions yet")
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
                
                // Works/Songs
                GroupBox("Songs (\(works.count))") {
                    if works.isEmpty {
                        Text("No songs yet")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(works.prefix(10)) { work in
                                WorkRowCompact(work: work)
                            }
                            
                            if works.count > 10 {
                                Text("+ \(works.count - 10) more songs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Notes
                if !project.notes.isEmpty {
                    GroupBox("Notes") {
                        Text(project.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProjectEditView(project: project)
        }
        .alert("Delete Project?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                project.isArchived = true
                project.markAsModified()
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(project)
            }
        } message: {
            Text("This project has \(sessions.count) sessions and \(works.count) songs. Archive instead of deleting to preserve historical data?")
        }
        .task {
            loadProjectData()
        }
    }
    
    private func loadProjectData() {
        do {
            sessions = try SessionMigrationHelper.sessionsForProject(projectID: project.id, modelContext: modelContext)
            
            let projectID = project.id
            let descriptor = FetchDescriptor<Work>(
                predicate: #Predicate { $0.projectID == projectID }
            )
            works = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading project data: \(error)")
        }
    }
}

struct SessionRowCompact: View {
    let session: Session
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.name)
                    .font(.subheadline)
                Text(session.sessionDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct WorkRowCompact: View {
    let work: Work
    
    var body: some View {
        HStack {
            Label(work.title, systemImage: "music.note")
                .font(.subheadline)
            
            Spacer()
            
            if !work.versionName.isEmpty {
                Text(work.versionName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(project: Project(name: "New Album", artistName: "Artist Name"))
    }
    .modelContainer(for: Project.self, inMemory: true)
}
