import Foundation

actor PersistenceStore {
    static let shared = PersistenceStore()

    // MARK: - iCloud URL resolution with local fallback

    private func containerURL() -> URL? {
        FileManager.default
            .url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents", isDirectory: true)
    }

    private func localURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func resolvedURL(for filename: String) -> URL {
        let base: URL
        if let icloud = containerURL() {
            // Ensure the iCloud Documents directory exists
            try? FileManager.default.createDirectory(at: icloud, withIntermediateDirectories: true)
            base = icloud
        } else {
            base = localURL()
        }
        return base.appendingPathComponent(filename)
    }

    // MARK: - Read / Write

    func save<T: Encodable>(_ value: T, to filename: String) throws {
        let url = resolvedURL(for: filename)
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomicWrite)
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = resolvedURL(for: filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}
