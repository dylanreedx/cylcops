import Foundation

struct AgentSession: Identifiable {
    let id: String              // session UUID from JSONL
    let projectName: String     // directory basename (e.g. "cyclops")
    let workspacePath: String   // decoded full path (e.g. /Users/dylan/Documents/personal/cyclops)
    let lastActivityDate: Date  // most recent JSONL file mtime
    let isActive: Bool          // mtime < 120 seconds ago
    var gitBranch: String = ""
    var claudeVersion: String = ""
    var tmuxSession: String = ""
    var terminalContent: String = ""
    var linesAdded: Int = 0
    var linesRemoved: Int = 0
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

struct Memory: Identifiable {
    let id: String
    let name: String
    let content: String
    let tags: [String]
    let projectName: String
    let createdAt: Date
}
