import Foundation

// MARK: - Price History Manager
class PriceHistoryManager {
    static let shared = PriceHistoryManager()

    private let historyKey = "priceHistoryV2"
    private var history: [String: [PriceRecord]] = [:]

    private init() {
        loadHistory()
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: [PriceRecord]].self, from: data) {
            history = decoded
        }
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    func recordPrice(_ price: Double, for bankKey: String) {
        if history[bankKey] == nil {
            history[bankKey] = []
        }
        history[bankKey]?.append(PriceRecord(timestamp: Date(), price: price))
        saveHistory()
    }

    func getRecordsInLast24Hours(for bankKey: String) -> [PriceRecord] {
        guard let records = history[bankKey] else { return [] }
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        return records.filter { $0.timestamp >= cutoff }
    }

    func getHighLow(for bankKey: String) -> (high: Double?, low: Double?) {
        let records = getRecordsInLast24Hours(for: bankKey)
        guard !records.isEmpty else { return (nil, nil) }
        let prices = records.map { $0.price }
        return (prices.max(), prices.min())
    }

    func cleanupOldData() {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        for (key, _) in history {
            history[key] = history[key]?.filter { $0.timestamp >= cutoff }
        }
        saveHistory()
    }
}
