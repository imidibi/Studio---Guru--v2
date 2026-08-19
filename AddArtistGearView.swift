//
//  AddArtistGearView.swift
//  Studio Guru
//
//  Form for adding artist-provided gear to a session
//

import SwiftUI
import SwiftData

struct AddArtistGearView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let session: Session
    let onGearAdded: () -> Void
    
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var nickname = ""
    @State private var ownerName = ""
    @State private var settingsNotes = ""
    @State private var selectedCategory: DeviceCategory = .other
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Device Information") {
                    TextField("Manufacturer", text: $manufacturer)
                    TextField("Model", text: $model)
                    TextField("Nickname (optional)", text: $nickname)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DeviceCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section("Owner Information") {
                    TextField("Owner/Artist Name", text: $ownerName)
                        .autocorrectionDisabled()
                }
                
                Section("Settings & Notes") {
                    TextEditor(text: $settingsNotes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Text("This gear will be added to the session canvas as artist-provided equipment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Artist Gear")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addArtistGear() }
                        .disabled(manufacturer.isEmpty || model.isEmpty)
                }
            }
        }
    }
    
    private func addArtistGear() {
        do {
            try SessionSnapshotHelper.addArtistGear(
                manufacturer: manufacturer,
                model: model,
                nickname: nickname.isEmpty ? model : nickname,
                category: selectedCategory,
                ownerName: ownerName,
                settingsNotes: settingsNotes,
                to: session,
                modelContext: modelContext
            )
            
            onGearAdded()
            dismiss()
        } catch {
            print("❌ Failed to add artist gear: \(error)")
        }
    }
}
