import Foundation
import Observation
import AppKit

@MainActor
@Observable
final class OutlookViewModel {

    // MARK: Published state

    var activeDay: OutlookDay = .day1 {
        didSet {
            // Ensure the active type is valid for the new day.
            if !activeDay.availableTypes.contains(activeType) {
                activeType = activeDay.availableTypes.first ?? .categorical
            }
            savePreferences()
            Task { await fetchOutlook() }
        }
    }

    var activeType: OutlookType = .categorical {
        didSet { savePreferences() }
    }

    var refreshInterval: RefreshInterval = .fifteenMin {
        didSet {
            savePreferences()
            scheduleRefresh()
        }
    }

    var suffix: String?
    var lastUpdated: Date?
    var isLoading = false
    var errorMessage: String?

    // MARK: Computed

    var imageURL: URL? {
        guard let suffix else { return nil }
        let cacheBust = Int(lastUpdated?.timeIntervalSince1970 ?? 0)
        return activeType.imageURL(day: activeDay, suffix: suffix, cacheBust: cacheBust)
    }

    var issuanceLabel: String {
        guard let suffix else {
            return isLoading ? "Fetching issuance…" : "—"
        }
        let h = suffix.prefix(2)
        let m = suffix.suffix(2)
        return "Issued \(h):\(m) UTC"
    }

    var lastUpdatedLabel: String {
        guard let date = lastUpdated else { return "" }
        return "Updated \(date.formatted(date: .omitted, time: .shortened))"
    }

    // MARK: Private

    private let service = OutlookService()
    private var refreshTask: Task<Void, Never>?

    // MARK: Init

    init() {
        loadPreferences()
        Task { await fetchOutlook() }
        scheduleRefresh()

        // Listen for "Refresh Now" from the menu bar.
        NotificationCenter.default.addObserver(
            forName: .refreshOutlookNow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchOutlook()
            }
        }
    }

    // MARK: Actions

    func fetchOutlook() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        suffix = nil   // Clear stale suffix so image re-resolves
        do {
            let newSuffix = try await service.fetchSuffix(for: activeDay)
            suffix = newSuffix
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: Refresh timer

    private func scheduleRefresh() {
        refreshTask?.cancel()
        let seconds = Double(refreshInterval.rawValue)
        refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(seconds))
                guard !Task.isCancelled else { break }
                await self?.fetchOutlook()
            }
        }
    }

    // MARK: Persistence

    private func loadPreferences() {
        let d = UserDefaults.standard
        if let raw = d.string(forKey: "activeType"),
           let type = OutlookType(rawValue: raw) {
            activeType = type
        }
        if let dayInt = d.object(forKey: "activeDay") as? Int,
           let day = OutlookDay(rawValue: dayInt) {
            activeDay = day
            // Re-validate type after loading day.
            if !activeDay.availableTypes.contains(activeType) {
                activeType = activeDay.availableTypes.first ?? .categorical
            }
        }
        if let seconds = d.object(forKey: "refreshInterval") as? Int,
           let interval = RefreshInterval(rawValue: seconds) {
            refreshInterval = interval
        }
    }

    private func savePreferences() {
        let d = UserDefaults.standard
        d.set(activeType.rawValue,    forKey: "activeType")
        d.set(activeDay.rawValue,     forKey: "activeDay")
        d.set(refreshInterval.rawValue, forKey: "refreshInterval")
    }
}
