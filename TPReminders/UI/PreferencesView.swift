import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PreferencesView: View {
    @ObservedObject var store: WatchedFilesStore
    @ObservedObject var loginItemService: LoginItemService
    let scheduler: ScanScheduler

    @State private var selectedPath: URL?
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Watched Files")
                .font(.headline)

            fileList
                .frame(minHeight: 160)

            actionButtons

            Divider()

            Toggle("Start at Login", isOn: Binding(
                get: { loginItemService.isEnabled },
                set: { loginItemService.setEnabled($0) }
            ))

            lastScanLabel
        }
        .padding(20)
        .frame(minWidth: 420)
    }

    // MARK: - Subviews

    private var fileList: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(isTargeted ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: isTargeted ? 2 : 1)
                .background(Color(NSColor.textBackgroundColor).cornerRadius(6))

            if store.filePaths.isEmpty {
                Text("Drop .taskpaper files here, or use + to add")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                List(store.filePaths, id: \.self, selection: $selectedPath) { url in
                    Text(url.path)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .listStyle(.bordered)
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                addFile()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)

            Button {
                if let sel = selectedPath { store.remove(sel); selectedPath = nil }
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            .disabled(selectedPath == nil)

            Spacer()
        }
    }

    private var lastScanLabel: some View {
        Group {
            if let date = scheduler.lastScanDate {
                let formatted = RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
                Text("Last scan: \(formatted)")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                Text("Not yet scanned")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
    }

    // MARK: - Actions

    private func addFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "taskpaper") ?? .plainText,
            .plainText
        ]
        panel.begin { response in
            if response == .OK {
                panel.urls.forEach { store.add($0) }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil)
                    else { return }
                    let ext = url.pathExtension.lowercased()
                    guard ext == "taskpaper" || ext == "txt" else { return }
                    DispatchQueue.main.async { store.add(url) }
                }
                handled = true
            }
        }
        return handled
    }
}
