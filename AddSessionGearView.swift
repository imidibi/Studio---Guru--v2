//
//  AddSessionGearView.swift
//  Studio Guru
//
//  Add gear from gear locker to a session with reservation

import SwiftUI
import SwiftData

struct AddSessionGearView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allDevices: [DeviceInstance]
    
    let session: Session
    let onGearAdded: () -> Void
    
    @State private var selectedDevice: DeviceInstance?
    @State private var startDateTime: Date
    @State private var endDateTime: Date
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Filter to only show gear locker devices
    private var gearLockerDevices: [DeviceInstance] {
        allDevices.filter { $0.isInGearLocker }
    }
    
    init(session: Session, onGearAdded: @escaping () -> Void) {
        self.session = session
        self.onGearAdded = onGearAdded
        
        // Initialize with session date and default 8-hour duration
        let sessionDate = session.sessionDate
        let start = session.startTime ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: sessionDate) ?? sessionDate
        let end = session.endTime ?? Calendar.current.date(byAdding: .hour, value: 8, to: start) ?? start
        
        _startDateTime = State(initialValue: start)
        _endDateTime = State(initialValue: end)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Gear") {
                    if gearLockerDevices.isEmpty {
                        Text("No gear available in Gear Locker")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Device", selection: $selectedDevice) {
                            Text("Select device").tag(nil as DeviceInstance?)
                            ForEach(gearLockerDevices) { device in
                                HStack {
                                    Text(device.nickname.isEmpty ? device.model : device.nickname)
                                    Text("•").foregroundStyle(.secondary)
                                    Text(device.manufacturer)
                                        .foregroundStyle(.secondary)
                                }
                                .tag(device as DeviceInstance?)
                            }
                        }
                        .labelsHidden()
                    }
                }
                
                if let device = selectedDevice {
                    Section("Reservation Details") {
                        DatePicker("Start", selection: $startDateTime, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End", selection: $endDateTime, displayedComponents: [.date, .hourAndMinute])
                        
                        // Duration display
                        LabeledContent("Duration") {
                            Text(formatDuration(from: startDateTime, to: endDateTime))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Device Info") {
                        LabeledContent("Manufacturer", value: device.manufacturer)
                        LabeledContent("Model", value: device.model)
                        if !device.serialNumber.isEmpty {
                            LabeledContent("Serial", value: device.serialNumber)
                        }
                    }
                    
                    // Check for conflicts
                    if let conflicts = checkConflicts(for: device) {
                        Section {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reservation Conflict")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                    Text("This device is already reserved:")
                                        .font(.subheadline)
                                    ForEach(conflicts, id: \.id) { conflictSession in
                                        Text("• \(conflictSession.name)")
                                            .font(.caption)
                                    }
                                }
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Gear")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addGear()
                    }
                    .disabled(selectedDevice == nil || checkConflicts(for: selectedDevice) != nil)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func checkConflicts(for device: DeviceInstance?) -> [Session]? {
        guard let device = device else { return nil }
        
        do {
            return try SessionSnapshotHelper.checkReservationConflicts(
                for: device,
                start: startDateTime,
                end: endDateTime,
                modelContext: modelContext
            )
        } catch {
            return nil
        }
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    private func addGear() {
        guard let device = selectedDevice else { return }
        
        do {
            // Add device to session snapshot with reservation
            try SessionSnapshotHelper.addGearLockerDevice(
                device: device,
                to: session,
                startDateTime: startDateTime,
                endDateTime: endDateTime,
                modelContext: modelContext
            )
            
            onGearAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    AddSessionGearView(
        session: Session(studioID: UUID(), name: "Test Session"),
        onGearAdded: {}
    )
    .modelContainer(for: [DeviceInstance.self, Session.self], inMemory: true)
}
