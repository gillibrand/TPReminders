import Foundation

class ScanEngine {
    func scan(store: WatchedFilesStore) -> [TaskItem] {
        store.filePaths
            .filter { FileManager.default.fileExists(atPath: $0.path) }
            .flatMap { TaskPaperParser.parse(fileURL: $0) }
            .filter(\.isDue)
            .sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (a?, b?): return a < b
                case (nil, _?): return false
                case (_?, nil): return true
                case (nil, nil): return $0.filePath.path < $1.filePath.path
                }
            }
    }
}
