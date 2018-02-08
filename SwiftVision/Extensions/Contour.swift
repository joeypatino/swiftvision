public extension Contour {
    var pointsArray: [CGPoint] {
        return Array(UnsafeBufferPointer(start: points, count: size))
    }
}
