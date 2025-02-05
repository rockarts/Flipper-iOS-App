import Inject

extension Archive {
    func synchronize() async {
        guard !isSyncronizing else { return }
        do {
            try await archiveSync.run()
            try await favoritesSync.run()
            try await updateFavoriteItems()
        } catch {
            logger.critical("syncronization error: \(error)")
        }
    }

    func updateFavoriteItems() async throws {
        let favorites = try await mobileFavorites.read()
        items = items.map {
            var item = $0
            item.isFavorite = favorites.contains($0.path)
            return item
        }
    }

    func onSyncEvent(_ event: ArchiveSync.Event) {
        Task {
            switch event {
            case .syncing(let path):
                if let index = items.firstIndex(where: { $0.path == path }) {
                    items[index].status = .synchronizing
                }
            case .imported(let path):
                let content = try await mobileArchive.read(path)
                var item = try ArchiveItem(path: path, content: content)
                item.status = .synchronized
                items.removeAll { $0.path == path }
                items.append(item)
            case .exported(let path):
                if let index = items.firstIndex(where: { $0.path == path }) {
                    items[index].status = .synchronized
                }
            case .deleted(let path):
                if let index = items.firstIndex(where: { $0.path == path }) {
                    try await backup(items[index])
                    items.removeAll { $0.path == path }
                }
            }
        }
    }
}
