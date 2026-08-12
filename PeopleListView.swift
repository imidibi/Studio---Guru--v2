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
    
    var avatarGradient: LinearGradient {
        let colors = [Color.blue, Color.purple, Color.pink, Color.orange, Color.green]
        let hash = abs(person.displayName.hashValue)
        let color1 = colors[hash % colors.count]
        let color2 = colors[(hash + 1) % colors.count]
        return LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Modern avatar with shadow
            Group {
                if let photoData = person.photoData,
                   let image = loadImage(from: photoData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Text(person.initials)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    if !person.defaultRole.isEmpty {
                        Text(person.defaultRole)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !person.company.isEmpty {
                        if !person.defaultRole.isEmpty {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Text(person.company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !person.instruments.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(person.instruments.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            if person.isArchived {
                Image(systemName: "archivebox.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.vertical, 4)
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
