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
        NavigationSplitView {
            List(selection: $selectedWork) {
                ForEach(filteredWorks) { work in
                    NavigationLink(value: work) {
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
        } detail: {
            if let work = selectedWork {
                WorkDetailView(work: work)
            } else {
                Text("Select a song")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct WorkRowView: View {
    let work: Work
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(work.title)
                .font(.headline)
            
            HStack {
                if !work.artistName.isEmpty {
                    Text(work.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !work.versionName.isEmpty {
                    Text("(\(work.versionName))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let bpm = work.bpm {
                    Text("\(Int(bpm)) BPM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !work.key.isEmpty {
                    Text(work.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(work.isArchived ? 0.6 : 1.0)
    }
}

#Preview {
    WorksListView()
        .modelContainer(for: Work.self, inMemory: true)
}
