//
//  SessionDetailView.swift
//  Studio Guru
//
//  Session detail view with tabs

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @State private var selectedTab: SessionTab = .overview
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    
    enum SessionTab {
        case overview, people, songs, setup, gear, notes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Tab", selection: $selectedTab) {
                Label("Overview", systemImage: "info.circle").tag(SessionTab.overview)
                Label("People", systemImage: "person.3").tag(SessionTab.people)
                Label("Songs", systemImage: "music.note.list").tag(SessionTab.songs)
                Label("Setup", systemImage: "square.grid.3x3").tag(SessionTab.setup)
                Label("Gear", systemImage: "guitars").tag(SessionTab.gear)
                Label("Notes", systemImage: "note.text").tag(SessionTab.notes)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab content
            TabView(selection: $selectedTab) {
                SessionOverviewTab(session: session)
                    .tag(SessionTab.overview)
                
                SessionPeopleTab(session: session)
                    .tag(SessionTab.people)
                
                SessionSongsTab(session: session)
                    .tag(SessionTab.songs)
                
                SessionSetupTab(session: session)
                    .tag(SessionTab.setup)
                
                SessionGearTab(session: session)
                    .tag(SessionTab.gear)
                
                SessionNotesTab(session: session)
                    .tag(SessionTab.notes)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #endif
        }
        .navigationTitle(session.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isEditing = true } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            SessionEditView(session: session)
        }
        .alert("Delete Session?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Archive", role: .destructive) {
                session.isArchived = true
                session.markAsModified()
            }
            Button("Delete", role: .destructive) {
                modelContext.delete(session)
            }
        }
    }
}

// MARK: - Overview Tab

struct SessionOverviewTab: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @Query private var studios: [Studio]
    @Query private var projects: [Project]
    
    var studio: Studio? {
        studios.first { $0.id == session.studioID }
    }
    
    var project: Project? {
        guard let projectID = session.projectID else { return nil }
        return projects.first { $0.id == projectID }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(session.name)
                                .font(.title2.bold())
                            Text(session.sessionDate, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        SessionStatusBadge(status: session.status)
                    }
                }
                .padding()
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.systemBackground))
                #endif
                .cornerRadius(12)
                
                // Details
                GroupBox("Details") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let studio = studio {
                            LabeledContent("Studio") {
                                Text(studio.name)
                            }
                        }
                        
                        if let project = project {
                            LabeledContent("Project") {
                                Text(project.name)
                            }
                        }
                        
                        LabeledContent("Type") {
                            Text(session.sessionType.rawValue.capitalized)
                        }
                        
                        if !session.artistName.isEmpty {
                            LabeledContent("Artist") {
                                Text(session.artistName)
                            }
                        }
                        
                        if !session.clientName.isEmpty {
                            LabeledContent("Client") {
                                Text(session.clientName)
                            }
                        }
                        
                        if let startTime = session.startTime {
                            LabeledContent("Start Time") {
                                Text(startTime, style: .time)
                            }
                        }
                        
                        if let endTime = session.endTime {
                            LabeledContent("End Time") {
                                Text(endTime, style: .time)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - People Tab

struct SessionPeopleTab: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @State private var participants: [SessionParticipant] = []
    @State private var showingAddPerson = false
    @State private var refreshTrigger = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if participants.isEmpty {
                    ContentUnavailableView(
                        "No Participants",
                        systemImage: "person.3",
                        description: Text("Add people who participated in this session")
                    )
                } else {
                    ForEach(participants) { participant in
                        SessionParticipantRow(participant: participant)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddPerson = true } label: {
                    Label("Add Person", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            loadParticipants() // Refresh when sheet dismisses
        } content: {
            AddSessionParticipantView(session: session)
        }
        .task(id: refreshTrigger) {
            loadParticipants()
        }
    }
    
    private func loadParticipants() {
        let sessionID = session.id
        let descriptor = FetchDescriptor<SessionParticipant>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        participants = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct SessionParticipantRow: View {
    @Environment(\.modelContext) private var modelContext
    let participant: SessionParticipant
    
    @Query private var allPeople: [Person]
    @State private var showingPersonDetail = false
    
    var person: Person? {
        allPeople.first { $0.id == participant.personID }
    }
    
    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                // Person photo
                if let person = person {
                    if let photoData = person.photoData, let image = loadImage(from: photoData) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay {
                                Text(person.initials)
                                    .font(.callout.bold())
                                    .foregroundStyle(.secondary)
                            }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let person = person {
                        Text(person.displayName)
                            .font(.headline)
                    } else {
                        Text("Unknown Person")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !participant.role.isEmpty {
                        Text(participant.role)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !participant.notes.isEmpty {
                        Text(participant.notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                if person != nil {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
        .contentShape(Rectangle())
        #if os(macOS)
        .onTapGesture(count: 2) {
            if person != nil {
                showingPersonDetail = true
            }
        }
        #else
        .onTapGesture {
            if person != nil {
                showingPersonDetail = true
            }
        }
        #endif
        .sheet(isPresented: $showingPersonDetail) {
            if let person = person {
                NavigationStack {
                    PersonDetailView(person: person)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showingPersonDetail = false
                                }
                            }
                        }
                }
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

// MARK: - Songs Tab

struct SessionSongsTab: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @State private var sessionWorks: [SessionWork] = []
    @State private var showingAddSong = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if sessionWorks.isEmpty {
                    ContentUnavailableView(
                        "No Songs",
                        systemImage: "music.note.list",
                        description: Text("Add songs worked on during this session")
                    )
                } else {
                    ForEach(sessionWorks.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })) { sessionWork in
                        SessionWorkRow(sessionWork: sessionWork)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSong = true } label: {
                    Label("Add Song", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSong) {
            loadSessionWorks() // Refresh when sheet dismisses
        } content: {
            AddSessionWorkView(session: session)
        }
        .task {
            loadSessionWorks()
        }
    }
    
    private func loadSessionWorks() {
        let sessionID = session.id
        let descriptor = FetchDescriptor<SessionWork>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        sessionWorks = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct SessionWorkRow: View {
    @Environment(\.modelContext) private var modelContext
    let sessionWork: SessionWork
    
    @Query private var allWorks: [Work]
    
    var work: Work? {
        allWorks.first { $0.id == sessionWork.workID }
    }
    
    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                // Music note icon
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let work = work {
                        Text(work.title)
                            .font(.headline)
                        if !work.artistName.isEmpty {
                            Text(work.artistName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if !work.versionName.isEmpty {
                            Text(work.versionName)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        Text("Unknown Work")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !sessionWork.notes.isEmpty {
                        Text(sessionWork.notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Sequence number badge
                if sessionWork.sequenceNumber > 0 {
                    Text("#\(sessionWork.sequenceNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Setup Tab

struct SessionSetupTab: View {
    let session: Session
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if session.configurationSnapshot != nil {
                    Text("Studio setup snapshot captured")
                        .font(.headline)
                    Text("The exact configuration used during this session has been preserved")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    ContentUnavailableView(
                        "No Setup Snapshot",
                        systemImage: "square.grid.3x3",
                        description: Text("The studio setup for this session was not captured")
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Gear Tab

struct SessionGearTab: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @State private var equipment: [SessionEquipment] = []
    @State private var showingAddGear = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if equipment.isEmpty {
                    ContentUnavailableView(
                        "No Gear Tracked",
                        systemImage: "guitars",
                        description: Text("Add gear used during this session")
                    )
                } else {
                    ForEach(equipment) { item in
                        SessionEquipmentRow(equipment: item)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddGear = true } label: {
                    Label("Add Gear", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGear) {
            loadEquipment() // Refresh when sheet dismisses
        } content: {
            // TODO: Create AddSessionEquipmentView
            Text("Add Gear - Coming Soon")
        }
        .task {
            loadEquipment()
        }
    }
    
    private func loadEquipment() {
        let sessionID = session.id
        let descriptor = FetchDescriptor<SessionEquipment>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        equipment = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct SessionEquipmentRow: View {
    @Environment(\.modelContext) private var modelContext
    let equipment: SessionEquipment
    
    @Query private var allDevices: [DeviceInstance]
    
    var device: DeviceInstance? {
        allDevices.first { $0.id == equipment.equipmentID }
    }
    
    var body: some View {
        GroupBox {
            HStack(spacing: 12) {
                // Gear icon
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "guitars")
                            .foregroundStyle(.orange)
                            .font(.title3)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let device = device {
                        Text("\(device.manufacturer) \(device.model)")
                            .font(.headline)
                        if !device.nickname.isEmpty && device.nickname != device.model {
                            Text(device.nickname)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Unknown Device")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !equipment.purpose.isEmpty {
                        Text(equipment.purpose)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                    
                    if !equipment.settings.isEmpty {
                        Text("Settings: \(equipment.settings)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Notes Tab

struct SessionNotesTab: View {
    let session: Session
    
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if session.notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Add notes about this session")
                    )
                } else {
                    Text(session.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isEditing = true } label: {
                    Label("Edit Notes", systemImage: "pencil")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: Session(studioID: UUID(), name: "Test Session"))
    }
    .modelContainer(for: Session.self, inMemory: true)
}
