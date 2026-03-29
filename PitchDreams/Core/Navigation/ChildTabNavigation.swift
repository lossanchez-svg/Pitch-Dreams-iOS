import SwiftUI

struct ChildTabNavigation: View {
    let childId: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPad Sidebar

    private var iPadLayout: some View {
        NavigationSplitView {
            List {
                NavigationLink(value: ChildTab.home) {
                    Label("Home", systemImage: "house.fill")
                }
                NavigationLink(value: ChildTab.train) {
                    Label("Train", systemImage: "trophy.fill")
                }
                NavigationLink(value: ChildTab.log) {
                    Label("Log", systemImage: "doc.text.fill")
                }
                NavigationLink(value: ChildTab.skills) {
                    Label("Skills", systemImage: "star.fill")
                }
                NavigationLink(value: ChildTab.progress) {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink(value: ChildTab.learn) {
                    Label("Learn", systemImage: "book.fill")
                }
            }
            .navigationTitle("PitchDreams")
            .tint(.hudCyan)
        } detail: {
            NavigationStack {
                ChildHomeView(childId: childId)
            }
        }
    }

    // MARK: - iPhone TabView

    private var iPhoneLayout: some View {
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

// MARK: - Tab Enum

private enum ChildTab: Hashable {
    case home, train, log, skills, progress, learn
}
