import SwiftUI

struct ChildTabNavigation: View {
    let childId: String

    var body: some View {
        TabView {
            NavigationStack {
                ChildHomeView(childId: childId)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                TrainingSessionView(childId: childId)
            }
            .tabItem {
                Label("Train", systemImage: "trophy.fill")
            }

            NavigationStack {
                ActivityLogView(childId: childId)
            }
            .tabItem {
                Label("Log", systemImage: "doc.text.fill")
            }

            NavigationStack {
                SkillTrackView(childId: childId)
            }
            .tabItem {
                Label("Skills", systemImage: "star.fill")
            }

            NavigationStack {
                ProgressDashboardView(childId: childId)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                LearnView(childId: childId)
            }
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
        }
        .tint(.hudCyan)
    }
}
