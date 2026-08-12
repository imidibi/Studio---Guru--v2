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
    
    var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(statusColor.gradient)
                .frame(width: 4, height: 48)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(project.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Status badge
                    Text(project.status.rawValue.capitalized)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.gradient)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 8) {
                    if !project.artistName.isEmpty {
                        Label(project.artistName, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if !project.clientName.isEmpty && project.clientName != project.artistName {
                    Label(project.clientName, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(project.isArchived ? 0.6 : 1.0)
    }
}

struct StatusBadge: View {
    let status: ProjectStatus
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.gradient)
            .clipShape(Capsule())
            .shadow(color: statusColor.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    ProjectsListView()
        .modelContainer(for: Project.self, inMemory: true)
}
