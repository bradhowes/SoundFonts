class FontStateQuery {
  let query = NSMetadataQuery()
  let queue: OperationQueue

  init(queue: OperationQueue = .main) {
    self.queue = queue
  }

  func searchMetadataItems(paths: [URL]) -> AsyncStream<[MetadataItemWrapper]> {
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    query.sortDescriptors = []
    query.predicate = NSPredicate(value: true)
    query.searchItems = paths
    return AsyncStream { continuation in
      NotificationCenter.default.addObserver(
        forName: .NSMetadataQueryDidFinishGathering,
        object: query,
        queue: queue
      ) { _ in
        let result = self.query.results.compactMap { item -> MetadataItemWrapper? in
          guard let metadataItem = item as? NSMetadataItem else {
            return nil
          }
          return MetadataItemWrapper(metadataItem: metadataItem)
        }
        continuation.yield(result)
      }

      NotificationCenter.default.addObserver(
        forName: .NSMetadataQueryDidUpdate,
        object: query,
        queue: queue
      ) { _ in
        let result = self.query.results.compactMap { item -> MetadataItemWrapper? in
          guard let metadataItem = item as? NSMetadataItem else {
            return nil
          }
          return MetadataItemWrapper(metadataItem: metadataItem)
        }
        continuation.yield(result)
      }

      query.start()

      continuation.onTermination = { @Sendable _ in
        self.query.stop()
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidFinishGathering, object: self.query)
        NotificationCenter.default.removeObserver(self, name: .NSMetadataQueryDidUpdate, object: self.query)
      }
    }
  }
}

struct MetadataItemWrapper: Sendable {
  let path: String?
  let isPlaceholder: Bool
  let isDownloading: Bool
  let isUploaded: Bool

  init(metadataItem: NSMetadataItem) {
    path = metadataItem.value(forAttribute: NSMetadataItemPathKey) as? String
    isPlaceholder = metadataItem.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? Bool ?? false

    let downloadStatus = metadataItem.value(forAttribute: NSMetadataUbiquitousItemIsDownloadingKey) as? String
    isDownloading = downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent

    // Check whether the file has been uploaded successfully or saved in the cloud
    let uploaded = metadataItem.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool ?? false
    let uploading = metadataItem.value(forAttribute: NSMetadataUbiquitousItemIsUploadingKey) as? Bool ?? true

    isUploaded = uploaded && !uploading
  }
}
