import SwiftUI

struct ChildTabNavigation: View {
    let childId: String
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: ChildTab = .home

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

    // MARK: - iPhone Custom Tab Layout

    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        ChildHomeView(childId: childId)
                    }
                case .train:
                    NavigationStack {
                        TrainingSessionView(childId: childId)
                    }
                case .log:
                    NavigationStack {
                        ActivityLogView(childId: childId)
                    }
                case .skills:
                    NavigationStack {
                        SkillTrackView(childId: childId)
                    }
                case .progress:
                    NavigationStack {
                        ProgressDashboardView(childId: childId)
                    }
                case .learn:
                    NavigationStack {
                        LearnView(childId: childId)
                    }
                }
            }

            // Custom glassmorphic tab bar
            customTabBar
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(tab: .home, icon: "house.fill", label: "Home")
            tabBarItem(tab: .train, icon: "dumbbell.fill", label: "Train")
            tabBarItem(tab: .log, icon: "square.and.pencil", label: "Log")
            tabBarItem(tab: .skills, icon: "medal.fill", label: "Skills")
            moreMenu
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .background(
            ZStack {
                // Dark glass bg
                Color(hex: "#0F172A").opacity(0.6)
                    .background(.ultraThinMaterial)
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 48,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 48
            )
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: -10)
    }

    private func tabBarItem(tab: ChildTab, icon: String, label: String) -> some View {
        Button {
            withAnimation(.dsSnappy) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundStyle(selectedTab == tab ? Color.dsSecondary : Color.dsOnSurfaceVariant.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        LinearGradient(
                            colors: [Color.dsSecondary.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.dsSecondary.opacity(0.3), radius: 15)
                    }
                }
            )
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTab == tab ? [.isSelected, .isButton] : .isButton)
    }

    private var moreMenu: some View {
        Menu {
            Button {
                selectedTab = .progress
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
            Button {
                selectedTab = .learn
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Learn", systemImage: "book.fill")
            }

            Divider()

            Button(role: .destructive) {
                authManager.logout()
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                Text("MORE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.5)
            }
            .foregroundStyle(
                [.progress, .learn].contains(selectedTab)
                    ? Color.dsSecondary
                    : Color.dsOnSurfaceVariant.opacity(0.4)
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if [.progress, .learn].contains(selectedTab) {
                        LinearGradient(
                            colors: [Color.dsSecondary.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.dsSecondary.opacity(0.3), radius: 15)
                    }
                }
            )
        }
    }
}

// MARK: - Tab Enum

private enum ChildTab: Hashable {
    case home, train, log, skills, progress, learn
}
