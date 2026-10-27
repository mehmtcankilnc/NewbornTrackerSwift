import UIKit

enum PhotoStorageError: Error {
    case unreadableImage
}

/// Keeps milestone photos in a folder inside the app.
/// The database stores only the file name: the folder's full path changes when the app is updated or reinstalled.
struct PhotoStorage {
    let directory: URL

    static let standard = PhotoStorage(
        directory: URL.documentsDirectory.appending(path: "milestone-photos", directoryHint: .isDirectory)
    )

    /// Shrinks the picture so its longest side is at most `maxDimension`, saves it as a JPEG and returns the file name.
    func save(imageData: Data, maxDimension: CGFloat = 1600) throws -> String {
        guard let image = UIImage(data: imageData) else { throw PhotoStorageError.unreadableImage }

        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }

        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else { throw PhotoStorageError.unreadableImage }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = UUID().uuidString + ".jpg"
        try jpeg.write(to: directory.appending(path: fileName))
        return fileName
    }

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    func image(named fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    /// Removes a photo. Does nothing when there is no name or no such file.
    func delete(_ fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}
