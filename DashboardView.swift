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

        return sessions.filter { session in
            !session.isArchived &&
            session.sessionDate >= today
        }.sorted { $0.sessionDate < $1.sessionDate }
    }
    
    var activeStudios: [Studio] {
        studios.filter { !$0.isSystemStudio }
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with gradient
                VStack(alignment: .leading, spacing: 8) {
                    Text("Studio Guru 2")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text(greeting)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 24)
                
                // Quick Stats
                HStack(spacing: 16) {
                    NavigationLink(destination: SessionsListView()) {
                        StatCard(
                            title: "Today's Sessions",
                            value: "\(todaySessions.count)",
                            icon: "calendar.badge.clock",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: StudioCanvasView()) {
                        StatCard(
                            title: "Active Studios",
                            value: "\(activeStudios.count)",
                            icon: "building.2",
                            color: .green
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(destination: PeopleListView()) {
                        StatCard(
                            title: "People",
                            value: "\(people.filter { !$0.isArchived }.count)",
                            icon: "person.3",
                            color: .orange
                        )
                    }
                    .buttonStyle(.plain)
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
                GroupBox("Upcoming") {
                    if upcomingSessions.isEmpty {
                        ContentUnavailableView(
                            "No Upcoming Sessions",
                            systemImage: "calendar",
                            description: Text("Schedule a new session to get started")
                        )
                        .frame(height: 200)
                    } else if upcomingSessions.count <= 5 {
                        upcomingSessionsList
                    } else {
                        // Scroll within the section so long schedules don't
                        // stretch the dashboard
                        ScrollView {
                            upcomingSessionsList
                        }
                        .frame(height: 420)
                    }
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
    }

    private var upcomingSessionsList: some View {
        VStack(spacing: 12) {
            ForEach(upcomingSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    UpcomingSessionRow(session: session, studios: activeStudios)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.gradient)
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
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
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .fontWeight(.semibold)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            }
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
    
    var statusColor: Color {
        switch session.status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Time indicator with gradient
            VStack(spacing: 4) {
                if let startTime = session.startTime {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                } else {
                    Text("All Day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .frame(width: 90)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(statusColor.gradient.opacity(0.15))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 1.5)
            }
            
            // Session info
            VStack(alignment: .leading, spacing: 6) {
                Text(session.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
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
            }
            
            Spacer()
            
            // Status badge
            Text(session.status.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.gradient)
                .clipShape(Capsule())
                .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

// MARK: - Upcoming Session Row

struct UpcomingSessionRow: View {
    let session: Session
    let studios: [Studio]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var statusColor: Color {
        switch session.status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Date indicator with modern styling
            VStack(spacing: 2) {
                Text(session.sessionDate, format: .dateTime.day())
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
                Text(session.sessionDate, format: .dateTime.month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 70)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(statusColor.gradient.opacity(0.1))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(statusColor.opacity(0.2), lineWidth: 1)
            }
            
            // Session info
            VStack(alignment: .leading, spacing: 6) {
                Text(session.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let studio = studio {
                    Label(studio.name, systemImage: "building.2")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let startTime = session.startTime {
                        Label {
                            Text(startTime.formatted(date: .omitted, time: .shortened))
                        } icon: {
                            Image(systemName: "clock.fill")
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
            
            Image(systemName: "chevron.right.circle.fill")
                .font(.title3)
                .foregroundStyle(.tertiary.opacity(0.5))
                .symbolRenderingMode(.hierarchical)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Session.self, Studio.self, Person.self], inMemory: true)
}
