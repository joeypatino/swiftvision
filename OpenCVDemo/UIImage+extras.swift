import UIKit

public extension UIImage {
    public func normalizedImage() -> UIImage {
        guard imageOrientation != .up else {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale);
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        draw(in: rect)

        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage;
    }
}
