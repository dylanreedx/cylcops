import SwiftUI

struct AgentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            Text("Cyclops")
                .foregroundColor(.white)
            Text("\(appState.sessions.count) sessions")
                .foregroundColor(.secondary)
            Text("\(appState.projects.count) projects")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
