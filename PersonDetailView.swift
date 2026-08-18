//
//  PersonDetailView.swift
//  Studio Guru
//
//  Person detail and edit view

import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let person: Person
    
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with photo and name
                HStack(spacing: 16) {
                    if let photoData = person.photoData, let image = loadImage(from: photoData) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Text(person.initials)
                                    .font(.title.bold())
                                    .foregroundStyle(.secondary)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.displayName)
                            .font(.title2.bold())
                        
                        if !person.company.isEmpty {
                            Text(person.company)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !person.defaultRole.isEmpty {
                            Text(person.defaultRole)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(12)
                
                // Contact Information
                GroupBox("Contact") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !person.email.isEmpty {
                            LabeledContent("Email") {
                                Link(person.email, destination: URL(string: "mailto:\(person.email)")!)
                                    .font(.body)
                            }
                        }
                        
                        if !person.phone.isEmpty {
                            LabeledContent("Phone") {
                                Link(person.phone, destination: URL(string: "tel:\(person.phone)")!)
                                    .font(.body)
                            }
                        }
                        
                        if !person.website.isEmpty {
                            LabeledContent("Website") {
                                if let url = URL(string: person.website) {
                                    Link(person.website, destination: url)
                                        .font(.body)
                                } else {
                                    Text(person.website)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
                
                // Instruments & Skills
                if !person.instruments.isEmpty {
                    GroupBox("Instruments & Skills") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(person.instruments, id: \.self) { instrument in
                                Label(instrument, systemImage: "music.note")
                            }
                        }
                    }
                }
                
                // Notes
                if !person.notes.isEmpty {
                    GroupBox("Notes") {
                        Text(person.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Session History
                SessionHistorySection(personID: person.id)
            }
            .padding()
        }
        .navigationTitle(person.displayName)
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
            PersonEditView(person: person)
        }
        .alert("Delete Person?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                person.isArchived = true
                person.markAsModified()
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(person)
            }
        } message: {
            Text("This person has been involved in sessions. Archive instead of deleting to preserve historical data?")
        }
    }
    
    private func loadImage(from data: Data) -> Image? {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }
}

struct SessionHistorySection: View {
    @Environment(\.modelContext) private var modelContext
    let personID: UUID
    
    @State private var sessions: [Session] = []
    
    var body: some View {
        GroupBox("Session History") {
            if sessions.isEmpty {
                Text("No sessions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sessions.prefix(5)) { session in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(session.name)
                                    .font(.headline)
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
                    
                    if sessions.count > 5 {
                        Text("+ \(sessions.count - 5) more sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            loadSessions()
        }
    }
    
    private func loadSessions() {
        do {
            sessions = try SessionMigrationHelper.sessionsForPerson(personID: personID, modelContext: modelContext)
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        PersonDetailView(person: Person(firstName: "John", lastName: "Doe"))
    }
    .modelContainer(for: Person.self, inMemory: true)
}
