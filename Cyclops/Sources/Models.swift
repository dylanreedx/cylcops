import Foundation

struct AgentSession {
    let id: String
    let projectName: String
    let startedAt: Date
    let status: String
    // TODO: Additional fields from conductor sessions table
}

struct ProjectStatus {
    let name: String
    let totalFeatures: Int
    let passedFeatures: Int
    let failedFeatures: Int
    let inProgressFeatures: Int
    // TODO: Computed progress percentage
}
