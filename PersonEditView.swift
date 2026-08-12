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
    
    var isEditing: Bool { person != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Display Name", text: $displayName)
                        .foregroundStyle(displayName.isEmpty ? .secondary : .primary)
                    
                    if displayName.isEmpty && (!firstName.isEmpty || !lastName.isEmpty) {
                        Text("Auto: \(firstName) \(lastName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Photo") {
                    HStack {
                        if let photoData = photoData, let image = loadImage(from: photoData) {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text(initials)
                                        .font(.title3.bold())
                                        .foregroundStyle(.secondary)
                                }
                        }
                        
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
                            Button("Remove", role: .destructive) {
                                photoData = nil
                                selectedPhoto = nil
                            }
                        }
                    }
                }
                
                Section("Professional") {
                    TextField("Company", text: $company)
                    TextField("Default Role", text: $defaultRole)
                        #if os(iOS)
                        .textInputAutocapitalization(.words)
                        #endif
                }
                
                Section("Contact") {
                    TextField("Email", text: $email)
                        #if os(iOS)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        #endif
                    
                    TextField("Phone", text: $phone)
                        #if os(iOS)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        #endif
                    
                    TextField("Website", text: $website)
                        #if os(iOS)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                Section("Instruments") {
                    ForEach(instruments, id: \.self) { instrument in
                        HStack {
                            Label(instrument, systemImage: "music.note")
                            Spacer()
                            Button(role: .destructive) {
                                instruments.removeAll { $0 == instrument }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack {
                        TextField("Add instrument", text: $newInstrument)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            #endif
                        
                        Button {
                            if !newInstrument.isEmpty {
                                instruments.append(newInstrument)
                                newInstrument = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newInstrument.isEmpty)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
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
        }
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

#Preview {
    PersonEditView(person: nil)
        .modelContainer(for: Person.self, inMemory: true)
}
