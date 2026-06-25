import Foundation

enum TaskBank {
    /// Loads and caches tasks.json from the main bundle.
    /// Returns empty array if file is missing or invalid (never throws in sync API).
    static func loadSync() -> [DailyTask] {
        if let cached { return cached }
        guard let url = Bundle.main.url(forResource: "tasks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bank = try? JSONDecoder().decode(TaskBankFile.self, from: data) else {
            return []
        }
        cached = bank.tasks
        return bank.tasks
    }

    /// Async variant for callers that prefer throws semantics.
    static func load() async throws -> [DailyTask] {
        let tasks = loadSync()
        guard !tasks.isEmpty else {
            throw TaskBankError.fileNotFound
        }
        return tasks
    }

    private nonisolated(unsafe) static var cached: [DailyTask]?
}

enum TaskBankError: Error {
    case fileNotFound
}
