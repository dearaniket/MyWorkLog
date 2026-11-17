import Foundation
import SwiftUI
import Observation

@Observable
final class TaskStore {
    var tasks: [InternTask] = [] {
        didSet {
            saveTasks()
        }
    }
    
    var profile: UserProfile = .default {
        didSet {
            saveProfile()
        }
    }
    
    var activityLogs: [ActivityLogItem] = [] {
        didSet {
            saveLogs()
        }
    }
    
    private let tasksKey = "interntrack_tasks_storage_v2"
    private let profileKey = "interntrack_profile_storage_v2"
    private let logsKey = "interntrack_logs_storage_v2"
    private let hasInitializedKey = "interntrack_has_initialized_v2"
    
    init() {
        loadData()
    }
    
    // MARK: - Metrics
    
    var totalTasksCount: Int {
        tasks.count
    }
    
    var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    var inProgressTasksCount: Int {
        tasks.filter { $0.status == .inProgress }.count
    }
    
    var pendingTasksCount: Int {
        tasks.filter { $0.status == .pending }.count
    }
    
    var completionRate: Double {
        guard totalTasksCount > 0 else { return 0.0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    func count(for category: TaskCategory) -> Int {
        tasks.filter { $0.category == category }.count
    }
    
    func count(for priority: TaskPriority) -> Int {
        tasks.filter { $0.priority == priority }.count
    }
    
    // MARK: - CRUD Operations
    
    func addTask(
        title: String,
        description: String,
        assignedBy: String,
        platform: TaskPlatform,
        category: TaskCategory,
        priority: TaskPriority,
        status: TaskStatus,
        assignedDate: Date,
        deadline: Date,
        deliverableNotes: String
    ) {
        let completionDate = (status == .completed) ? Date() : nil
        let newTask = InternTask(
            title: title,
            taskDescription: description,
            assignedBy: assignedBy,
            platform: platform,
            category: category,
            priority: priority,
            status: status,
            assignedDate: assignedDate,
            deadline: deadline,
            completionDate: completionDate,
            deliverableNotes: deliverableNotes
        )
        tasks.insert(newTask, at: 0)
        logActivity(action: "Logged new task", taskTitle: title)
    }
    
    func updateTask(_ task: InternTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = task
            if updated.status == .completed && tasks[index].status != .completed {
                updated.completionDate = Date()
                logActivity(action: "Completed task", taskTitle: updated.title)
            } else if updated.status != .completed {
                updated.completionDate = nil
                logActivity(action: "Updated task", taskTitle: updated.title)
            } else {
                logActivity(action: "Updated task", taskTitle: updated.title)
            }
            tasks[index] = updated
        }
    }
    
    func deleteTask(withId id: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            let title = tasks[index].title
            tasks.remove(at: index)
            logActivity(action: "Deleted task", taskTitle: title)
        }
    }
    
    func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let title = tasks[index].title
            logActivity(action: "Deleted task", taskTitle: title)
        }
        tasks.remove(atOffsets: offsets)
    }
    
    func toggleStatus(for task: InternTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updated = tasks[index]
            switch updated.status {
            case .pending:
                updated.status = .inProgress
                updated.completionDate = nil
                logActivity(action: "In Progress", taskTitle: updated.title)
            case .inProgress:
                updated.status = .completed
                updated.completionDate = Date()
                logActivity(action: "Completed", taskTitle: updated.title)
            case .completed:
                updated.status = .pending
                updated.completionDate = nil
                logActivity(action: "Reopened", taskTitle: updated.title)
            }
            tasks[index] = updated
        }
    }
    
    func logActivity(action: String, taskTitle: String) {
        let log = ActivityLogItem(actionText: action, taskTitle: taskTitle)
        activityLogs.insert(log, at: 0)
        if activityLogs.count > 40 {
            activityLogs.removeLast()
        }
    }
    
    // MARK: - Persistence & Reset
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    private func saveLogs() {
        if let encoded = try? JSONEncoder().encode(activityLogs) {
            UserDefaults.standard.set(encoded, forKey: logsKey)
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let decodedProfile = try? decoder.decode(UserProfile.self, from: profileData) {
            self.profile = decodedProfile
        } else {
            self.profile = .default
        }
        
        let hasInitialized = UserDefaults.standard.bool(forKey: hasInitializedKey)
        
        if hasInitialized {
            if let tasksData = UserDefaults.standard.data(forKey: tasksKey),
               let decodedTasks = try? decoder.decode([InternTask].self, from: tasksData) {
                self.tasks = decodedTasks
            } else {
                self.tasks = []
            }
            
            if let logsData = UserDefaults.standard.data(forKey: logsKey),
               let decodedLogs = try? decoder.decode([ActivityLogItem].self, from: logsData) {
                self.activityLogs = decodedLogs
            } else {
                self.activityLogs = []
            }
        } else {
            // First run initial setup
            UserDefaults.standard.set(true, forKey: hasInitializedKey)
            self.tasks = TaskStore.createSampleTasks()
            self.activityLogs = [
                ActivityLogItem(actionText: "Welcome to InternTrack", taskTitle: "System Ready")
            ]
            saveTasks()
            saveLogs()
        }
    }
    
    /// Clears all tasks and logs so everything resets to 0
    func resetAllData() {
        tasks = []
        activityLogs = []
        UserDefaults.standard.set(true, forKey: hasInitializedKey)
        if let emptyTasks = try? JSONEncoder().encode([InternTask]()) {
            UserDefaults.standard.set(emptyTasks, forKey: tasksKey)
        }
        if let emptyLogs = try? JSONEncoder().encode([ActivityLogItem]()) {
            UserDefaults.standard.set(emptyLogs, forKey: logsKey)
        }
    }
    
    func restoreSampleData() {
        self.tasks = TaskStore.createSampleTasks()
        self.activityLogs = [
            ActivityLogItem(actionText: "Loaded sample tasks", taskTitle: "Demo Workspace")
        ]
        saveTasks()
        saveLogs()
    }
    
    static func createSampleTasks() -> [InternTask] {
        let calendar = Calendar.current
        let today = Date()
        
        let dateMinus4 = calendar.date(byAdding: .day, value: -4, to: today) ?? today
        let dateMinus2 = calendar.date(byAdding: .day, value: -2, to: today) ?? today
        let dateMinus1 = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let datePlus2 = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        let datePlus5 = calendar.date(byAdding: .day, value: 5, to: today) ?? today
        
        return [
            InternTask(
                title: "Prepare Monthly Review PPT Deck",
                taskDescription: "Compile department metrics, progress highlights, and upcoming milestones into presentation slides.",
                assignedBy: "Supervisor",
                platform: .email,
                category: .documentationPPT,
                priority: .high,
                status: .completed,
                assignedDate: dateMinus4,
                deadline: dateMinus2,
                completionDate: dateMinus2,
                deliverableNotes: "Slides exported to PDF and sent via email."
            ),
            InternTask(
                title: "Event Social Media Banner Design",
                taskDescription: "Design promotion banners and story assets for campus tech talk.",
                assignedBy: "Marketing Team",
                platform: .instagram,
                category: .bannerDesign,
                priority: .medium,
                status: .completed,
                assignedDate: dateMinus2,
                deadline: dateMinus1,
                completionDate: dateMinus1,
                deliverableNotes: "Delivered 1080x1080 and 1080x1920 PNG assets."
            ),
            InternTask(
                title: "Update Project Documentation Handout",
                taskDescription: "Review process guidelines and add updated FAQ section.",
                assignedBy: "Team Lead",
                platform: .whatsapp,
                category: .documentationPPT,
                priority: .low,
                status: .inProgress,
                assignedDate: today,
                deadline: datePlus2,
                completionDate: nil,
                deliverableNotes: "Draft in progress."
            ),
            InternTask(
                title: "Quarterly Campaign Banner Revisions",
                taskDescription: "Make typography and logo sizing adjustments based on feedback.",
                assignedBy: "Creative Lead",
                platform: .whatsapp,
                category: .bannerDesign,
                priority: .high,
                status: .pending,
                assignedDate: today,
                deadline: datePlus5,
                completionDate: nil,
                deliverableNotes: "Awaiting final copy."
            )
        ]
    }
}
