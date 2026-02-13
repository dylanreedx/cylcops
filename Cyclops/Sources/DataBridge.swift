import Foundation

struct DataBridge {
    private let basePaths: [String]
    private let claudeProjectsDir: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.basePaths = ["\(home)/Documents/personal"]
        self.claudeProjectsDir = "\(home)/.claude/projects"
    }

    /// Discover all conductor.db files across project directories
    private func discoverDBPaths() -> [String] {
        let fm = FileManager.default
        var paths: [String] = []

        for base in basePaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: base) else { continue }
            for dir in contents {
                let dbPath = "\(base)/\(dir)/.conductor/conductor.db"
                if fm.fileExists(atPath: dbPath) {
                    paths.append(dbPath)
                }
            }
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let globalDB = "\(home)/.conductor/conductor.db"
        if fm.fileExists(atPath: globalDB) && !paths.contains(globalDB) {
            paths.append(globalDB)
        }

        return paths
    }

    private func runQuery(_ sql: String, dbPath: String) -> [[String: String]] {
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

    // MARK: - Shell Helper

    private func runShell(_ executable: String, _ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return "" }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }

    // MARK: - Path Decoding

    /// Decode a Claude projects encoded path like `-Users-dylan-Documents-personal-cyclops`
    /// back to `/Users/dylan/Documents/personal/cyclops`.
    /// Strategy: replace leading `-` with `/`, then greedily resolve `-` as `/` where the path exists.
    private func decodePath(_ encoded: String) -> String {
        let fm = FileManager.default
        guard encoded.hasPrefix("-") else { return encoded }

        // Split into components (drop leading empty from first `-`)
        let parts = encoded.dropFirst().split(separator: "-", omittingEmptySubsequences: false).map { String($0) }
        guard !parts.isEmpty else { return "/\(encoded.dropFirst())" }

        // Greedy path resolution: try joining with `/` and check existence
        var resolved = "/\(parts[0])"
        var i = 1
        while i < parts.count {
            let trySlash = resolved + "/\(parts[i])"
            let tryHyphen = resolved + "-\(parts[i])"

            if fm.fileExists(atPath: trySlash) {
                resolved = trySlash
            } else if fm.fileExists(atPath: tryHyphen) {
                resolved = tryHyphen
            } else {
                // Neither exists yet — prefer slash (building toward a real path)
                resolved = trySlash
            }
            i += 1
        }
        return resolved
    }

    // MARK: - JSONL Tail Read

    /// Read the last ~4KB of a file, find the last line containing sessionId, parse metadata.
    private func readJSONLMetadata(at path: String) -> (sessionId: String, cwd: String, gitBranch: String, version: String)? {
        guard let fileHandle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { fileHandle.closeFile() }

        let fileSize = fileHandle.seekToEndOfFile()
        let readSize: UInt64 = min(fileSize, 4096)
        fileHandle.seek(toFileOffset: fileSize - readSize)
        let data = fileHandle.readDataToEndOfFile()

        guard let text = String(data: data, encoding: .utf8) else { return nil }

        // Iterate lines from the end to find one with sessionId
        let lines = text.components(separatedBy: "\n").reversed()
        for line in lines {
            guard line.contains("\"sessionId\"") else { continue }
            guard let lineData = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else { continue }

            let sessionId = json["sessionId"] as? String ?? ""
            let cwd = json["cwd"] as? String ?? ""
            let gitBranch = json["gitBranch"] as? String ?? ""
            let version = json["version"] as? String ?? ""

            if !sessionId.isEmpty {
                return (sessionId, cwd, gitBranch, version)
            }
        }

        return nil
    }

    // MARK: - Session Detection (File-Based)

    /// Detect Claude Code projects by scanning `~/.claude/projects/`.
    /// Returns the 5 most recently active projects, with active status based on file mtime.
    func fetchSessions() -> [AgentSession] {
        let fm = FileManager.default
        let now = Date()

        guard let projectDirs = try? fm.contentsOfDirectory(atPath: claudeProjectsDir) else { return [] }

        struct ProjectInfo {
            let encodedName: String
            let jsonlPath: String
            let mtime: Date
        }

        // 1. Scan each project directory, find the most recent JSONL file
        var projectInfos: [ProjectInfo] = []
        for dirName in projectDirs {
            let dirPath = "\(claudeProjectsDir)/\(dirName)"
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dirPath, isDirectory: &isDir), isDir.boolValue else { continue }

            // List only .jsonl files directly in this directory (not subdirectories)
            guard let contents = try? fm.contentsOfDirectory(atPath: dirPath) else { continue }

            var bestPath: String?
            var bestMtime: Date = .distantPast

            for file in contents {
                guard file.hasSuffix(".jsonl") else { continue }
                let filePath = "\(dirPath)/\(file)"

                // Make sure it's a file, not a directory
                var fileIsDir: ObjCBool = false
                guard fm.fileExists(atPath: filePath, isDirectory: &fileIsDir), !fileIsDir.boolValue else { continue }

                if let attrs = try? fm.attributesOfItem(atPath: filePath),
                   let mtime = attrs[.modificationDate] as? Date,
                   mtime > bestMtime {
                    bestMtime = mtime
                    bestPath = filePath
                }
            }

            if let path = bestPath {
                projectInfos.append(ProjectInfo(encodedName: dirName, jsonlPath: path, mtime: bestMtime))
            }
        }

        // 2. Sort by most recent activity, take top 5
        projectInfos.sort { $0.mtime > $1.mtime }
        let top = projectInfos.prefix(5)

        // 3. Build tmux CWD→session map (one call for all active sessions)
        let tmuxOutput = runShell("/usr/bin/env", ["tmux", "list-panes", "-a", "-F", "#{pane_current_path}\t#{session_name}"])
        var cwdToTmux: [String: String] = [:]
        for line in tmuxOutput.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard parts.count == 2 else { continue }
            cwdToTmux[String(parts[0])] = String(parts[1])
        }

        // 4. Build AgentSession for each project
        var sessions: [AgentSession] = []
        for info in top {
            let decodedPath = decodePath(info.encodedName)
            let isActive = now.timeIntervalSince(info.mtime) < 120

            // Read JSONL metadata from the most recent file
            let metadata = readJSONLMetadata(at: info.jsonlPath)
            let sessionId = metadata?.sessionId ?? UUID().uuidString
            let cwd = metadata?.cwd ?? decodedPath
            let gitBranch = metadata?.gitBranch ?? ""
            let version = metadata?.version ?? ""

            // Use cwd from JSONL if path decoding gave a non-existent path
            let workspacePath: String
            if FileManager.default.fileExists(atPath: decodedPath) {
                workspacePath = decodedPath
            } else {
                workspacePath = cwd
            }

            let projectName = (workspacePath as NSString).lastPathComponent

            // Map active sessions to tmux
            let tmuxSession = isActive ? (cwdToTmux[workspacePath] ?? "") : ""

            var session = AgentSession(
                id: sessionId,
                projectName: projectName,
                workspacePath: workspacePath,
                lastActivityDate: info.mtime,
                isActive: isActive
            )
            session.gitBranch = gitBranch
            session.claudeVersion = version
            session.tmuxSession = tmuxSession
            sessions.append(session)
        }

        return sessions
    }

    func fetchProjects() -> [ProjectStatus] {
        let dbPaths = discoverDBPaths()
        var allProjects: [ProjectStatus] = []

        for dbPath in dbPaths {
            let rows = runQuery("""
                SELECT p.name,
                       COUNT(f.id) AS total,
                       SUM(CASE WHEN f.status = 'passed' THEN 1 ELSE 0 END) AS passed,
                       SUM(CASE WHEN f.status = 'failed' THEN 1 ELSE 0 END) AS failed,
                       SUM(CASE WHEN f.status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress
                FROM projects p
                LEFT JOIN features f ON f.project_id = p.id
                GROUP BY p.name
                """, dbPath: dbPath)

            for row in rows {
                allProjects.append(ProjectStatus(
                    name: row["name"] ?? "",
                    totalFeatures: Int(row["total"] ?? "0") ?? 0,
                    passedFeatures: Int(row["passed"] ?? "0") ?? 0,
                    failedFeatures: Int(row["failed"] ?? "0") ?? 0,
                    inProgressFeatures: Int(row["in_progress"] ?? "0") ?? 0
                ))
            }
        }

        return allProjects
    }

    func captureTerminalContent(for sessionName: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["tmux", "capture-pane", "-t", sessionName, "-p", "-S", "-30"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return ""
        }
    }

    func fetchDiffStats(workspacePath: String) -> (added: Int, removed: Int) {
        guard !workspacePath.isEmpty else { return (0, 0) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", workspacePath, "diff", "--shortstat"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return parseDiffStats(output)
        } catch {
            return (0, 0)
        }
    }

    private func parseDiffStats(_ output: String) -> (added: Int, removed: Int) {
        var added = 0
        var removed = 0

        if let range = output.range(of: #"(\d+) insertion"#, options: .regularExpression) {
            let numStr = output[range].split(separator: " ").first ?? ""
            added = Int(numStr) ?? 0
        }

        if let range = output.range(of: #"(\d+) deletion"#, options: .regularExpression) {
            let numStr = output[range].split(separator: " ").first ?? ""
            removed = Int(numStr) ?? 0
        }

        return (added, removed)
    }

    func fetchMemories() -> [Memory] {
        let dbPaths = discoverDBPaths()
        var allMemories: [Memory] = []
        let now = Date()

        for dbPath in dbPaths {
            let rows = runQuery("""
                SELECT id, name, content, tags, project_name, created_at
                FROM memories
                ORDER BY created_at DESC
                LIMIT 20
                """, dbPath: dbPath)

            for row in rows {
                let createdAt: Date
                if let ts = Double(row["created_at"] ?? "") {
                    createdAt = Date(timeIntervalSince1970: ts / 1000)
                } else {
                    createdAt = now
                }

                let tagsString = row["tags"] ?? ""
                let tags: [String]
                if tagsString.isEmpty {
                    tags = []
                } else if tagsString.hasPrefix("[") {
                    if let data = tagsString.data(using: .utf8),
                       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String] {
                        tags = parsed
                    } else {
                        tags = [tagsString]
                    }
                } else {
                    tags = tagsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                }

                allMemories.append(Memory(
                    id: row["id"] ?? UUID().uuidString,
                    name: row["name"] ?? "",
                    content: row["content"] ?? "",
                    tags: tags,
                    projectName: row["project_name"] ?? "",
                    createdAt: createdAt
                ))
            }
        }

        return allMemories
    }
}
