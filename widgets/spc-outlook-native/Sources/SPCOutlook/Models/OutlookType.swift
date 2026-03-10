import Foundation

// MARK: - OutlookDay

enum OutlookDay: Int, CaseIterable, Codable {
    case day1 = 1
    case day2 = 2
    case day3 = 3

    var label: String { "Day \(rawValue)" }

    var pageURL: URL {
        URL(string: "https://www.spc.noaa.gov/products/outlook/day\(rawValue)otlk.html")!
    }

    /// Tabs available for this day. Day 3 only has Categorical + Probabilistic.
    var availableTypes: [OutlookType] {
        switch self {
        case .day1, .day2: return [.categorical, .tornado, .wind, .hail]
        case .day3:        return [.categorical, .probabilistic]
        }
    }
}

// MARK: - OutlookType

enum OutlookType: String, CaseIterable, Codable {
    case categorical   = "cat"
    case tornado       = "torn"
    case wind          = "wind"
    case hail          = "hail"
    case probabilistic = "prob"   // Day 3 only

    var label: String {
        switch self {
        case .categorical:   "Categorical"
        case .tornado:       "Tornado"
        case .wind:          "Wind"
        case .hail:          "Hail"
        case .probabilistic: "Probabilistic"
        }
    }

    func imageURL(day: OutlookDay, suffix: String, cacheBust: Int) -> URL? {
        let n = day.rawValue
        let base = "https://www.spc.noaa.gov/products/outlook/day\(n)"
        let path: String
        switch self {
        case .categorical:   path = "otlk_\(suffix).png"
        case .tornado:       path = "probotlk_\(suffix)_torn.png"
        case .wind:          path = "probotlk_\(suffix)_wind.png"
        case .hail:          path = "probotlk_\(suffix)_hail.png"
        case .probabilistic: path = "prob_\(suffix).png"
        }
        return URL(string: "\(base)\(path)?t=\(cacheBust)")
    }
}

// MARK: - RefreshInterval

enum RefreshInterval: Int, CaseIterable, Codable {
    case fiveMin    = 300
    case fifteenMin = 900
    case thirtyMin  = 1800
    case oneHour    = 3600
    case sixHours   = 21600

    var label: String {
        switch self {
        case .fiveMin:    "5 min"
        case .fifteenMin: "15 min"
        case .thirtyMin:  "30 min"
        case .oneHour:    "1 hr"
        case .sixHours:   "6 hr"
        }
    }
}
