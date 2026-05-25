import Foundation

private let kLastMorningNotifyDate = "lastMorningNotifyDate"
private let kLastAfternoonNotifyDate = "lastAfternoonNotifyDate"
private let kLastHourlyScan = "lastHourlyScan"
private let kLastScanDisplay = "lastScanDisplay"

class ScanScheduler {
    private var timer: Timer?
    private var onScan: (() -> Void)?

    var lastScanDate: Date? {
        UserDefaults.standard.object(forKey: kLastScanDisplay) as? Date
    }

    func start(onScan: @escaping () -> Void) {
        self.onScan = onScan
        // Fire immediately on launch
        fireScan()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func triggerNow() {
        fireScan()
    }

    private func tick() {
        let now = Date()
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let today = cal.startOfDay(for: now)
        let defaults = UserDefaults.standard

        // Morning window: 9:00–9:04
        if hour == 9, minute < 5 {
            let last = defaults.object(forKey: kLastMorningNotifyDate) as? Date
            if last == nil || cal.startOfDay(for: last!) < today {
                defaults.set(now, forKey: kLastMorningNotifyDate)
                fireScan()
                return
            }
        }

        // Afternoon window: 16:00–16:04
        if hour == 16, minute < 5 {
            let last = defaults.object(forKey: kLastAfternoonNotifyDate) as? Date
            if last == nil || cal.startOfDay(for: last!) < today {
                defaults.set(now, forKey: kLastAfternoonNotifyDate)
                fireScan()
                return
            }
        }

        // Hourly fallback
        let lastHourly = defaults.object(forKey: kLastHourlyScan) as? Date
        if lastHourly == nil || now.timeIntervalSince(lastHourly!) > 3600 {
            fireScan()
        }
    }

    private func fireScan() {
        UserDefaults.standard.set(Date(), forKey: kLastHourlyScan)
        UserDefaults.standard.set(Date(), forKey: kLastScanDisplay)
        onScan?()
    }
}
