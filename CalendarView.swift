//
//  CalendarView.swift
//  Studio Guru
//
//  Multi-dimensional calendar for session scheduling and resource management

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [Session]
    @Query private var studios: [Studio]
    @Query private var people: [Person]
    
    @State private var selectedDate = Date()
    @State private var calendarView: CalendarViewType = .week
    @State private var resourceFilter: ResourceFilter = .allStudios
    @State private var selectedResourceID: UUID?
    @State private var showingNewSession = false
    
    enum CalendarViewType: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    enum ResourceFilter: String, CaseIterable {
        case allStudios = "All Studios"
        case byStudio = "By Studio"
        case byPerson = "By Person"
    }
    
    var activeStudios: [Studio] {
        studios.filter { !$0.isSystemStudio }
    }
    
    var activePeople: [Person] {
        people.filter { !$0.isArchived }
    }
    
    var filteredSessions: [Session] {
        var filtered = sessions.filter { !$0.isArchived }
        
        switch resourceFilter {
        case .allStudios:
            return filtered
        case .byStudio:
            if let studioID = selectedResourceID {
                filtered = filtered.filter { $0.studioID == studioID }
            }
        case .byPerson:
            if let personID = selectedResourceID {
                // Find sessions where this person is a participant
                let sessionIDs = getSessionIDsForPerson(personID: personID)
                filtered = filtered.filter { sessionIDs.contains($0.id) }
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            CalendarToolbar(
                calendarView: $calendarView,
                resourceFilter: $resourceFilter,
                selectedResourceID: $selectedResourceID,
                selectedDate: $selectedDate,
                studios: activeStudios,
                people: activePeople,
                showingNewSession: $showingNewSession
            )
            .padding()
            
            Divider()
            
            // Calendar Content
            ScrollView {
                VStack(spacing: 0) {
                    switch calendarView {
                    case .day:
                        DayCalendarView(
                            selectedDate: selectedDate,
                            sessions: filteredSessions,
                            studios: activeStudios
                        )
                    case .week:
                        WeekCalendarView(
                            selectedDate: selectedDate,
                            sessions: filteredSessions,
                            studios: activeStudios
                        )
                    case .month:
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            sessions: filteredSessions,
                            studios: activeStudios
                        )
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .sheet(isPresented: $showingNewSession) {
            SessionCreationView()
        }
    }
    
    private func getSessionIDsForPerson(personID: UUID) -> Set<UUID> {
        let descriptor = FetchDescriptor<SessionParticipant>(
            predicate: #Predicate { $0.personID == personID }
        )
        let participants = (try? modelContext.fetch(descriptor)) ?? []
        return Set(participants.map { $0.sessionID })
    }
}

// MARK: - Calendar Toolbar

struct CalendarToolbar: View {
    @Binding var calendarView: CalendarView.CalendarViewType
    @Binding var resourceFilter: CalendarView.ResourceFilter
    @Binding var selectedResourceID: UUID?
    @Binding var selectedDate: Date
    let studios: [Studio]
    let people: [Person]
    @Binding var showingNewSession: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // View type picker
                Picker("View", selection: $calendarView) {
                    ForEach(CalendarView.CalendarViewType.allCases, id: \.self) { view in
                        Text(view.rawValue).tag(view)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 8) {
                    Button {
                        adjustDate(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    Button("Today") {
                        selectedDate = Date()
                    }
                    
                    Button {
                        adjustDate(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                
                Spacer()
                
                // New session button
                Button {
                    showingNewSession = true
                } label: {
                    Label("New Session", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Resource filter
            HStack {
                Picker("Filter", selection: $resourceFilter) {
                    ForEach(CalendarView.ResourceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 400)
                
                if resourceFilter == .byStudio {
                    Picker("Studio", selection: $selectedResourceID) {
                        Text("Select Studio").tag(nil as UUID?)
                        ForEach(studios) { studio in
                            Text(studio.name).tag(studio.id as UUID?)
                        }
                    }
                    .frame(maxWidth: 300)
                } else if resourceFilter == .byPerson {
                    Picker("Person", selection: $selectedResourceID) {
                        Text("Select Person").tag(nil as UUID?)
                        ForEach(people) { person in
                            Text(person.displayName).tag(person.id as UUID?)
                        }
                    }
                    .frame(maxWidth: 300)
                }
                
                Spacer()
            }
        }
    }
    
    private func adjustDate(by value: Int) {
        let calendar = Calendar.current
        switch calendarView {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
        }
    }
}

// MARK: - Day Calendar View

struct DayCalendarView: View {
    let selectedDate: Date
    let sessions: [Session]
    let studios: [Studio]
    
    var daySessions: [Session] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return sessions.filter { session in
            session.sessionDate >= dayStart && session.sessionDate < dayEnd
        }.sorted { $0.sessionDate < $1.sessionDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.title2.bold())
                .padding()
            
            if daySessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "calendar",
                    description: Text("No sessions scheduled for this day")
                )
                .frame(height: 400)
            } else {
                VStack(spacing: 12) {
                    ForEach(daySessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            CalendarSessionCard(session: session, studios: studios, showDate: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Week Calendar View

struct WeekCalendarView: View {
    let selectedDate: Date
    let sessions: [Session]
    let studios: [Studio]
    
    var weekDays: [Date] {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }
    
    func sessionsForDay(_ date: Date) -> [Session] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return sessions.filter { session in
            session.sessionDate >= dayStart && session.sessionDate < dayEnd
        }.sorted { ($0.startTime ?? $0.sessionDate) < ($1.startTime ?? $1.sessionDate) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Week header
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(day, format: .dateTime.weekday(.abbreviated))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(day, format: .dateTime.day())
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.1) : Color.clear)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Week grid
            HStack(alignment: .top, spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        let daySessions = sessionsForDay(day)
                        
                        if daySessions.isEmpty {
                            Text("No sessions")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(daySessions) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    WeekSessionCard(session: session, studios: studios)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Calendar.current.isDateInToday(day) ? Color.blue.opacity(0.05) : Color.clear)
                    
                    if day != weekDays.last {
                        Divider()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let sessions: [Session]
    let studios: [Studio]
    
    var monthDays: [Date] {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }
    
    var weekDayHeaders: [String] {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols
    }
    
    func sessionsForDay(_ date: Date) -> [Session] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        return sessions.filter { session in
            session.sessionDate >= dayStart && session.sessionDate < dayEnd
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            Text(selectedDate, format: .dateTime.month(.wide).year())
                .font(.title2.bold())
                .padding()
            
            // Calendar grid
            VStack(spacing: 0) {
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(weekDayHeaders, id: \.self) { day in
                        Text(day)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Month grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                    ForEach(monthDays, id: \.self) { day in
                        let daySessions = sessionsForDay(day)
                        let isToday = Calendar.current.isDateInToday(day)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day, format: .dateTime.day())
                                .font(.caption.bold())
                                .foregroundStyle(isToday ? .white : .primary)
                                .padding(4)
                                .background(isToday ? Color.blue : Color.clear)
                                .clipShape(Circle())
                            
                            if !daySessions.isEmpty {
                                ForEach(daySessions.prefix(3)) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        MonthSessionDot(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if daySessions.count > 3 {
                                    Text("+\(daySessions.count - 3)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        #if os(macOS)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                        #else
                        .background(Color(.secondarySystemBackground))
                        #endif
                        .onTapGesture {
                            selectedDate = day
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

// MARK: - Session Cards

struct CalendarSessionCard: View {
    let session: Session
    let studios: [Studio]
    let showDate: Bool
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.headline)
                
                if let studio = studio {
                    Label(studio.name, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if showDate {
                        Label {
                            Text(session.sessionDate, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    
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
            
            SessionStatusBadge(status: session.status)
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct WeekSessionCard: View {
    let session: Session
    let studios: [Studio]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let startTime = session.startTime {
                Text(startTime, style: .time)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            
            Text(session.name)
                .font(.caption)
                .lineLimit(2)
            
            if let studio = studio {
                Text(studio.name)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(sessionColor.opacity(0.2))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(sessionColor, lineWidth: 1)
        )
    }
    
    var sessionColor: Color {
        switch session.status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct MonthSessionDot: View {
    let session: Session
    
    var sessionColor: Color {
        switch session.status {
        case .planned: return .blue
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(sessionColor)
                .frame(width: 6, height: 6)
            
            Text(session.name)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
    .modelContainer(for: [Session.self, Studio.self, Person.self], inMemory: true)
}
