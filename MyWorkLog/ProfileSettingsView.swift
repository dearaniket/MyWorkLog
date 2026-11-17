import SwiftUI

struct ProfileSettingsView: View {
    @Bindable var store: TaskStore
    @State private var showingResetAlert = false
    @State private var showingLoadSamplesAlert = false
    
    // Edit state for Intern Information
    @State private var isEditingInfo: Bool = false
    @State private var tempName: String = ""
    @State private var tempEmail: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isEditingInfo {
                        TextField("Full Name", text: $tempName)
                        TextField("Email Address", text: $tempEmail)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        HStack(spacing: 12) {
                            Button("Cancel", role: .cancel) {
                                cancelEditing()
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Save") {
                                saveEditing()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Text("Full Name")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(store.profile.internName.isEmpty ? "Not set" : store.profile.internName)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Email Address")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(store.profile.internEmail.isEmpty ? "Not set" : store.profile.internEmail)
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    HStack {
                        Text("Intern Information")
                        Spacer()
                        if !isEditingInfo {
                            Button("Edit") {
                                startEditing()
                            }
                            .font(.caption.weight(.semibold))
                            .textCase(nil)
                        }
                    }
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
    
    private func startEditing() {
        tempName = store.profile.internName
        tempEmail = store.profile.internEmail
        isEditingInfo = true
    }
    
    private func saveEditing() {
        store.profile.internName = tempName
        store.profile.internEmail = tempEmail
        isEditingInfo = false
    }
    
    private func cancelEditing() {
        isEditingInfo = false
    }
}
