import SwiftUI

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var taskToEdit: InternTask?
    var onSave: (String, String, String, TaskPlatform, TaskCategory, TaskPriority, TaskStatus, Date, Date, String) -> Void
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var assignedBy: String = ""
    @State private var platform: TaskPlatform = .whatsapp
    @State private var category: TaskCategory = .documentationPPT
    @State private var priority: TaskPriority = .medium
    @State private var status: TaskStatus = .pending
    @State private var assignedDate: Date = Date()
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var deliverableNotes: String = ""
    
    var isEditing: Bool {
        taskToEdit != nil
    }
    
    init(
        taskToEdit: InternTask? = nil,
        onSave: @escaping (String, String, String, TaskPlatform, TaskCategory, TaskPriority, TaskStatus, Date, Date, String) -> Void
    ) {
        self.taskToEdit = taskToEdit
        self.onSave = onSave
        
        if let existing = taskToEdit {
            _title = State(initialValue: existing.title)
            _taskDescription = State(initialValue: existing.taskDescription)
            _assignedBy = State(initialValue: existing.assignedBy)
            _platform = State(initialValue: existing.platform)
            _category = State(initialValue: existing.category)
            _priority = State(initialValue: existing.priority)
            _status = State(initialValue: existing.status)
            _assignedDate = State(initialValue: existing.assignedDate)
            _deadline = State(initialValue: existing.deadline)
            _deliverableNotes = State(initialValue: existing.deliverableNotes)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    TextField("Assigned By", text: $assignedBy)
                    
                    Picker("Platform", selection: $platform) {
                        ForEach(TaskPlatform.allCases) { plat in
                            Label(plat.rawValue, systemImage: plat.iconName).tag(plat)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases) { prio in
                                Text(prio.rawValue).tag(prio)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 2)
                    
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                }
                
                Section("Timeline") {
                    DatePicker("Assigned Date", selection: $assignedDate, displayedComponents: [.date])
                    DatePicker("Deadline", selection: $deadline, displayedComponents: [.date])
                }
                
                Section("Description") {
                    TextField("Optional notes or instructions", text: $taskDescription, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Deliverable / Link / Notes") {
                    TextField("e.g. PPT file sent, Banner link, Approval status", text: $deliverableNotes, axis: .vertical)
                        .lineLimit(2...3)
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Task" : title,
                            taskDescription,
                            assignedBy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Supervisor" : assignedBy,
                            platform,
                            category,
                            priority,
                            status,
                            assignedDate,
                            deadline,
                            deliverableNotes
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
