import Foundation

struct AgentSession: Identifiable {
    let id: String
    let projectName: String
    let startedAt: Date
    let status: String
}

struct ProjectStatus: Identifiable {
    var id: String { name }
    let name: String
    let totalFeatures: Int
    let passedFeatures: Int
    let failedFeatures: Int
    let inProgressFeatures: Int

    var progressPercent: Double {
        guard totalFeatures > 0 else { return 0 }
        return Double(passedFeatures) / Double(totalFeatures)
    }
}
