import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var manager: BlockingManager

    // Regular schedule local state
    @State private var startHour:   Int = 22
    @State private var startMinute: Int = 0
    @State private var endHour:     Int = 8
    @State private var endMinute:   Int = 0

    // Blackout local state
    @State private var blackoutStartHour:   Int = 21
    @State private var blackoutStartMinute: Int = 0
    @State private var blackoutEndHour:     Int = 8
    @State private var blackoutEndMinute:   Int = 0

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Regular Schedule
                Section {
                    Toggle("Enable Daily Schedule", isOn: $manager.scheduleEnabled)
                        .onChange(of: manager.scheduleEnabled) { _, enabled in
                            if enabled { applySchedule() } else { manager.cancelSchedule() }
                        }
                } footer: {
                    Text("Selected apps are blocked automatically during the configured time window.")
                }

                Section("Block Start Time") {
                    timePicker(hour: $startHour, minute: $startMinute)
                }

                Section("Block End Time") {
                    timePicker(hour: $endHour, minute: $endMinute)
                }

                Section {
                    Button("Apply Schedule") { applySchedule() }
                        .disabled(manager.selectedAppCount == 0)
                } footer: {
                    if manager.selectedAppCount == 0 {
                        Text("Select apps on the Home tab first.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Schedule Summary") {
                    LabeledContent("Start",  value: formattedTime(hour: startHour,  minute: startMinute))
                    LabeledContent("End",    value: formattedTime(hour: endHour,    minute: endMinute))
                    LabeledContent("Apps",   value: "\(manager.selectedAppCount) selected")
                    LabeledContent("Status", value: manager.scheduleEnabled ? "Active" : "Inactive")
                }

                // MARK: Blackout Hours
                Section {
                    Toggle("Enable Blackout Hours", isOn: Binding(
                        get: { manager.blackoutEnabled },
                        set: { if $0 { manager.enableBlackout() } else { manager.disableBlackout() } }
                    ))
                } header: {
                    Text("Blackout Hours")
                } footer: {
                    Text("During blackout, EVERYTHING is blocked except always-free apps. Earning paused. Travel and emergency Claude override still work.")
                }

                Section("Blackout Start") {
                    timePicker(hour: $blackoutStartHour, minute: $blackoutStartMinute)
                }

                Section("Blackout End (next morning)") {
                    timePicker(hour: $blackoutEndHour, minute: $blackoutEndMinute)
                }

                Section {
                    Button("Apply Blackout Window") { applyBlackout() }
                } footer: {
                    if manager.isInBlackout {
                        Label("Blackout is active right now.", systemImage: "moon.fill")
                            .foregroundStyle(.indigo)
                    }
                }

                Section("Blackout Summary") {
                    LabeledContent("Start",  value: formattedTime(hour: blackoutStartHour,  minute: blackoutStartMinute))
                    LabeledContent("End",    value: formattedTime(hour: blackoutEndHour,    minute: blackoutEndMinute))
                    LabeledContent("Status", value: manager.isInBlackout ? "Active now" : (manager.blackoutEnabled ? "Scheduled" : "Inactive"))
                }
            }
            .navigationTitle("Schedule")
        }
        .onAppear { loadFromManager() }
    }

    // MARK: - Time Picker

    @ViewBuilder
    private func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        #if os(iOS)
        HStack {
            Picker("Hour", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text(":").font(.headline)

            Picker("Minute", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 100)
        #elseif os(macOS)
        HStack {
            Stepper(
                value: hour, in: 0...23,
                label: {
                    Text(String(format: "%02d", hour.wrappedValue))
                        .monospacedDigit()
                        .frame(minWidth: 28, alignment: .trailing)
                }
            )
            Text(":").font(.headline)
            Picker("", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .frame(width: 72)
        }
        #endif
    }

    // MARK: - Helpers

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

    private func applyBlackout() {
        manager.blackoutStart = DateComponents(hour: blackoutStartHour, minute: blackoutStartMinute)
        manager.blackoutEnd   = DateComponents(hour: blackoutEndHour,   minute: blackoutEndMinute)
        if manager.blackoutEnabled { manager.evaluateBlackoutWindow() }
    }

    private func loadFromManager() {
        startHour   = manager.scheduleStart.hour   ?? 22
        startMinute = manager.scheduleStart.minute ?? 0
        endHour     = manager.scheduleEnd.hour     ?? 8
        endMinute   = manager.scheduleEnd.minute   ?? 0

        blackoutStartHour   = manager.blackoutStart.hour   ?? 21
        blackoutStartMinute = manager.blackoutStart.minute ?? 0
        blackoutEndHour     = manager.blackoutEnd.hour     ?? 8
        blackoutEndMinute   = manager.blackoutEnd.minute   ?? 0
    }
}

#Preview {
    ScheduleView()
        .environmentObject(BlockingManager())
}
