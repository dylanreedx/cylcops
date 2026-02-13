import SwiftUI

enum HUDTab: String, CaseIterable {
    case sessions = "Sessions"
    case projects = "Projects"
    case memories = "Memories"
}

struct AgentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: HUDTab = .sessions

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 2) {
                ForEach(HUDTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab
                                    ? Color.white.opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.2))

            // Content
            ScrollView {
                VStack(spacing: 8) {
                    switch selectedTab {
                    case .sessions:
                        sessionsContent
                    case .projects:
                        projectsContent
                    case .memories:
                        memoriesContent
                    }
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var sessionsContent: some View {
        if appState.sessions.isEmpty {
            Text("No active sessions")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 100)
        } else {
            ForEach(appState.sessions) { session in
                SessionCardView(session: session)
            }
        }
    }

    @ViewBuilder
    private var projectsContent: some View {
        if appState.projects.isEmpty {
            Text("No projects")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 100)
        } else {
            ForEach(appState.projects) { project in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(project.passedFeatures)/\(project.totalFeatures)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.green.opacity(0.8))
                                .frame(width: geo.size.width * project.progressPercent, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private var memoriesContent: some View {
        Text("Memories")
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.4))
            .frame(maxWidth: .infinity, minHeight: 100)
    }
}
