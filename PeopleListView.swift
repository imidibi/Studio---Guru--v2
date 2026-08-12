//
//  PeopleListView.swift
//  Studio Guru
//
//  People directory management

import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.lastName, order: .forward) private var allPeople: [Person]
    
    @State private var searchText = ""
    @State private var showingAddPerson = false
    @State private var showArchived = false
    @State private var selectedPerson: Person?
    
    var filteredPeople: [Person] {
        let activeFilter = showArchived ? allPeople : allPeople.filter { !$0.isArchived }
        
        if searchText.isEmpty {
            return activeFilter
        }
        
        return activeFilter.filter { person in
            person.displayName.localizedCaseInsensitiveContains(searchText) ||
            person.firstName.localizedCaseInsensitiveContains(searchText) ||
            person.lastName.localizedCaseInsensitiveContains(searchText) ||
            person.email.localizedCaseInsensitiveContains(searchText) ||
            person.company.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredPeople) { person in
                NavigationLink(destination: PersonDetailView(person: person)) {
                    PersonRowView(person: person)
                }
            }
        }
        .navigationTitle("People")
        .searchable(text: $searchText, prompt: "Search people")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPerson = true
                } label: {
                    Label("Add Person", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showArchived) {
                    Label("Show Archived", systemImage: "archivebox")
                }
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            PersonEditView(person: nil)
        }
    }
}

struct PersonRowView: View {
    let person: Person
    
    var body: some View {
        HStack {
            // Photo placeholder
            if let photoData = person.photoData,
               let image = loadImage(from: photoData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(person.initials)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                
                if !person.defaultRole.isEmpty {
                    Text(person.defaultRole)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !person.company.isEmpty {
                    Text(person.company)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if person.isArchived {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
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

extension Person {
    var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
}

#Preview {
    PeopleListView()
        .modelContainer(for: Person.self, inMemory: true)
}
