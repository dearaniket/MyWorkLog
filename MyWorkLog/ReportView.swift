import SwiftUI
import QuickLook

struct ReportView: View {
    @Bindable var store: TaskStore
    
    enum DateScope: String, CaseIterable, Identifiable {
        case thisMonth = "This Month"
        case past7Days = "Past 7 Days"
        case allTime = "All Time"
        case custom = "Custom Range"
        
        var id: String { rawValue }
    }
    
    @State private var selectedScope: DateScope = .thisMonth
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEndDate: Date = Date()
    
    @State private var generatedPDFData: Data? = nil
    @State private var tempPDFURL: URL? = nil
    @State private var showingShareSheet = false
    
    private var effectiveDateRange: (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedScope {
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let start = calendar.date(from: components)
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: start ?? now)
            let end = calendar.date(byAdding: .second, value: -1, to: nextMonth ?? now)
            return (start, end)
        case .past7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now)
            return (start, now)
        case .allTime:
            return (nil, nil)
        case .custom:
            return (customStartDate, customEndDate)
        }
    }
    
    private var scopedCompletedTasks: [InternTask] {
        let range = effectiveDateRange
        return store.tasks.filter { task in
            guard let compDate = task.completionDate else { return false }
            if let start = range.start, compDate < Calendar.current.startOfDay(for: start) {
                return false
            }
            if let end = range.end, compDate > Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end {
                return false
            }
            return true
        }.sorted { ($0.completionDate ?? Date()) < ($1.completionDate ?? Date()) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Filter & Export Controls Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Scope & Filter")
                            .font(.headline)
                        
                        Picker("Report Scope", selection: $selectedScope) {
                            ForEach(DateScope.allCases) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedScope == .custom {
                            HStack {
                                DatePicker("From", selection: $customStartDate, displayedComponents: [.date])
                                DatePicker("To", selection: $customEndDate, displayedComponents: [.date])
                            }
                            .padding(.top, 4)
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // 1-Click Export Button
                        Button {
                            generateAndSharePDF()
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "doc.text.fill")
                                Text("Export Official PDF Report")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Formatted Report Document Preview
                    VStack(alignment: .leading, spacing: 0) {
                        // Document Sheet Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("INTERNTRACK AI")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                    Text("Official Work Log Report")
                                        .font(.title3.bold())
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("STATUS: VERIFIED")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                    Text("Generated: \(Date(), style: .date)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Intern & Institution Details Grid
                            VStack(alignment: .leading, spacing: 6) {
                                LabeledReportRow(label: "Intern Name", value: store.profile.internName)
                                LabeledReportRow(label: "University", value: store.profile.university)
                                LabeledReportRow(label: "Host Organization", value: store.profile.organization)
                                LabeledReportRow(label: "Department", value: store.profile.department)
                                LabeledReportRow(label: "Supervisor", value: store.profile.supervisorName)
                                LabeledReportRow(label: "Evaluation Scope", value: selectedScope.rawValue)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            // Summary Metrics Table
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Productivity Summary")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    ReportMetricBox(title: "Completed in Scope", value: "\(scopedCompletedTasks.count)")
                                    ReportMetricBox(title: "Total System Tasks", value: "\(store.totalTasksCount)")
                                    let rate = store.totalTasksCount > 0 ? Int((Double(scopedCompletedTasks.count) / Double(store.totalTasksCount)) * 100) : 0
                                    ReportMetricBox(title: "Scope Productivity", value: "\(rate)%")
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Chronological Completed Tasks List
                            Text("Chronological Work Logs")
                                .font(.headline)
                            
                            if scopedCompletedTasks.isEmpty {
                                Text("No tasks completed in this time range.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(scopedCompletedTasks) { task in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(task.title)
                                                    .font(.subheadline.bold())
                                                Spacer()
                                                if let compDate = task.completionDate {
                                                    Text(compDate, style: .date)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            HStack(spacing: 6) {
                                                Text(task.category.rawValue)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color(.systemGray5))
                                                    .cornerRadius(4)
                                                
                                                Text("Assigned by: \(task.assignedBy)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                
                                                Text("via \(task.platform.rawValue)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if !task.deliverableNotes.isEmpty {
                                                Text("Deliverable: \(task.deliverableNotes)")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                                        )
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 6)
                            
                            // Supervisor Sign-off Line Block
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Supervisor Approval & Verification")
                                    .font(.subheadline.bold())
                                
                                Text("I verify that the logged activities and deliverables above accurately reflect work performed by the intern.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1)
                                            .padding(.top, 24)
                                        Text("Supervisor Signature (\(store.profile.supervisorName))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1)
                                            .padding(.top, 24)
                                        Text("Date")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 100)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Formal Work Report")
            .sheet(isPresented: $showingShareSheet) {
                if let url = tempPDFURL {
                    ShareSheetView(activityItems: [url])
                }
            }
        }
    }
    
    private func generateAndSharePDF() {
        let range = effectiveDateRange
        let pdfData = PDFReportGenerator.generateReportPDF(
            profile: store.profile,
            tasks: store.tasks,
            startDate: range.start,
            endDate: range.end
        )
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("InternTrack_Report_\(store.profile.internName.replacingOccurrences(of: " ", with: "_")).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            self.tempPDFURL = tempURL
            self.generatedPDFData = pdfData
            self.showingShareSheet = true
            store.logActivity(action: "Exported Official PDF Report", taskTitle: "Work Report")
        } catch {
            print("Failed to write PDF: \(error)")
        }
    }
}

private struct LabeledReportRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

private struct ReportMetricBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
