//
//  ProjectEditView.swift
//  Studio Guru
//
//  Add/Edit project form

import SwiftUI
import SwiftData

struct ProjectEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: Project?
    
    @State private var name = ""
    @State private var artistName = ""
    @State private var clientName = ""
    @State private var projectType: ProjectType = .other
    @State private var status: ProjectStatus = .active
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var notes = ""
    @State private var hasStartDate = false
    @State private var hasEndDate = false
    
    var isEditing: Bool { project != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Project Name", text: $name)
                    TextField("Artist Name", text: $artistName)
                    TextField("Client Name", text: $clientName)
                    
                    Picker("Type", selection: $projectType) {
                        ForEach(ProjectType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                Section("Timeline") {
                    Toggle("Start Date", isOn: $hasStartDate)
                    if hasStartDate {
                        DatePicker("Start", selection: Binding(
                            get: { startDate ?? Date() },
                            set: { startDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    Toggle("End Date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("End", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadProjectData()
            }
        }
    }
    
    private func loadProjectData() {
        guard let project = project else { return }
        
        name = project.name
        artistName = project.artistName
        clientName = project.clientName
        projectType = project.projectType
        status = project.status
        startDate = project.startDate
        endDate = project.endDate
        notes = project.notes
        hasStartDate = project.startDate != nil
        hasEndDate = project.endDate != nil
    }
    
    private func saveProject() {
        if let project = project {
            // Update existing
            project.name = name
            project.artistName = artistName
            project.clientName = clientName
            project.projectType = projectType
            project.status = status
            project.startDate = hasStartDate ? startDate : nil
            project.endDate = hasEndDate ? endDate : nil
            project.notes = notes
            project.markAsModified()
        } else {
            // Create new
            let newProject = Project(name: name, artistName: artistName, clientName: clientName)
            newProject.projectType = projectType
            newProject.status = status
            newProject.startDate = hasStartDate ? startDate : nil
            newProject.endDate = hasEndDate ? endDate : nil
            newProject.notes = notes
            
            modelContext.insert(newProject)
        }
        
        dismiss()
    }
}

#Preview {
    ProjectEditView(project: nil)
        .modelContainer(for: Project.self, inMemory: true)
}
