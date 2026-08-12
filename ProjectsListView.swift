//
//  ProjectsListView.swift
//  Studio Guru
//
//  Projects management view

import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name, order: .forward) private var allProjects: [Project]
    
    @State private var searchText = ""
    @State private var showingAddProject = false
    @State private var showArchived = false
    @State private var selectedProject: Project?
    @State private var statusFilter: ProjectStatus?
    
    var filteredProjects: [Project] {
        var filtered = showArchived ? allProjects : allProjects.filter { !$0.isArchived }
        
        if let status = statusFilter {
            filtered = filtered.filter { $0.status == status }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                project.artistName.localizedCaseInsensitiveContains(searchText) ||
                project.clientName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Status filter
            Picker("Status", selection: $statusFilter) {
                Text("All").tag(nil as ProjectStatus?)
                ForEach(ProjectStatus.allCases, id: \.self) { status in
                    Text(status.rawValue.capitalized).tag(status as ProjectStatus?)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectRowView(project: project)
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddProject = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showArchived) {
                    Label("Show Archived", systemImage: "archivebox")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            ProjectEditView(project: nil)
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            
            HStack {
                if !project.artistName.isEmpty {
                    Text(project.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: project.status)
            }
            
            if !project.clientName.isEmpty && project.clientName != project.artistName {
                Text("Client: \(project.clientName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(project.isArchived ? 0.6 : 1.0)
    }
}

struct StatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(4)
    }
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
}

#Preview {
    ProjectsListView()
        .modelContainer(for: Project.self, inMemory: true)
}
