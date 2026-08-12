//
//  DashboardView.swift
//  Studio Guru
//
//  Dashboard home screen with overview and quick actions

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    @Query private var studios: [Studio]
    @Query private var people: [Person]
    
    @State private var showingNewSession = false
    @State private var showingNewPerson = false
    @State private var showingSettings = false
    
    var todaySessions: [Session] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return sessions.filter { session in
            !session.isArchived &&
            session.sessionDate >= today &&
            session.sessionDate < tomorrow
        }.sorted { $0.sessionDate < $1.sessionDate }
    }
    
    var upcomingSessions: [Session] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        
        return sessions.filter { session in
            !session.isArchived &&
            session.sessionDate >= today &&
            session.sessionDate < nextWeek
        }.sorted { $0.sessionDate < $1.sessionDate }
    }
    
    var activeStudios: [Studio] {
        studios.filter { !$0.isSystemStudio }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Studio Guru")
                        .font(.largeTitle.bold())
                    Text("Welcome back")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatCard(
                        title: "Today's Sessions",
                        value: "\(todaySessions.count)",
                        icon: "calendar.badge.clock",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Active Studios",
                        value: "\(activeStudios.count)",
                        icon: "building.2",
                        color: .green
                    )
                    
                    StatCard(
                        title: "People",
                        value: "\(people.filter { !$0.isArchived }.count)",
                        icon: "person.3",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Quick Actions
                GroupBox("Quick Actions") {
                    VStack(spacing: 12) {
                        QuickActionButton(
                            title: "New Session",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showingNewSession = true
                        }
                        
                        QuickActionButton(
                            title: "Add Person",
                            icon: "person.crop.circle.badge.plus",
                            color: .green
                        ) {
                            showingNewPerson = true
                        }
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal)
                
                // Today's Sessions
                if !todaySessions.isEmpty {
                    GroupBox("Today's Sessions") {
                        VStack(spacing: 12) {
                            ForEach(todaySessions.prefix(5)) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    TodaySessionRow(session: session, studios: activeStudios)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal)
                }
                
                // Upcoming Sessions
                GroupBox("Upcoming This Week") {
                    if upcomingSessions.isEmpty {
                        ContentUnavailableView(
                            "No Upcoming Sessions",
                            systemImage: "calendar",
                            description: Text("Schedule a new session to get started")
                        )
                        .frame(height: 200)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(upcomingSessions.prefix(10)) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    UpcomingSessionRow(session: session, studios: activeStudios)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                
                // Settings
                GroupBox {
                    Button {
                        showingSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            Text("Settings")
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        #if os(macOS)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        #else
                        .background(Color(.secondarySystemBackground))
                        #endif
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingNewSession) {
            SessionCreationView()
        }
        .sheet(isPresented: $showingNewPerson) {
            PersonEditView(person: nil)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            #if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            #else
            .background(Color(.secondarySystemBackground))
            #endif
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Session Row

struct TodaySessionRow: View {
    let session: Session
    let studios: [Studio]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                if let startTime = session.startTime {
                    Text(startTime, style: .time)
                        .font(.headline)
                } else {
                    Text("All Day")
                        .font(.caption)
                }
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            
            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                
                HStack {
                    if let studio = studio {
                        Label(studio.name, systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Label(session.sessionType.rawValue.capitalized, systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            SessionStatusBadge(status: session.status)
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(8)
    }
}

// MARK: - Upcoming Session Row

struct UpcomingSessionRow: View {
    let session: Session
    let studios: [Studio]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Date indicator
            VStack(spacing: 2) {
                Text(session.sessionDate, format: .dateTime.day())
                    .font(.title2.bold())
                Text(session.sessionDate, format: .dateTime.month(.abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            // Session info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                
                if let studio = studio {
                    Text(studio.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 12) {
                    if let startTime = session.startTime {
                        Label {
                            Text(startTime, style: .time)
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    
                    Label(session.sessionType.rawValue.capitalized, systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Session.self, Studio.self, Person.self], inMemory: true)
}
