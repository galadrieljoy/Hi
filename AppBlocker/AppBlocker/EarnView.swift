import SwiftUI

// MARK: - EarnView

/// Tab where users can claim completed tasks to earn unblocked screen time.
struct EarnView: View {
    @EnvironmentObject private var manager: BlockingManager
    @State private var showAddTask = false
    @State private var selectedTask: EarnTask?

    var body: some View {
        NavigationStack {
            List {
                // Active earned session banner
                if manager.earnSessionActive {
                    Section {
                        earnSessionBanner
                    }
                } else if manager.earnedMinutesRemaining > 0 {
                    Section {
                        pendingMinutesBanner
                    }
                }

                // Blackout notice
                if manager.isInBlackout {
                    Section {
                        Label("Earning is paused during blackout hours.", systemImage: "moon.fill")
                            .foregroundStyle(.indigo)
                            .font(.subheadline)
                    }
                }

                // Task list
                Section {
                    if manager.earnTasks.isEmpty {
                        Text("No tasks yet. Add tasks below to start earning screen time.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(manager.earnTasks) { task in
                            EarnTaskRow(task: task) {
                                selectedTask = task
                            }
                        }
                        .onDelete { indices in
                            manager.earnTasks.remove(atOffsets: indices)
                        }
                    }
                } header: {
                    Text("Your Tasks")
                } footer: {
                    Text("Tap a task to tell Claude you completed it. Claude will verify your claim before granting time.")
                }

                // Add task
                Section {
                    Button {
                        showAddTask = true
                    } label: {
                        Label("Add New Task", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Earn Time")
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet()
                    .environmentObject(manager)
            }
            .sheet(item: $selectedTask) { task in
                ClaudeChatView(mode: .earnTask(task: task))
                    .environmentObject(manager)
            }
        }
    }

    // MARK: - Banners

    private var earnSessionBanner: some View {
        HStack {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Earned Session Active")
                    .font(.subheadline.bold())
                Text("\(manager.earnedMinutesRemaining) minute(s) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatMinutes(manager.earnedMinutesRemaining))
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }

    private var pendingMinutesBanner: some View {
        HStack {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(manager.earnedMinutesRemaining) minute(s) banked")
                    .font(.subheadline.bold())
                Text("Ready to use — tap Start to unblock apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Start") {
                manager.startEarnedSession()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(manager.isInBlackout)
        }
        .padding(.vertical, 4)
    }

    private func formatMinutes(_ m: Int) -> String {
        let h = m / 60
        let min = m % 60
        if h > 0 { return String(format: "%d:%02d", h, min) }
        return "\(min)m"
    }
}

// MARK: - EarnTaskRow

struct EarnTaskRow: View {
    let task: EarnTask
    let onClaim: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.body.bold())
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Label("\(task.minutesEarned) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button("Claim") {
                onClaim()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddTaskSheet

struct AddTaskSheet: View {
    @EnvironmentObject private var manager: BlockingManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var minutes = 30

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && minutes > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name (e.g. Do homework)", text: $name)
                    TextField("Description (optional)", text: $description)
                }

                Section("Time Reward") {
                    Stepper("\(minutes) minutes", value: $minutes, in: 5...120, step: 5)
                }

                Section {
                    Text("Claude will verify you actually completed this task before granting the time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let task = EarnTask(
                            name: name.trimmingCharacters(in: .whitespaces),
                            taskDescription: description.trimmingCharacters(in: .whitespaces),
                            minutesEarned: minutes
                        )
                        manager.earnTasks.append(task)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

#Preview {
    EarnView()
        .environmentObject(BlockingManager())
}
