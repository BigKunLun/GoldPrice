import Foundation

// MARK: - Gold Price Service
class GoldPriceService {
    static let shared = GoldPriceService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        session = URLSession(configuration: config)
    }

    func fetchAllPrices() async -> GoldPrices {
        var prices = GoldPrices()

        async let minsheng = fetchMinsheng()
        async let international = fetchInternationalGold()

        prices.minsheng = await minsheng

        let intlPrices = await international
        prices.london = intlPrices.london
        prices.newyork = intlPrices.newyork

        prices.lastUpdate = Date()

        // 记录国内金价历史并更新最高/最低价
        updateHighLow(&prices.minsheng, for: "minsheng")

        // 清理旧数据
        PriceHistoryManager.shared.cleanupOldData()

        return prices
    }

    private func updateHighLow(_ info: inout PriceInfo, for bankKey: String) {
        guard let price = Double(info.price), price > 0 else { return }
        PriceHistoryManager.shared.recordPrice(price, for: bankKey)
        let (high, low) = PriceHistoryManager.shared.getHighLow(for: bankKey)
        if let h = high { info.dayHigh = String(format: "%.2f", h) }
        if let l = low { info.dayLow = String(format: "%.2f", l) }
    }

    private func fetchMinsheng() async -> PriceInfo {
        var info = PriceInfo()
        guard let url = URL(string: "https://api.jdjygold.com/gw/generic/hj/h5/m/latestPrice") else { return info }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(APIResponse.self, from: data)
            if let datas = response.resultData?.datas {
                info.price = datas.price ?? "--"
                info.yesterdayPrice = datas.yesterdayPrice ?? "--"
                info.changeRate = datas.upAndDownRate ?? ""
                info.changeAmount = datas.upAndDownAmt ?? ""
            }
        } catch {
            print("Minsheng fetch error: \(error)")
        }
        return info
    }

    // 获取国际金价（伦敦金、纽约金）
    private func fetchInternationalGold() async -> (london: PriceInfo, newyork: PriceInfo) {
        var london = PriceInfo()
        var newyork = PriceInfo()

        // 使用新浪财经 API
        guard let url = URL(string: "https://hq.sinajs.cn/list=hf_XAU,hf_GC") else {
            print("❌ Invalid URL for international gold")
            return (london, newyork)
        }

        var request = URLRequest(url: url)
        request.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 International gold API status: \(httpResponse.statusCode)")
            }
            // 新浪 API 返回 GB18030 编码，优先尝试，然后 fallback 到 UTF-8/ASCII
            let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
            if let text = String(data: data, encoding: gb18030) ?? String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                print("📦 API response length: \(text.count) chars")
                let lines = text.components(separatedBy: ";")
                for line in lines {
                    if line.contains("hf_XAU") {
                        print("🔍 Parsing XAU (London): \(line.prefix(100))...")
                        london = parseSinaData(line)
                        print("✅ London price: \(london.price)")
                    } else if line.contains("hf_GC") {
                        print("🔍 Parsing GC (NewYork): \(line.prefix(100))...")
                        newyork = parseSinaData(line)
                        print("✅ NewYork price: \(newyork.price)")
                    }
                }
            }
        } catch {
            print("❌ International gold fetch error: \(error)")
        }

        return (london, newyork)
    }

    // 解析新浪数据：当前价,昨收,开盘,当前价2,最高,最低,时间,昨收(备用),...
    // 格式: "5191.60,5141.430,5191.60,5191.90,5210.20,5122.02,16:41:00,5141.43,..."
    private func parseSinaData(_ line: String) -> PriceInfo {
        var info = PriceInfo()
        guard let start = line.firstIndex(of: "\""),
              let end = line.lastIndex(of: "\"") else {
            print("❌ Cannot find quotes in line")
            return info
        }
        let content = String(line[line.index(after: start)..<end])
        let parts = content.components(separatedBy: ",")
        print("📊 Parts count: \(parts.count), first: \(parts.first ?? "nil")")

        // 字段0: 当前价, 字段1: 昨收, 字段4: 最高价, 字段5: 最低价, 字段7: 昨收(备用)
        if parts.count > 7 {
            if let currentPrice = Double(parts[0]) {
                info.price = String(format: "%.2f", currentPrice)

                // 尝试获取昨收价（字段1或字段7）
                var yesterdayPrice: Double? = nil
                if let yp = Double(parts[1]), yp > 0 {
                    yesterdayPrice = yp
                } else if let yp = Double(parts[7]), yp > 0 {
                    yesterdayPrice = yp
                }

                if let yp = yesterdayPrice {
                    info.yesterdayPrice = String(format: "%.2f", yp)
                    let change = currentPrice - yp
                    let changePercent = (change / yp) * 100
                    let sign = change >= 0 ? "+" : ""
                    info.changeAmount = "\(sign)\(String(format: "%.2f", change))"
                    info.changeRate = "\(sign)\(String(format: "%.2f", changePercent))%"
                }

                // 解析最高价（字段4）
                if let high = Double(parts[4]), high > 0 {
                    info.dayHigh = String(format: "%.2f", high)
                }

                // 解析最低价（字段5）
                if let low = Double(parts[5]), low > 0 {
                    info.dayLow = String(format: "%.2f", low)
                }
            }
        }
        return info
    }
}
