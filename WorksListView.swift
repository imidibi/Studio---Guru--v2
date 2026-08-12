//
//  WorksListView.swift
//  Studio Guru
//
//  Works/Songs management

import SwiftUI
import SwiftData

struct WorksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Work.title, order: .forward) private var allWorks: [Work]
    
    @State private var searchText = ""
    @State private var showingAddWork = false
    @State private var showArchived = false
    @State private var selectedWork: Work?
    
    var filteredWorks: [Work] {
        let activeFilter = showArchived ? allWorks : allWorks.filter { !$0.isArchived }
        
        if searchText.isEmpty {
            return activeFilter
        }
        
        return activeFilter.filter { work in
            work.title.localizedCaseInsensitiveContains(searchText) ||
            work.artistName.localizedCaseInsensitiveContains(searchText) ||
            work.versionName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredWorks) { work in
                NavigationLink(destination: WorkDetailView(work: work)) {
                    WorkRowView(work: work)
                }
            }
        }
        .navigationTitle("Songs")
        .searchable(text: $searchText, prompt: "Search songs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddWork = true
                } label: {
                    Label("Add Song", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showArchived) {
                    Label("Show Archived", systemImage: "archivebox")
                }
            }
        }
        .sheet(isPresented: $showingAddWork) {
            WorkEditView(work: nil)
        }
    }
}

struct WorkRowView: View {
    let work: Work
    
    var body: some View {
        HStack(spacing: 12) {
            // Music icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(work.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    if !work.artistName.isEmpty {
                        Label(work.artistName, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if !work.versionName.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(work.versionName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 12) {
                    if let bpm = work.bpm {
                        Label("\(Int(bpm)) BPM", systemImage: "metronome")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if !work.key.isEmpty {
                        Label(work.key, systemImage: "music.quarternote.3")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(work.isArchived ? 0.6 : 1.0)
    }
}

#Preview {
    WorksListView()
        .modelContainer(for: Work.self, inMemory: true)
}
