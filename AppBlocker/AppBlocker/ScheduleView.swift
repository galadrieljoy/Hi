import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var manager: BlockingManager

    // Local copies for the pickers
    @State private var startHour:   Int = 22
    @State private var startMinute: Int = 0
    @State private var endHour:     Int = 8
    @State private var endMinute:   Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Daily Schedule", isOn: $manager.scheduleEnabled)
                        .onChange(of: manager.scheduleEnabled) { _, enabled in
                            if enabled {
                                applySchedule()
                            } else {
                                manager.cancelSchedule()
                            }
                        }
                } footer: {
                    Text("When enabled, selected apps will be blocked automatically during the time window you set.")
                }

                Section("Block Start Time") {
                    timePicker(hour: $startHour, minute: $startMinute)
                }

                Section("Block End Time") {
                    timePicker(hour: $endHour, minute: $endMinute)
                }

                Section {
                    Button("Apply Schedule") {
                        applySchedule()
                    }
                    .disabled(manager.selection.applicationTokens.isEmpty)
                } footer: {
                    if manager.selection.applicationTokens.isEmpty {
                        Text("Select apps on the Home tab first.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Summary") {
                    LabeledContent("Start", value: formattedTime(hour: startHour, minute: startMinute))
                    LabeledContent("End",   value: formattedTime(hour: endHour,   minute: endMinute))
                    LabeledContent("Apps",  value: "\(manager.selection.applicationTokens.count) selected")
                    LabeledContent("Status", value: manager.scheduleEnabled ? "Active" : "Inactive")
                }
            }
            .navigationTitle("Schedule")
        }
        .onAppear { loadFromManager() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack {
            Picker("Hour", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(":")
                .font(.headline)

            Picker("Minute", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 100)
    }

    private func formattedTime(hour: Int, minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    private func applySchedule() {
        manager.scheduleStart = DateComponents(hour: startHour,  minute: startMinute)
        manager.scheduleEnd   = DateComponents(hour: endHour,    minute: endMinute)
        manager.enableSchedule()
    }

    private func loadFromManager() {
        startHour   = manager.scheduleStart.hour   ?? 22
        startMinute = manager.scheduleStart.minute ?? 0
        endHour     = manager.scheduleEnd.hour     ?? 8
        endMinute   = manager.scheduleEnd.minute   ?? 0
    }
}

#Preview {
    ScheduleView()
        .environmentObject(BlockingManager())
}
