import AppKit

enum ImageHelper {
    /// Kapak fotoğrafını kaydetmeden önce boyutlandırır (max 400x600px)
    /// Bu sayede büyük TIFF dosyaları SwiftData'yı şişirmez
    static func resizedCoverData(_ image: NSImage, maxWidth: CGFloat = 400, maxHeight: CGFloat = 600) -> Data? {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        // Oranı koru
        let widthRatio  = maxWidth  / originalSize.width
        let heightRatio = maxHeight / originalSize.height
        let ratio = min(widthRatio, heightRatio, 1.0)  // 1.0 = küçük resimleri büyütme

        let newSize = CGSize(
            width:  originalSize.width  * ratio,
            height: originalSize.height * ratio
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: CGRect(origin: .zero, size: newSize),
            from: CGRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()

        guard let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
    }
}
