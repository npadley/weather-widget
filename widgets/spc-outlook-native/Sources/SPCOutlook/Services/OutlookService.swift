import Foundation

actor OutlookService {

    /// Fetches the SPC outlook page for the given day and returns the issuance
    /// time suffix embedded in the page JS (e.g. "2000" for 20:00 UTC).
    func fetchSuffix(for day: OutlookDay) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: day.pageURL)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OutlookError.badResponse
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw OutlookError.parseFailure("Could not decode page as UTF-8")
        }

        // Matches patterns like: show_tab('otlk_2000') or show_tab('prob_1930')
        let pattern = #/(?:otlk|prob)_(\d{3,4})/#
        if let match = html.firstMatch(of: pattern) {
            return String(match.1)
        }

        throw OutlookError.parseFailure("Could not find issuance time in SPC Day \(day.rawValue) page")
    }
}

enum OutlookError: LocalizedError {
    case badResponse
    case parseFailure(String)

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "SPC server returned an unexpected response."
        case .parseFailure(let detail):
            return "Could not parse SPC page: \(detail)"
        }
    }
}
