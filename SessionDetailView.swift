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
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    let session: Session
    
    @State private var showingAddGear = false
    @State private var showingAddArtistGear = false
    @State private var showingDuplicateOptions = false
    @State private var sessionsForDuplication: [Session] = []
    
    var snapshot: SessionConfigurationSnapshot? {
        session.configurationSnapshot
    }
    
    var body: some View {
        if let snapshot = snapshot {
            SessionCanvasContent(session: session, snapshot: snapshot)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            Button {
                                showingAddGear = true
                            } label: {
                                Label("Add from Gear Locker", systemImage: "archivebox")
                            }
                            
                            Button {
                                showingAddArtistGear = true
                            } label: {
                                Label("Add Artist Gear", systemImage: "person.badge.plus")
                            }
                            
                            Divider()
                            
                            Button {
                                loadSessionsForDuplication()
                                showingDuplicateOptions = true
                            } label: {
                                Label("Duplicate from Session", systemImage: "doc.on.doc")
                            }
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddGear) {
                    AddSessionGearView(session: session, onGearAdded: {})
                }
                .sheet(isPresented: $showingAddArtistGear) {
                    AddArtistGearView(session: session, onGearAdded: {})
                }
                .sheet(isPresented: $showingDuplicateOptions) {
                    DuplicateSessionCanvasView(
                        session: session,
                        availableSessions: sessionsForDuplication,
                        onDuplicated: {}
                    )
                }
        } else {
            ContentUnavailableView(
                "No Canvas Available",
                systemImage: "square.grid.3x3",
                description: Text("Edit this session and assign a studio to create a canvas")
            )
        }
    }
    
    private func loadSessionsForDuplication() {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.sessionDate, order: .reverse)]
        )
        
        if let allSessions = try? modelContext.fetch(descriptor) {
            // Filter to sessions that have a snapshot and aren't this session
            sessionsForDuplication = allSessions.filter {
                $0.id != session.id && $0.configurationSnapshot != nil
            }
        }
    }
}

// Helper view for stats


// MARK: - Gear Tab

struct SessionGearTab: View {
    @Environment(\.modelContext) private var modelContext
    let session: Session
    
    @State private var showingAddGear = false
    @State private var reservations: [GearReservation] = []
    
    var snapshot: SessionConfigurationSnapshot? {
        session.configurationSnapshot
    }
    
    var devices: [SnapshotDevice] {
        snapshot?.devices?.sorted { device1, device2 in
            let name1 = device1.nickname.isEmpty ? device1.model : device1.nickname
            let name2 = device2.nickname.isEmpty ? device2.model : device2.nickname
            return name1 < name2
        } ?? []
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if devices.isEmpty {
                    ContentUnavailableView(
                        "No Gear Tracked",
                        systemImage: "guitars",
                        description: Text("Add gear used during this session")
                    )
                } else {
                    ForEach(devices) { device in
                        SessionGearRow(
                            device: device,
                            reservation: reservationForDevice(device),
                            session: session
                        )
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
            AddSessionGearView(session: session, onGearAdded: loadReservations)
        }
        .task {
            loadReservations()
        }
    }
    
    private func loadReservations() {
        let sessionID = session.id
        let descriptor = FetchDescriptor<GearReservation>(
            predicate: #Predicate { $0.sessionID == sessionID }
        )
        reservations = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func reservationForDevice(_ device: SnapshotDevice) -> GearReservation? {
        reservations.first { $0.deviceID == device.originalDeviceID }
    }
}

struct SessionGearRow: View {
    @Environment(\.modelContext) private var modelContext
    let device: SnapshotDevice
    let reservation: GearReservation?
    let session: Session
    
    @Query private var allDevices: [DeviceInstance]
    
    var originalDevice: DeviceInstance? {
        allDevices.first { $0.id == device.originalDeviceID }
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Ownership icon
                    Circle()
                        .fill(colorForOwnership(device.ownershipType).opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: iconForOwnership(device.ownershipType))
                                .foregroundStyle(colorForOwnership(device.ownershipType))
                                .font(.title3)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.nickname.isEmpty ? device.model : device.nickname)
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Text(device.ownershipType.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(colorForOwnership(device.ownershipType).opacity(0.2))
                                .foregroundStyle(colorForOwnership(device.ownershipType))
                                .cornerRadius(4)
                            
                            if !device.manufacturer.isEmpty {
                                Text(device.manufacturer)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Reservation details for gear locker items
                        if device.ownershipType == .gearLocker, let reservation = reservation {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text("\(formatDate(reservation.startDateTime)) - \(formatTime(reservation.endDateTime))")
                                    .font(.caption)
                            }
                            .foregroundStyle(.purple)
                            .padding(.top, 2)
                        }
                        
                        // Owner name for artist gear
                        if device.ownershipType == .artistProvided && !device.ownerName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .font(.caption)
                                Text(device.ownerName)
                                    .font(.caption)
                            }
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                
                // Settings notes
                if !device.settingsNotes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Settings", systemImage: "slider.horizontal.3")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(device.settingsNotes)
                            .font(.body)
                    }
                }
            }
            .padding(4)
        }
    }
    
    private func iconForOwnership(_ ownership: GearOwnership) -> String {
        switch ownership {
        case .studioOwned: return "building.2"
        case .gearLocker: return "cube.box"
        case .artistProvided: return "person.circle"
        case .rental: return "dollarsign.circle"
        }
    }
    
    private func colorForOwnership(_ ownership: GearOwnership) -> Color {
        switch ownership {
        case .studioOwned: return .blue
        case .gearLocker: return .purple
        case .artistProvided: return .orange
        case .rental: return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
