import Peripheral
import Foundation

class FileStorage {
    var baseURL: URL {
        let paths = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask)
        return paths[0]
    }

    init() {}

    func isExists(_ path: Path) -> Bool {
        makeURL(for: path).isExists
    }

    func makeDirectory(for path: Path) throws {
        let subdirectory = path.removingLastComponent
        let directory = baseURL.appendingPathComponent(subdirectory.string)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true)
        }
    }

    private func makeURL(for path: Path) -> URL {
        baseURL.appendingPathComponent(path.string)
    }

    func read(_ path: Path) throws -> String {
        let url = makeURL(for: path)
        return try .init(contentsOf: url)
    }

    func write(_ content: String, at path: Path) throws {
        try makeDirectory(for: path)
        let url = makeURL(for: path)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func delete(_ path: Path) throws {
        let url = makeURL(for: path)
        guard url.isExists else { return }
        try FileManager.default.removeItem(at: url)
    }

    func reset() throws {
        let contents = try FileManager
            .default
            .contentsOfDirectory(atPath: baseURL.path)

        for path in contents {
            print(path)
            let url = baseURL.appendingPathComponent(path)
            try FileManager.default.removeItem(at: url)
        }
    }

    func archive(
        _ directory: String = "",
        to archive: String = "archive.zip"
    ) -> URL? {
        var result: URL?
        var error: NSError?

        let sourceURL = baseURL.appendingPathComponent(directory)

        NSFileCoordinator().coordinate(
            readingItemAt: sourceURL,
            options: [.forUploading],
            error: &error
        ) {
            result = try? moveToTemp($0)
        }

        func moveToTemp(_ archiveURL: URL) throws -> URL {
            let tempURL = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: archiveURL,
                create: true
            ).appendingPathComponent(archive)
            try FileManager.default.moveItem(at: archiveURL, to: tempURL)
            return tempURL
        }

        return result
    }
}

extension URL {
    var isExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
