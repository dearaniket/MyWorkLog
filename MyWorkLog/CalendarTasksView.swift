import SwiftUI

struct CalendarTasksView: View {
    @Bindable var store: TaskStore
    @State private var selectedDate: Date = Date()
    @State private var showingAddTask = false
    @State private var taskToEdit: InternTask? = nil
    
    private var tasksForSelectedDate: [InternTask] {
        let calendar = Calendar.current
        return store.tasks.filter { task in
            let isSameDeadline = calendar.isDate(task.deadline, inSameDayAs: selectedDate)
            let isSameAssigned = calendar.isDate(task.assignedDate, inSameDayAs: selectedDate)
            let isSameCompletion = task.completionDate != nil && calendar.isDate(task.completionDate!, inSameDayAs: selectedDate)
            return isSameDeadline || isSameAssigned || isSameCompletion
        }
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Graphical Calendar
                    DatePicker(
                        "Calendar",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Selected Day Agenda Header
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Day Milestones")
                                    .font(.headline)
                                Text(formattedSelectedDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                showingAddTask = true
                            } label: {
                                Label("Add for Day", systemImage: "plus")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        if tasksForSelectedDate.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                Text("No tasks or deadlines scheduled for this day.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(tasksForSelectedDate) { task in
                                    TaskRowView(task: task) {
                                        store.toggleStatus(for: task)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        taskToEdit = task
                                    }
                                    
                                    if task.id != tasksForSelectedDate.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar & Milestones")
            .sheet(isPresented: $showingAddTask) {
                TaskEditorSheet(onSave: { title, desc, assignedBy, plat, cat, prio, stat, _, _, notes in
                    store.addTask(
                        title: title,
                        description: desc,
                        assignedBy: assignedBy,
                        platform: plat,
                        category: cat,
                        priority: prio,
                        status: stat,
                        assignedDate: selectedDate,
                        deadline: selectedDate,
                        deliverableNotes: notes
                    )
                })
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditorSheet(taskToEdit: task) { title, desc, assignedBy, plat, cat, prio, stat, assignedDate, deadline, notes in
                    var updated = task
                    updated.title = title
                    updated.taskDescription = desc
                    updated.assignedBy = assignedBy
                    updated.platform = plat
                    updated.category = cat
                    updated.priority = prio
                    updated.status = stat
                    updated.assignedDate = assignedDate
                    updated.deadline = deadline
                    updated.deliverableNotes = notes
                    store.updateTask(updated)
                }
            }
        }
    }
}
