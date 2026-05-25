import Foundation

private let kWatchedFilePaths = "watchedFilePaths"

class WatchedFilesStore: ObservableObject {
    @Published var filePaths: [URL] = []

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: kWatchedFilePaths) ?? []
        filePaths = stored.map { URL(fileURLWithPath: $0) }
    }

    func add(_ url: URL) {
        guard !filePaths.contains(url) else { return }
        filePaths.append(url)
        persist()
    }

    func remove(_ url: URL) {
        filePaths.removeAll { $0 == url }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(filePaths.map(\.path), forKey: kWatchedFilePaths)
    }
}
