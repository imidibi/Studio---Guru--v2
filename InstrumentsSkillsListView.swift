//
//  InstrumentsSkillsListView.swift
//  Studio Guru
//
//  Manage instruments and skills library

import SwiftUI
import SwiftData

struct InstrumentsSkillsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InstrumentSkill.sortOrder) private var allInstrumentsSkills: [InstrumentSkill]
    
    @State private var showingAddSheet = false
    @State private var showArchived = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private var categories: [String] {
        let cats = Set(allInstrumentsSkills.map { $0.category }).sorted()
        return ["All"] + cats
    }
    
    private var filteredInstrumentsSkills: [InstrumentSkill] {
        allInstrumentsSkills.filter { skill in
            let matchesArchived = showArchived || !skill.isArchived
            let matchesSearch = searchText.isEmpty || skill.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || skill.category == selectedCategory
            return matchesArchived && matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search instruments/skills", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
                .cornerRadius(8)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .frame(width: 180)
            }
            .padding()
            
            Divider()
            
            // List
            List {
                ForEach(filteredInstrumentsSkills) { skill in
                    InstrumentSkillRow(skill: skill)
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle("Instruments & Skills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    showArchived.toggle()
                } label: {
                    Label(showArchived ? "Hide Archived" : "Show Archived", 
                          systemImage: showArchived ? "archivebox.fill" : "archivebox")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            InstrumentSkillEditView(skill: nil)
        }
    }
}

struct InstrumentSkillRow: View {
    @Environment(\.modelContext) private var modelContext
    let skill: InstrumentSkill
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.body)
                
                if !skill.category.isEmpty {
                    Text(skill.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if skill.isArchived {
                Text("Archived")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.gradient)
                    .clipShape(Capsule())
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            if skill.isArchived {
                Button {
                    skill.isArchived = false
                    skill.markAsModified()
                } label: {
                    Label("Unarchive", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    skill.isArchived = true
                    skill.markAsModified()
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            InstrumentSkillEditView(skill: skill)
        }
        .alert("Delete Instrument/Skill?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(skill)
            }
        } message: {
            Text("This will permanently delete \"\(skill.name)\". This cannot be undone.")
        }
    }
}

struct InstrumentSkillEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InstrumentSkill.sortOrder) private var allSkills: [InstrumentSkill]
    
    let skill: InstrumentSkill?
    
    @State private var name = ""
    @State private var category = ""
    @State private var sortOrder = 0
    
    private let commonCategories = ["Instrument", "Production", "Engineering", "Writing", "Other"]
    
    var isEditing: Bool { skill != nil }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GroupBox("Details") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("e.g., Guitar, Producer, Mix Engineer", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    Picker("Category", selection: $category) {
                                        Text("Select category").tag("")
                                        ForEach(commonCategories, id: \.self) { cat in
                                            Text(cat).tag(cat)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity)
                                    
                                    Text("or")
                                        .foregroundStyle(.secondary)
                                    
                                    TextField("Custom", text: $category)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sort Order")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    TextField("Sort Order", value: $sortOrder, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                    Stepper("", value: $sortOrder, in: 0...1000)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Instrument/Skill" : "New Instrument/Skill")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadData() }
        }
    }
    
    private func loadData() {
        guard let skill = skill else {
            // For new skills, set sort order to highest + 1
            sortOrder = (allSkills.map { $0.sortOrder }.max() ?? 0) + 1
            return
        }
        name = skill.name
        category = skill.category
        sortOrder = skill.sortOrder
    }
    
    private func save() {
        if let skill = skill {
            skill.name = name
            skill.category = category
            skill.sortOrder = sortOrder
            skill.markAsModified()
        } else {
            let newSkill = InstrumentSkill(name: name, category: category, sortOrder: sortOrder)
            modelContext.insert(newSkill)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        InstrumentsSkillsListView()
    }
    .modelContainer(for: InstrumentSkill.self, inMemory: true)
}
