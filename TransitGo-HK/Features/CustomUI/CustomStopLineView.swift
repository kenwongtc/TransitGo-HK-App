//
//  CustomStopLineView.swift
//  TransitGo-HK
//
//  Created by Ken on 22/8/2026.
//

import SwiftUI

struct CustomStopLineView: View {

    let sequence: Int
    let isFirst: Bool
    let isLast: Bool

    init(
        sequence: Int,
        isFirst: Bool = false,
        isLast: Bool = false
    ) {
        self.sequence = sequence
        self.isFirst = isFirst
        self.isLast = isLast
    }

    var body: some View {

        HStack(spacing: 8) {

            Text("\(sequence)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(
                    width: 24,
                    alignment: .trailing
                )

            GeometryReader { geometry in

                let centerX =
                    geometry.size.width / 2

                let centerY =
                    geometry.size.height / 2

                Path { path in

                    if !isFirst {
                        path.move(
                            to: CGPoint(
                                x: centerX,
                                y: 0
                            )
                        )
                        path.addLine(
                            to: CGPoint(
                                x: centerX,
                                y: centerY
                            )
                        )
                    }

                    if !isLast {
                        path.move(
                            to: CGPoint(
                                x: centerX,
                                y: centerY
                            )
                        )
                        path.addLine(
                            to: CGPoint(
                                x: centerX,
                                y: geometry.size.height
                            )
                        )
                    }
                }
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )

                Circle()
                    .fill(.background)
                    .stroke(
                        Color.accentColor,
                        lineWidth: 3
                    )
                    .frame(
                        width: 12,
                        height: 12
                    )
                    .position(
                        x: centerX,
                        y: centerY
                    )
            }
            .frame(width: 16)
        }
        .frame(
            width: 48,
            alignment: .leading
        )
        .frame(maxHeight: .infinity)
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            "Stop \(sequence)"
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        CustomStopLineView(
            sequence: 1,
            isFirst: true
        )
        CustomStopLineView(sequence: 2)
        CustomStopLineView(
            sequence: 3,
            isLast: true
        )
    }
    .frame(height: 180)
    .padding()
}
