import Foundation

struct DataBridge {
    let dbPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.dbPath = "\(home)/.conductor/conductor.db"
    }

    private func runQuery(_ sql: String) -> [[String: String]] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        process.arguments = ["-json", dbPath, sql]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard !data.isEmpty else { return [] }

            if let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return rows.map { row in
                    var stringRow: [String: String] = [:]
                    for (key, value) in row {
                        stringRow[key] = "\(value)"
                    }
                    return stringRow
                }
            }
        } catch {
            // Silently return empty on failure
        }
        return []
    }

    func fetchProjects() -> [ProjectStatus] {
        let rows = runQuery("""
            SELECT p.name,
                   COUNT(f.id) AS total,
                   SUM(CASE WHEN f.status = 'passed' THEN 1 ELSE 0 END) AS passed,
                   SUM(CASE WHEN f.status = 'failed' THEN 1 ELSE 0 END) AS failed,
                   SUM(CASE WHEN f.status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress
            FROM projects p
            LEFT JOIN features f ON f.project_id = p.id
            GROUP BY p.name
            """)

        return rows.map { row in
            ProjectStatus(
                name: row["name"] ?? "",
                totalFeatures: Int(row["total"] ?? "0") ?? 0,
                passedFeatures: Int(row["passed"] ?? "0") ?? 0,
                failedFeatures: Int(row["failed"] ?? "0") ?? 0,
                inProgressFeatures: Int(row["in_progress"] ?? "0") ?? 0
            )
        }
    }
}
