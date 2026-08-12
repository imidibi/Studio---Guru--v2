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
    
    @State private var selectedTab: NavigationTab = .studios
    
    enum NavigationTab {
        case studios
        case sessions
        case projects
        case people
        case works
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Studios Tab (existing functionality)
            StudioCanvasView()
                .tabItem {
                    Label("Studios", systemImage: "building.2")
                }
                .tag(NavigationTab.studios)
            
            // Sessions Tab (new)
            SessionsListView()
                .tabItem {
                    Label("Sessions", systemImage: "calendar")
                }
                .tag(NavigationTab.sessions)
            
            // Projects Tab (new)
            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }
                .tag(NavigationTab.projects)
            
            // People Tab (new)
            PeopleListView()
                .tabItem {
                    Label("People", systemImage: "person.3")
                }
                .tag(NavigationTab.people)
            
            // Works/Songs Tab (new)
            WorksListView()
                .tabItem {
                    Label("Songs", systemImage: "music.note.list")
                }
                .tag(NavigationTab.works)
        }
    }
}

#Preview {
    MainNavigationView()
        .environmentObject(StoreManager())
        .modelContainer(for: [Studio.self, Session.self, Project.self, Person.self, Work.self])
}
