import UIKit

extension AuroraCoreBridge {
    func currentFrameImage() -> UIImage? {
        guard let spec = getVideoSpec(), let buffer = getFrameBuffer() else { return nil }
        let width = Int(spec.width)
        let height = Int(spec.height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        guard let context = CGContext(data: UnsafeMutableRawPointer(mutating: buffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: width * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
