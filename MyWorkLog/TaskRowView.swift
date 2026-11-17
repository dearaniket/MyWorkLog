import SwiftUI

struct TaskRowView: View {
    let task: InternTask
    var onToggleStatus: () -> Void
    
    private var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: task.deadline)
    }
    
    private var isOverdue: Bool {
        task.status != .completed && task.deadline < Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggleStatus) {
                Image(systemName: task.status.iconName)
                    .font(.title3)
                    .foregroundColor(task.status.color)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.status == .completed, color: .secondary)
                        .foregroundColor(task.status == .completed ? .secondary : .primary)
                    
                    Spacer()
                    
                    // Priority Pill
                    Text(task.priority.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(task.priority.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.priority.color.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    // Category Tag
                    Label(task.category.rawValue, systemImage: task.category.iconName)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                    
                    // Platform Tag
                    Label(task.platform.rawValue, systemImage: task.platform.iconName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Deadline
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formattedDeadline)
                            .font(.caption2)
                    }
                    .foregroundColor(isOverdue ? .red : .secondary)
                }
                
                HStack {
                    Text("By: \(task.assignedBy)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !task.deliverableNotes.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Deliverable: \(task.deliverableNotes)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
