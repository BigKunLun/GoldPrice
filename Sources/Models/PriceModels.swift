import Foundation

// MARK: - Data Models
struct PriceInfo {
    var price: String = "--"
    var yesterdayPrice: String = "--"
    var changeRate: String = ""      // 如 "+2.43%"
    var changeAmount: String = ""    // 如 "+26.93"
    var dayHigh: String = "--"       // 当日最高价
    var dayLow: String = "--"        // 当日最低价

    var isUp: Bool {
        if let rate = Double(changeRate.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "")) {
            return rate >= 0
        }
        return changeRate.hasPrefix("+") || (!changeRate.hasPrefix("-") && !changeRate.isEmpty)
    }
}

struct GoldPrices {
    var minsheng = PriceInfo()
    var london = PriceInfo()
    var newyork = PriceInfo()
    var lastUpdate: Date?

    func priceInfo(for key: String) -> PriceInfo {
        switch key {
        case "minsheng": return minsheng
        case "london": return london
        case "newyork": return newyork
        default: return PriceInfo()
        }
    }
}

struct APIResponse: Codable {
    struct ResultData: Codable {
        struct Datas: Codable {
            let price: String?
            let yesterdayPrice: String?
            let upAndDownRate: String?
            let upAndDownAmt: String?
        }
        let datas: Datas?
    }
    let resultData: ResultData?
}

// MARK: - Price Record
struct PriceRecord: Codable {
    let timestamp: Date
    let price: Double
}
