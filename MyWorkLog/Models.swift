import Foundation
import SwiftUI
import Observation

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "clock.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable, Identifiable {
    case documentationPPT = "Documentation / PPT"
    case bannerDesign = "Banner Design"
    case others = "Others"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .documentationPPT: return "doc.richtext"
        case .bannerDesign: return "photo.artframe"
        case .others: return "ellipsis.circle"
        }
    }
}

enum TaskPlatform: String, CaseIterable, Codable, Identifiable {
    case whatsapp = "WhatsApp"
    case instagram = "Instagram"
    case email = "Email"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .whatsapp: return "message.fill"
        case .instagram: return "camera.fill"
        case .email: return "envelope.fill"
        case .other: return "link"
        }
    }
}

struct InternTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var taskDescription: String
    var assignedBy: String
    var platform: TaskPlatform
    var category: TaskCategory
    var priority: TaskPriority
    var status: TaskStatus
    var assignedDate: Date
    var deadline: Date
    var activeDate: Date? = nil
    var completionDate: Date? = nil
    var deliverableNotes: String
    var attachmentName: String?
    
    /// Number of days taken to complete the task from activeDate (or assignedDate if activeDate is nil)
    var completionDurationInDays: Int? {
        guard let completed = completionDate else { return nil }
        let start = activeDate ?? assignedDate
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: completed)
        let diff = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
        return max(1, diff)
    }
}

struct UserProfile: Codable, Equatable {
    var internName: String
    var internEmail: String
    var organization: String
    var university: String
    var department: String
    var supervisorName: String
    var supervisorEmail: String
    var startDate: Date
    var endDate: Date
    
    static var `default`: UserProfile {
        UserProfile(
            internName: "Alex Rivera",
            internEmail: "alex.rivera@university.edu",
            organization: "Acme Innovations Inc.",
            university: "State University",
            department: "Marketing & Tech Operations",
            supervisorName: "Dr. Evelyn Reed",
            supervisorEmail: "evelyn.reed@acmeinnovations.com",
            startDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        )
    }
}

struct ActivityLogItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var actionText: String
    var taskTitle: String
}
