//
//  TrendChart.swift
//  MacServerMonitor
//
//  Lightweight trend chart component
//

import SwiftUI

/// Simple sparkline-style trend chart
struct TrendChart: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let width = geometry.size.width
            let count = data.count

            if count < 2 {
                // Not enough data
                Rectangle()
                    .fill(Color.clear)
            } else {
                let maxVal = data.max() ?? 100
                let minVal = data.min() ?? 0
                let range = maxVal - minVal == 0 ? 1 : maxVal - minVal

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(count - 1)
                        let normalizedValue = (value - minVal) / range
                        let y = height * (1 - normalizedValue)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
        .frame(height: 40)
    }
}

/// Metric card with trend chart
struct MetricCardWithTrend<Content: View>: View {
    let title: String
    let icon: String
    let value: Double
    let unit: String
    let trendData: [Double]
    let isAlerting: Bool
    let content: Content

    init(title: String, icon: String, value: Double, unit: String, trendData: [Double], isAlerting: Bool, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.value = value
        self.unit = unit
        self.trendData = trendData
        self.isAlerting = isAlerting
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(isAlerting ? .red : .blue)
                .frame(width: 60)

            Divider()

            // Value and trend
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", value))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(isAlerting ? .red : .primary)

                        Text(unit)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    // Trend chart
                    if trendData.count >= 2 {
                        TrendChart(data: trendData, color: isAlerting ? .red : .blue)
                            .frame(width: 100)
                    }
                }

                // Additional content
                content
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAlerting ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        TrendChart(data: [10, 20, 15, 30, 25, 40, 35, 50], color: .blue)
            .frame(width: 200, height: 60)

        TrendChart(data: [80, 75, 85, 70, 90], color: .red)
            .frame(width: 200, height: 60)
    }
    .padding()
}
