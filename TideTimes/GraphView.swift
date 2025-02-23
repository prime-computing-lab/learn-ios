import SwiftUI

struct GraphView: View {
    let tideData: NetworkManager.TideData
    let currentTime: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private func normalizedHeight(_ height: Double) -> Double {
        let heights = tideData.heights.map(\.height)
        let minHeight = heights.min() ?? 0
        let maxHeight = heights.max() ?? 1
        return (height - minHeight) / (maxHeight - minHeight)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw the tide curve
                Path { path in
                    let points = tideData.heights.enumerated().map { index, height in
                        CGPoint(
                            x: CGFloat(index) / CGFloat(tideData.heights.count - 1) * geometry.size.width,
                            y: geometry.size.height * (1 - CGFloat(normalizedHeight(height.height)))
                        )
                    }
                    
                    path.move(to: points[0])
                    for index in 1..<points.count {
                        let control1 = CGPoint(
                            x: points[index-1].x + (points[index].x - points[index-1].x) / 3,
                            y: points[index-1].y
                        )
                        let control2 = CGPoint(
                            x: points[index].x - (points[index].x - points[index-1].x) / 3,
                            y: points[index].y
                        )
                        path.addCurve(to: points[index], control1: control1, control2: control2)
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                // Draw current time indicator
                if let currentPoint = getCurrentPoint(in: geometry) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .position(currentPoint)
                }
            }
        }
        .frame(height: 200)
    }
    
    private func getCurrentPoint(in geometry: GeometryProxy) -> CGPoint? {
        let currentTimeInterval = currentTime.timeIntervalSince1970
        guard let index = tideData.heights.firstIndex(where: { $0.dt >= currentTimeInterval }) else {
            return nil
        }
        
        let x = CGFloat(index) / CGFloat(tideData.heights.count - 1) * geometry.size.width
        let height = tideData.heights[index].height
        let y = geometry.size.height * (1 - CGFloat(normalizedHeight(height)))
        
        return CGPoint(x: x, y: y)
    }
} 