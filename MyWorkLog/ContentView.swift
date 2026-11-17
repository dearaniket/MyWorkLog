import SwiftUI

struct ContentView: View {
    @State private var store = TaskStore()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(store: store)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .tag(0)
            
            TaskListView(store: store)
                .tabItem {
                    Label("Work Logs", systemImage: "checklist")
                }
                .tag(1)
            
            CalendarTasksView(store: store)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(2)
            
            ReportView(store: store)
                .tabItem {
                    Label("Report", systemImage: "doc.text.fill")
                }
                .tag(3)
            
            ProfileSettingsView(store: store)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}
