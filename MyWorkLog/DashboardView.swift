import SwiftUI

struct DashboardView: View {
    @Bindable var store: TaskStore
    @State private var showingAddTask = false
    @State private var expandedPriority: TaskPriority? = nil
    @State private var taskToEdit: InternTask? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.profile.internName.isEmpty ? "Intern Track" : store.profile.internName)
                                .font(.headline)
                            if !store.profile.internEmail.isEmpty {
                                Text(store.profile.internEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            showingAddTask = true
                        } label: {
                            Label("New Task", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Metric Summary Grid (4 Minimal Cards)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MinimalMetricCard(title: "Total Tasks", count: store.totalTasksCount, color: .primary)
                        MinimalMetricCard(title: "Completed", count: store.completedTasksCount, color: .green)
                        MinimalMetricCard(title: "In Progress", count: store.inProgressTasksCount, color: .blue)
                        MinimalMetricCard(title: "Pending", count: store.pendingTasksCount, color: .orange)
                    }
                    
                    // Priority Distribution (Expandable)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Tasks by Priority")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if expandedPriority != nil {
                                Button("Collapse") {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expandedPriority = nil
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        // Priority Selection Buttons
                        HStack(spacing: 10) {
                            ForEach(TaskPriority.allCases) { priority in
                                let count = store.count(for: priority)
                                let isSelected = expandedPriority == priority
                                
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        if expandedPriority == priority {
                                            expandedPriority = nil
                                        } else {
                                            expandedPriority = priority
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(priority.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(count)")
                                            .font(.title3.bold())
                                            .foregroundColor(priority.color)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? priority.color.opacity(0.18) : Color(.systemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? priority.color : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Expanded Task List for selected priority
                        if let selectedPriority = expandedPriority {
                            let priorityTasks = store.tasks.filter { $0.priority == selectedPriority }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                HStack {
                                    Text("\(selectedPriority.rawValue) Priority Tasks (\(priorityTasks.count))")
                                        .font(.caption.bold())
                                        .foregroundColor(selectedPriority.color)
                                    Spacer()
                                }
                                
                                if priorityTasks.isEmpty {
                                    Text("No tasks found for \(selectedPriority.rawValue) priority.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 6)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(priorityTasks) { task in
                                            TaskRowView(task: task) {
                                                store.toggleStatus(for: task)
                                            }
                                            .padding(8)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(8)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                taskToEdit = task
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Updates")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        
                        if store.activityLogs.isEmpty {
                            Text("No recent activity recorded.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 6)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(store.activityLogs.prefix(4)) { log in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(log.actionText)
                                                .font(.caption.weight(.medium))
                                            Text(log.taskTitle)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(log.timestamp, style: .time)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    if log.id != store.activityLogs.prefix(4).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
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

private struct MinimalMetricCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
