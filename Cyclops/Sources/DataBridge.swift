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
}
