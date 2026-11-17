import SwiftUI

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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Scope Picker Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Report Scope")
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
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Export Button (No action on click)
                Button {
                    // No action performed on click as requested
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "doc.text.fill")
                        Text("Export Official PDF Report")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("Report")
        }
    }
}
