//
//  SessionsListView.swift
//  Studio Guru
//
//  Sessions management view

import SwiftUI
import SwiftData

struct SessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.sessionDate, order: .reverse) private var allSessions: [Session]
    @Query private var studios: [Studio]
    
    @State private var searchText = ""
    @State private var showingNewSession = false
    @State private var showArchived = false
    @State private var selectedSession: Session?
    @State private var statusFilter: SessionStatus?
    @State private var typeFilter: SessionType?
    
    var filteredSessions: [Session] {
        var filtered = showArchived ? allSessions : allSessions.filter { !$0.isArchived }
        
        if let status = statusFilter {
            filtered = filtered.filter { $0.status == status }
        }
        
        if let type = typeFilter {
            filtered = filtered.filter { $0.sessionType == type }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.name.localizedCaseInsensitiveContains(searchText) ||
                session.artistName.localizedCaseInsensitiveContains(searchText) ||
                session.clientName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters
            VStack(spacing: 8) {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag(nil as SessionStatus?)
                    ForEach(SessionStatus.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(status as SessionStatus?)
                    }
                }
                .pickerStyle(.segmented)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(typeFilter == nil ? "All Types" : "All") {
                            typeFilter = nil
                        }
                        .buttonStyle(.bordered)
                        .tint(typeFilter == nil ? .blue : .gray)
                        
                        ForEach(SessionType.allCases, id: \.self) { type in
                            Button(type.rawValue.capitalized) {
                                typeFilter = type
                            }
                            .buttonStyle(.bordered)
                            .tint(typeFilter == type ? .blue : .gray)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
            
            List {
                ForEach(filteredSessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        SessionRowView(session: session, studios: studios)
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .searchable(text: $searchText, prompt: "Search sessions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSession = true
                } label: {
                    Label("New Session", systemImage: "plus")
                }
                .disabled(studios.filter { !$0.isSystemStudio }.isEmpty)
            }
            
            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showArchived) {
                    Label("Show Archived", systemImage: "archivebox")
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            SessionCreationView()
        }
    }
}

struct SessionRowView: View {
    let session: Session
    let studios: [Studio]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name)
                    .font(.headline)
                
                Spacer()
                
                SessionStatusBadge(status: session.status)
            }
            
            HStack(spacing: 12) {
                Label {
                    Text(session.sessionDate, format: .dateTime.month().day().year())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                
                if let studio = studio {
                    Label(studio.name, systemImage: "building.2")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Label(session.sessionType.rawValue.capitalized, systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            if !session.artistName.isEmpty {
                Text(session.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(session.isArchived ? 0.6 : 1.0)
    }
}

struct SessionStatusBadge: View {
    let status: SessionStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(4)
    }
    
    var statusColor: Color {
        switch status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

#Preview {
    SessionsListView()
        .modelContainer(for: [Session.self, Studio.self], inMemory: true)
}
