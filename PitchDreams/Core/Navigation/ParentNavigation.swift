import SwiftUI

struct ParentNavigation: View {
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
                NavigationLink(value: ParentTab.dashboard) {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                NavigationLink(value: ParentTab.settings) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("PitchDreams")
        } detail: {
            NavigationStack {
                ParentDashboardView()
            }
        }
    }

    // MARK: - iPhone Stack

    private var iPhoneLayout: some View {
        NavigationStack {
            ParentDashboardView()
        }
    }
}

// MARK: - Tab Enum

private enum ParentTab: Hashable {
    case dashboard, settings
}
