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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Project Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Enter project name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                            
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
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Project Type")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Picker("Type", selection: $projectType) {
                                    ForEach(ProjectType.allCases, id: \.self) { type in
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
                                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                                        Text(status.rawValue.capitalized).tag(status)
                                    }
                                }
                                .labelsHidden()
                            }
                        }
                    }
                    
                    // Timeline
                    GroupBox("Timeline") {
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle("Include Start Date", isOn: $hasStartDate)
                            if hasStartDate {
                                DatePicker("Start Date", selection: Binding(
                                    get: { startDate ?? Date() },
                                    set: { startDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                            }
                            
                            Toggle("Include End Date", isOn: $hasEndDate)
                            if hasEndDate {
                                DatePicker("End Date", selection: Binding(
                                    get: { endDate ?? Date() },
                                    set: { endDate = $0 }
                                ), displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.graphical)
                            }
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Project Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .overlay(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Add any notes about this project...")
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
