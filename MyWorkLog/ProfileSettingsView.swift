import SwiftUI

struct ProfileSettingsView: View {
    @Bindable var store: TaskStore
    @State private var showingResetAlert = false
    @State private var showingLoadSamplesAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Intern Information") {
                    TextField("Full Name", text: $store.profile.internName)
                    TextField("Email Address", text: $store.profile.internEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                
                Section("Internship Period") {
                    DatePicker("Start Date", selection: $store.profile.startDate, displayedComponents: [.date])
                    DatePicker("End Date", selection: $store.profile.endDate, displayedComponents: [.date])
                }
                
                Section("Data Management") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Reset All Data (Clear to 0)")
                        }
                    }
                    
                    Button {
                        showingLoadSamplesAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restore Sample Tasks")
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("InternTrack AI")
                            .font(.caption.bold())
                        Text("Minimal & classic work log and report tracker.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Profile & Settings")
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear to 0", role: .destructive) {
                    store.resetAllData()
                }
            } message: {
                Text("All tasks and work logs will be cleared. All dashboard counters will reset to 0.")
            }
            .alert("Restore Sample Data?", isPresented: $showingLoadSamplesAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Restore") {
                    store.restoreSampleData()
                }
            } message: {
                Text("This will load demo tasks into your workspace.")
            }
        }
    }
}
