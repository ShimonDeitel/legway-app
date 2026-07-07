import Foundation
import Combine

@MainActor
final class Store: ObservableObject {
    @Published var entries: [LogEntry] = []
    @Published var isProUnlocked: Bool = false

    static let freeLimit = 20

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        fileURL = appSupport.appendingPathComponent("legway_entries.json")
        load()
    }

    var canAddMore: Bool {
        isProUnlocked || entries.count < Store.freeLimit
    }

    func add(_ entry: LogEntry) {
        guard canAddMore else { return }
        entries.insert(entry, at: 0)
        save()
    }

    func update(_ entry: LogEntry) {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[idx] = entry
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func delete(_ entry: LogEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            entries = decoded
        } else {
            entries = [
            LogEntry(primaryText: "JFK-LHR", secondaryText: "Overnight, gate B22", numericValue: 0.0, tag: "British Airways"),
            LogEntry(primaryText: "LHR-CDG", secondaryText: "Short layover, tight connection", numericValue: 65.0, tag: "Air France")
            ]
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            try? data.write(to: fileURL)
        }
    }
}
