import SwiftUI

struct TaskListView: View {
    @Bindable var store: TaskStore
    
    @State private var searchText = ""
    @State private var selectedStatusFilter: TaskStatusFilter = .all
    @State private var selectedCategory: TaskCategory? = nil
    @State private var selectedPriority: TaskPriority? = nil
    
    @State private var showingAddTask = false
    @State private var taskToEdit: InternTask? = nil
    
    enum TaskStatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case inProgress = "Active"
        case completed = "Completed"
        
        var id: String { rawValue }
    }
    
    var filteredTasks: [InternTask] {
        store.tasks.filter { task in
            // Search filter
            if !searchText.isEmpty {
                let lower = searchText.lowercased()
                let matchTitle = task.title.lowercased().contains(lower)
                let matchDesc = task.taskDescription.lowercased().contains(lower)
                let matchAssigned = task.assignedBy.lowercased().contains(lower)
                let matchDeliverable = task.deliverableNotes.lowercased().contains(lower)
                if !(matchTitle || matchDesc || matchAssigned || matchDeliverable) {
                    return false
                }
            }
            
            // Status filter
            switch selectedStatusFilter {
            case .all:
                break
            case .pending:
                if task.status != .pending { return false }
            case .inProgress:
                if task.status != .inProgress { return false }
            case .completed:
                if task.status != .completed { return false }
            }
            
            // Category filter
            if let cat = selectedCategory, task.category != cat {
                return false
            }
            
            // Priority filter
            if let prio = selectedPriority, task.priority != prio {
                return false
            }
            
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Segmented Filter
                Picker("Status", selection: $selectedStatusFilter) {
                    ForEach(TaskStatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 6)
                
                // Active Category/Priority Filter Badges
                HStack {
                    Menu {
                        Button("All Categories") {
                            selectedCategory = nil
                        }
                        Divider()
                        ForEach(TaskCategory.allCases) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Label(cat.rawValue, systemImage: cat.iconName)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCategory?.rawValue ?? "Category: All")
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedCategory != nil ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .foregroundColor(selectedCategory != nil ? Color.accentColor : .primary)
                        .cornerRadius(8)
                    }
                    
                    Menu {
                        Button("All Priorities") {
                            selectedPriority = nil
                        }
                        Divider()
                        ForEach(TaskPriority.allCases) { prio in
                            Button(prio.rawValue) {
                                selectedPriority = prio
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedPriority?.rawValue ?? "Priority: All")
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedPriority != nil ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .foregroundColor(selectedPriority != nil ? Color.accentColor : .primary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    if selectedCategory != nil || selectedPriority != nil {
                        Button("Reset") {
                            selectedCategory = nil
                            selectedPriority = nil
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Task List
                if filteredTasks.isEmpty {
                    ContentUnavailableView {
                        Label("No Tasks Found", systemImage: "tray")
                    } description: {
                        Text("No tasks match your current search and filters.")
                    } actions: {
                        Button("Add New Task") {
                            showingAddTask = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task) {
                                store.toggleStatus(for: task)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.deleteTask(withId: task.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.toggleStatus(for: task)
                                } label: {
                                    Label("Cycle Status", systemImage: "arrow.triangle.2.circlepath")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Work Logs")
            .searchable(text: $searchText, prompt: "Search tasks, assigners, deliverables")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskEditorSheet { title, desc, assignedBy, plat, cat, prio, stat, assignedDate, deadline, notes in
                    store.addTask(
                        title: title,
                        description: desc,
                        assignedBy: assignedBy,
                        platform: plat,
                        category: cat,
                        priority: prio,
                        status: stat,
                        assignedDate: assignedDate,
                        deadline: deadline,
                        deliverableNotes: notes
                    )
                }
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
