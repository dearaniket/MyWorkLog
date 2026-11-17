import UIKit
import PDFKit

struct PDFReportGenerator {
    static func generateReportPDF(
        profile: UserProfile,
        tasks: [InternTask],
        startDate: Date?,
        endDate: Date?
    ) -> Data {
        let pageWidth: CGFloat = 612 // Standard US Letter width
        let pageHeight: CGFloat = 792 // Standard US Letter height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let filteredTasks = tasks.filter { task in
            guard let compDate = task.completionDate else { return false }
            if let start = startDate, compDate < Calendar.current.startOfDay(for: start) {
                return false
            }
            if let end = endDate, compDate > Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end {
                return false
            }
            return true
        }.sorted { ($0.completionDate ?? Date()) < ($1.completionDate ?? Date()) }
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var cursorY: CGFloat = 36
            let margin: CGFloat = 40
            let contentWidth = pageWidth - (margin * 2)
            
            // Header Title
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let subtitleFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
            let bodyFont = UIFont.systemFont(ofSize: 9)
            let boldBodyFont = UIFont.boldSystemFont(ofSize: 9)
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.systemBlue
            ]
            
            "INTERNTRACK AI — OFFICIAL WORK LOG REPORT".draw(
                at: CGPoint(x: margin, y: cursorY),
                withAttributes: titleAttributes
            )
            cursorY += 24
            
            "VERIFIED JOB REPORT & INTERNSHIP PERFORMANCE RECORD".draw(
                at: CGPoint(x: margin, y: cursorY),
                withAttributes: subtitleAttributes
            )
            cursorY += 18
            
            // Divider
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: cursorY))
            path.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY))
            path.lineWidth = 1.5
            UIColor.systemGray3.setStroke()
            path.stroke()
            cursorY += 12
            
            // Intern Details Box
            let boxRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: 74)
            let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 4)
            UIColor.systemGray6.setFill()
            boxPath.fill()
            UIColor.systemGray4.setStroke()
            boxPath.lineWidth = 0.5
            boxPath.stroke()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateRangeString = "\(dateFormatter.string(from: profile.startDate)) – \(dateFormatter.string(from: profile.endDate))"
            
            let leftDetails = """
            Intern Name: \(profile.internName)
            Email: \(profile.internEmail)
            University: \(profile.university)
            """
            
            let rightDetails = """
            Organization: \(profile.organization)
            Department: \(profile.department)
            Supervisor: \(profile.supervisorName)
            Period: \(dateRangeString)
            """
            
            let boxTextAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            leftDetails.draw(
                in: CGRect(x: margin + 10, y: cursorY + 8, width: (contentWidth / 2) - 15, height: 60),
                withAttributes: boxTextAttributes
            )
            
            rightDetails.draw(
                in: CGRect(x: margin + (contentWidth / 2) + 5, y: cursorY + 8, width: (contentWidth / 2) - 15, height: 60),
                withAttributes: boxTextAttributes
            )
            
            cursorY += 86
            
            // Metrics Summary Bar
            let metricsTitle = "SUMMARY METRICS (PERIOD: \(startDate != nil ? dateFormatter.string(from: startDate!) : "Start") to \(endDate != nil ? dateFormatter.string(from: endDate!) : "Present"))"
            metricsTitle.draw(
                at: CGPoint(x: margin, y: cursorY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 11),
                    .foregroundColor: UIColor.black
                ]
            )
            cursorY += 16
            
            let totalTasks = tasks.count
            let completedCount = filteredTasks.count
            let rate = totalTasks > 0 ? Int((Double(completedCount) / Double(totalTasks)) * 100) : 0
            
            let metricsText = "Total Tasks in System: \(totalTasks)   |   Completed Tasks in Scope: \(completedCount)   |   Period Productivity: \(rate)%"
            metricsText.draw(
                at: CGPoint(x: margin, y: cursorY),
                withAttributes: [
                    .font: boldBodyFont,
                    .foregroundColor: UIColor.systemIndigo
                ]
            )
            cursorY += 18
            
            // Work Log Table Header
            let tableHeaderY = cursorY
            let tableHeaderRect = CGRect(x: margin, y: tableHeaderY, width: contentWidth, height: 20)
            UIColor.systemBlue.withAlphaComponent(0.12).setFill()
            UIBezierPath(rect: tableHeaderRect).fill()
            
            let col1X = margin + 4
            let col2X = margin + 80
            let col3X = margin + 260
            let col4X = margin + 370
            
            let tableHeaderAttrs: [NSAttributedString.Key: Any] = [
                .font: boldBodyFont,
                .foregroundColor: UIColor.black
            ]
            
            "Date".draw(at: CGPoint(x: col1X, y: tableHeaderY + 4), withAttributes: tableHeaderAttrs)
            "Task & Deliverable Summary".draw(at: CGPoint(x: col2X, y: tableHeaderY + 4), withAttributes: tableHeaderAttrs)
            "Category / Priority".draw(at: CGPoint(x: col3X, y: tableHeaderY + 4), withAttributes: tableHeaderAttrs)
            "Assigned By & Platform".draw(at: CGPoint(x: col4X, y: tableHeaderY + 4), withAttributes: tableHeaderAttrs)
            
            cursorY += 24
            
            // Table Rows
            if filteredTasks.isEmpty {
                "No completed tasks found in the selected date range.".draw(
                    at: CGPoint(x: margin + 10, y: cursorY + 10),
                    withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                )
                cursorY += 40
            } else {
                for (index, task) in filteredTasks.prefix(8).enumerated() {
                    let rowHeight: CGFloat = 38
                    let rowRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: rowHeight)
                    
                    if index % 2 == 1 {
                        UIColor.systemGray6.withAlphaComponent(0.5).setFill()
                        UIBezierPath(rect: rowRect).fill()
                    }
                    
                    let taskDateStr = task.completionDate != nil ? dateFormatter.string(from: task.completionDate!) : "—"
                    taskDateStr.draw(at: CGPoint(x: col1X, y: cursorY + 4), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    
                    let titleText = "\(task.title)\nDeliverable: \(task.deliverableNotes.isEmpty ? "Complete" : task.deliverableNotes)"
                    titleText.draw(in: CGRect(x: col2X, y: cursorY + 2, width: 170, height: 34), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.black
                    ])
                    
                    let catPrio = "\(task.category.rawValue)\nPriority: \(task.priority.rawValue)"
                    catPrio.draw(in: CGRect(x: col3X, y: cursorY + 2, width: 100, height: 34), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    
                    let assigner = "\(task.assignedBy)\nvia \(task.platform.rawValue)"
                    assigner.draw(in: CGRect(x: col4X, y: cursorY + 2, width: 150, height: 34), withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.darkGray
                    ])
                    
                    cursorY += rowHeight
                    
                    // Row separator
                    let rowLine = UIBezierPath()
                    rowLine.move(to: CGPoint(x: margin, y: cursorY))
                    rowLine.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY))
                    rowLine.lineWidth = 0.5
                    UIColor.systemGray5.setStroke()
                    rowLine.stroke()
                }
            }
            
            cursorY = max(cursorY + 16, pageHeight - 160)
            
            // Sign-off / Verification section
            let signDivider = UIBezierPath()
            signDivider.move(to: CGPoint(x: margin, y: cursorY))
            signDivider.addLine(to: CGPoint(x: margin + contentWidth, y: cursorY))
            signDivider.lineWidth = 1
            UIColor.systemGray4.setStroke()
            signDivider.stroke()
            cursorY += 12
            
            "SUPERVISOR VERIFICATION & SIGN-OFF".draw(
                at: CGPoint(x: margin, y: cursorY),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
            )
            cursorY += 14
            
            "I hereby certify that the work log deliverables recorded above have been reviewed, verified, and approved according to department standards.".draw(
                in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 26),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.gray
                ]
            )
            cursorY += 32
            
            let signWidth: CGFloat = 200
            
            // Supervisor signature line
            let sigLine1 = UIBezierPath()
            sigLine1.move(to: CGPoint(x: margin, y: cursorY))
            sigLine1.addLine(to: CGPoint(x: margin + signWidth, y: cursorY))
            sigLine1.lineWidth = 1
            UIColor.darkGray.setStroke()
            sigLine1.stroke()
            
            "Supervisor Signature (\(profile.supervisorName))".draw(
                at: CGPoint(x: margin, y: cursorY + 4),
                withAttributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            )
            
            // Date line
            let sigLine2 = UIBezierPath()
            let dateLineX = margin + contentWidth - 160
            sigLine2.move(to: CGPoint(x: dateLineX, y: cursorY))
            sigLine2.addLine(to: CGPoint(x: dateLineX + 160, y: cursorY))
            sigLine2.lineWidth = 1
            UIColor.darkGray.setStroke()
            sigLine2.stroke()
            
            "Date of Review".draw(
                at: CGPoint(x: dateLineX, y: cursorY + 4),
                withAttributes: [.font: bodyFont, .foregroundColor: UIColor.darkGray]
            )
            
            cursorY += 24
            
            // Footer branding
            let footerText = "Generated via InternTrack AI Official Work Log System • Certified Copy"
            footerText.draw(
                at: CGPoint(x: margin, y: pageHeight - 24),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8),
                    .foregroundColor: UIColor.lightGray
                ]
            )
        }
        
        return data
    }
}
