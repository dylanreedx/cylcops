import SwiftUI

enum HUDTab: String, CaseIterable {
    case sessions = "SESSIONS"
    case projects = "PROJECTS"
    case memories = "RECENT MEMORIES"
}

struct AgentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notchVM: NotchViewModel
    @State private var selectedTab: HUDTab = .sessions
    @State private var contentVisible = false
    @State private var tabBarVisible = false

    private var isOpen: Bool { notchVM.notchState == .open }

    var body: some View {
        ZStack {
            // Black fill inside the notch shape
            Color.black

            // Content only visible when open
            if isOpen {
                VStack(spacing: 0) {
                    // Tab bar
                    HStack(spacing: 16) {
                        ForEach(HUDTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1.2)
                                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.35))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .opacity(tabBarVisible ? 1 : 0)
                    .scaleEffect(tabBarVisible ? 1 : 0.8)

                    Divider()
                        .background(Color.white.opacity(0.15))
                        .opacity(tabBarVisible ? 1 : 0)

                    // Tab content
                    Group {
                        switch selectedTab {
                        case .sessions:
                            sessionsContent
                        case .projects:
                            projectsContent
                        case .memories:
                            memoriesContent
                        }
                    }
                    .opacity(contentVisible ? 1 : 0)
                    .scaleEffect(contentVisible ? 1 : 0.6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Offset down to account for the notch area at top
                .padding(.top, NotchSizing.getClosedNotchSize().height)
            }
        }
        // Inner frame: animates between closed and open sizes
        .frame(
            width: isOpen ? NotchSizing.openSize.width : notchVM.closedSize.width,
            height: isOpen ? NotchSizing.openSize.height : notchVM.closedSize.height
        )
        .clipShape(
            NotchShape(
                topCornerRadius: isOpen ? 19 : 6,
                bottomCornerRadius: isOpen ? 24 : 14
            )
        )
        .shadow(
            color: .black.opacity(isOpen ? 0.5 : 0),
            radius: isOpen ? 15 : 0,
            y: isOpen ? 5 : 0
        )
        // Outer frame: fixed at window size, pinned to .top so content expands downward
        .frame(
            maxWidth: NotchSizing.windowSize.width,
            maxHeight: NotchSizing.windowSize.height,
            alignment: .top
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isOpen)
        .onChange(of: isOpen) { nowOpen in
            if nowOpen {
                // Staggered reveal: tab bar first, then content
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.08)) {
                    tabBarVisible = true
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) {
                    contentVisible = true
                }
            } else {
                // Fast fade out on close
                withAnimation(.easeOut(duration: 0.15)) {
                    contentVisible = false
                    tabBarVisible = false
                }
            }
        }
    }

    // MARK: - Sessions: Horizontal Carousel

    @ViewBuilder
    private var sessionsContent: some View {
        if appState.sessions.isEmpty {
            Spacer()
            Text("No recent projects")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.sessions) { session in
                        SessionCardView(session: session)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Shared Grid Layout

    private var twoRowGrid: [GridItem] {
        [GridItem(.fixed(95), spacing: 8), GridItem(.fixed(95), spacing: 8)]
    }

    // MARK: - Projects

    @ViewBuilder
    private var projectsContent: some View {
        if appState.projects.isEmpty {
            Spacer()
            Text("No projects")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: twoRowGrid, spacing: 8) {
                    ForEach(appState.projects) { project in
                        ProjectCardView(project: project)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Memories

    @ViewBuilder
    private var memoriesContent: some View {
        if appState.memories.isEmpty {
            Spacer()
            Text("No memories")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: twoRowGrid, spacing: 8) {
                    ForEach(appState.memories) { memory in
                        MemoryCardView(memory: memory)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}
