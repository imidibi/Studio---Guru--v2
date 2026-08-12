//
//  MainNavigationView.swift
//  Studio Guru
//
//  Main navigation container for Studio Guru 2.0

import SwiftUI
import SwiftData

struct MainNavigationView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var selectedTab: NavigationTab = .dashboard
    
    enum NavigationTab {
        case dashboard
        case calendar
        case sessions
        case studios
        case people
        case projects
        case works
    }
    
    var body: some View {
        #if os(macOS)
        // macOS: Sidebar navigation
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section("Overview") {
                    NavigationLink(value: NavigationTab.dashboard) {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                    
                    NavigationLink(value: NavigationTab.calendar) {
                        Label("Calendar", systemImage: "calendar")
                    }
                }
                
                Section("Management") {
                    NavigationLink(value: NavigationTab.sessions) {
                        Label("Sessions", systemImage: "waveform")
                    }
                    
                    NavigationLink(value: NavigationTab.studios) {
                        Label("Studios", systemImage: "building.2")
                    }
                    
                    NavigationLink(value: NavigationTab.people) {
                        Label("People", systemImage: "person.3")
                    }
                }
                
                Section("Resources") {
                    NavigationLink(value: NavigationTab.projects) {
                        Label("Projects", systemImage: "folder")
                    }
                    
                    NavigationLink(value: NavigationTab.works) {
                        Label("Songs", systemImage: "music.note.list")
                    }
                }
            }
            .navigationTitle("Studio Guru")
            .listStyle(.sidebar)
        } detail: {
            destinationView(for: selectedTab)
        }
        #else
        // iOS: Tab bar navigation
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            .tag(NavigationTab.dashboard)
            
            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(NavigationTab.calendar)
            
            NavigationStack {
                SessionsListView()
            }
            .tabItem {
                Label("Sessions", systemImage: "waveform")
            }
            .tag(NavigationTab.sessions)
            
            NavigationStack {
                StudioCanvasView()
            }
            .tabItem {
                Label("Studios", systemImage: "building.2")
            }
            .tag(NavigationTab.studios)
            
            NavigationStack {
                PeopleListView()
            }
            .tabItem {
                Label("People", systemImage: "person.3")
            }
            .tag(NavigationTab.people)
        }
        #endif
    }
    
    #if os(macOS)
    @ViewBuilder
    private func destinationView(for tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .calendar:
            CalendarView()
        case .sessions:
            SessionsListView()
        case .studios:
            StudioCanvasView()
        case .people:
            PeopleListView()
        case .projects:
            ProjectsListView()
        case .works:
            WorksListView()
        }
    }
    #endif
}

#Preview {
    MainNavigationView()
        .environmentObject(StoreManager())
        .modelContainer(for: [Studio.self, Session.self, Project.self, Person.self, Work.self])
}
