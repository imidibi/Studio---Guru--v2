//
//  PersonEditView.swift
//  Studio Guru
//
//  Add/Edit person form

import SwiftUI
import SwiftData
import PhotosUI

struct PersonEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \InstrumentSkill.sortOrder) private var allInstrumentsSkills: [InstrumentSkill]
    
    let person: Person?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var displayName = ""
    @State private var company = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var defaultRole = ""
    @State private var instruments: [String] = []
    @State private var notes = ""
    @State private var photoData: Data?
    
    @State private var newInstrument = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingAddInstrumentSheet = false
    @State private var newInstrumentName = ""
    @State private var newInstrumentCategory = ""
    
    var isEditing: Bool { person != nil }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photo
                    GroupBox("Photo") {
                        HStack(spacing: 16) {
                            if let photoData = photoData, let image = loadImage(from: photoData) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay {
                                        Text(initials)
                                            .font(.title2.bold())
                                            .foregroundStyle(.secondary)
                                    }
                            }
                            
                            VStack(spacing: 12) {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Label("Choose Photo", systemImage: "photo")
                                }
                                .onChange(of: selectedPhoto) { oldValue, newValue in
                                    Task {
                                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                            photoData = data
                                        }
                                    }
                                }
                                
                                if photoData != nil {
                                    Button("Remove Photo", role: .destructive) {
                                        photoData = nil
                                        selectedPhoto = nil
                                    }
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    
                    // Basic Information
                    GroupBox("Basic Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("First Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("First name", text: $firstName)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Name")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Last name", text: $lastName)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name (Optional)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Override display name", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                                
                                if displayName.isEmpty && (!firstName.isEmpty || !lastName.isEmpty) {
                                    Text("Will use: \(firstName) \(lastName)")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                    
                    // Professional
                    GroupBox("Professional") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Company")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Company or organization", text: $company)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default Role")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("e.g., Producer, Engineer, Artist", text: $defaultRole)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.words)
                                    #endif
                            }
                        }
                    }
                    
                    // Contact Information
                    GroupBox("Contact Information") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("email@example.com", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("Phone number", text: $phone)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                    #endif
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Website")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                TextField("https://example.com", text: $website)
                                    .textFieldStyle(.roundedBorder)
                                    #if os(iOS)
                                    .textContentType(.URL)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    #endif
                            }
                        }
                    }
                    
                    // Instruments & Skills
                    GroupBox("Instruments & Skills") {
                        VStack(alignment: .leading, spacing: 12) {
                            if instruments.isEmpty {
                                Text("No instruments or skills added")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                            } else {
                                ForEach(instruments, id: \.self) { instrument in
                                    HStack {
                                        // Show category if available
                                        if let skill = allInstrumentsSkills.first(where: { $0.name == instrument }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(instrument)
                                                    .font(.subheadline)
                                                if !skill.category.isEmpty {
                                                    Text(skill.category)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        } else {
                                            Text(instrument)
                                                .font(.subheadline)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(role: .destructive) {
                                            instruments.removeAll { $0 == instrument }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add from library")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    Picker("Select instrument/skill", selection: $newInstrument) {
                                        Text("Select instrument or skill").tag("")
                                        ForEach(availableInstrumentsSkills, id: \.name) { skill in
                                            HStack {
                                                Text(skill.name)
                                                if !skill.category.isEmpty {
                                                    Text("(\(skill.category))")
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .tag(skill.name)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity)
                                    
                                    Button {
                                        if !newInstrument.isEmpty {
                                            instruments.append(newInstrument)
                                            newInstrument = ""
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(newInstrument.isEmpty)
                                }
                                
                                Button {
                                    showingAddInstrumentSheet = true
                                } label: {
                                    Label("Create New Instrument/Skill", systemImage: "plus.app")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Notes
                    GroupBox("Notes") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Notes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .overlay(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Add any notes about this person...")
                                            .foregroundStyle(.tertiary)
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Person" : "New Person")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePerson()
                    }
                    .disabled(firstName.isEmpty && lastName.isEmpty)
                }
            }
            .onAppear {
                loadPersonData()
            }
            .sheet(isPresented: $showingAddInstrumentSheet) {
                QuickAddInstrumentSkillView(
                    name: $newInstrumentName,
                    category: $newInstrumentCategory,
                    onSave: { name, category in
                        let newSkill = InstrumentSkill(
                            name: name,
                            category: category,
                            sortOrder: (allInstrumentsSkills.map { $0.sortOrder }.max() ?? 0) + 1
                        )
                        modelContext.insert(newSkill)
                        instruments.append(name)
                        newInstrumentName = ""
                        newInstrumentCategory = ""
                    }
                )
            }
        }
    }
    
    private var availableInstrumentsSkills: [InstrumentSkill] {
        allInstrumentsSkills
            .filter { !$0.isArchived && !instruments.contains($0.name) }
    }
    
    private var initials: String {
        let first = firstName.prefix(1)
        let last = lastName.prefix(1)
        return "\(first)\(last)".uppercased()
    }
    
    private func loadPersonData() {
        guard let person = person else { return }
        
        firstName = person.firstName
        lastName = person.lastName
        displayName = person.displayName
        company = person.company
        email = person.email
        phone = person.phone
        website = person.website
        defaultRole = person.defaultRole
        instruments = person.instruments
        notes = person.notes
        photoData = person.photoData
    }
    
    private func savePerson() {
        if let person = person {
            // Update existing
            person.firstName = firstName
            person.lastName = lastName
            person.displayName = displayName.isEmpty ? "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) : displayName
            person.company = company
            person.email = email
            person.phone = phone
            person.website = website
            person.defaultRole = defaultRole
            person.instruments = instruments
            person.notes = notes
            person.photoData = photoData
            person.markAsModified()
        } else {
            // Create new
            let newPerson = Person(
                firstName: firstName,
                lastName: lastName,
                displayName: displayName.isEmpty ? "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) : displayName
            )
            newPerson.company = company
            newPerson.email = email
            newPerson.phone = phone
            newPerson.website = website
            newPerson.defaultRole = defaultRole
            newPerson.instruments = instruments
            newPerson.notes = notes
            newPerson.photoData = photoData
            
            modelContext.insert(newPerson)
        }
        
        dismiss()
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

// MARK: - Quick Add Instrument/Skill Sheet

struct QuickAddInstrumentSkillView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var name: String
    @Binding var category: String
    let onSave: (String, String) -> Void
    
    private let commonCategories = ["Instrument", "Production", "Engineering", "Writing", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("New Instrument/Skill") {
                    TextField("Name", text: $name)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                    
                    Picker("Category", selection: $category) {
                        Text("None").tag("")
                        ForEach(commonCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle("Add Instrument/Skill")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        name = ""
                        category = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(name, category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 250)
        #endif
    }
}

#Preview {
    PersonEditView(person: nil)
        .modelContainer(for: Person.self, inMemory: true)
}
