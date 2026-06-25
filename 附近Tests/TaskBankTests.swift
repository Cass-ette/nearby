import Testing
import Foundation
@testable import 附近

struct TaskBankTests {
    @Test func loadsAllTasksFromBundle() async throws {
        let bank = try await TaskBank.load()
        #expect(bank.count == 30, "Expected 30 tasks, got \(bank.count)")
    }

    @Test func allTasksHaveBilingualContent() async throws {
        let bank = try await TaskBank.load()
        for task in bank {
            #expect(task.title["zh"]?.isEmpty == false, "Task \(task.id) missing zh title")
            #expect(task.title["en"]?.isEmpty == false, "Task \(task.id) missing en title")
            #expect(task.prompt["zh"]?.isEmpty == false, "Task \(task.id) missing zh prompt")
            #expect(task.prompt["en"]?.isEmpty == false, "Task \(task.id) missing en prompt")
        }
    }

    @Test func allTasksHaveRequiredMetadata() async throws {
        let bank = try await TaskBank.load()
        for task in bank {
            #expect(task.proposedBy.isEmpty == false, "Task \(task.id) missing proposedBy")
            #expect(task.voteCount > 0, "Task \(task.id) voteCount must be > 0")
            #expect(task.adoptedOn.isEmpty == false, "Task \(task.id) missing adoptedOn")
        }
    }
}
