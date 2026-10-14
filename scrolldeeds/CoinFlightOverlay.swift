//
//  CoinFlightOverlay.swift
//  scrolldeeds
//
//  Coins earned from a deed arc across the dashboard into the header pill.
//

import SwiftUI

struct CoinFlightOverlay: View {
    let amount: Int
    let target: CGRect
    let onArrive: () -> Void

    @State private var arrived = false

    var body: some View {
        GeometryReader { proxy in
            let origin = proxy.frame(in: .global).origin
            let start = CGPoint(x: proxy.size.width * 0.5, y: proxy.size.height * 0.58)
            let end = resolvedEnd(in: proxy, origin: origin)

            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    FlyingCoin(index: index, start: start, end: end)
                }
                FlyingRewardLabel(amount: amount, start: start, end: end)
            }
        }
        .allowsHitTesting(false)
        .onAppear(perform: scheduleArrival)
    }

    private func resolvedEnd(in proxy: GeometryProxy, origin: CGPoint) -> CGPoint {
        guard target.width > 1, target.height > 1 else {
            return CGPoint(x: proxy.size.width - 54, y: 36)
        }
        return CGPoint(x: target.midX - origin.x, y: target.midY - origin.y)
    }

    private func scheduleArrival() {
        HapticManager.shared.soft()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.86) {
            guard !arrived else { return }
            arrived = true
            onArrive()
        }
    }
}

private struct FlyingCoin: View {
    let index: Int
    let start: CGPoint
    let end: CGPoint

    @State private var travel: CGFloat = 0

    var body: some View {
        let arc = -96 * sin(travel * .pi)
        let spread = CGFloat(index - 2) * 28 * (1 - travel)
        NafsiCoinGlyph(size: 28)
            .scaleEffect(1.05 - 0.42 * travel)
            .opacity(travel > 0.94 ? 0 : 1)
            .position(
                x: start.x + (end.x - start.x) * travel + spread,
                y: start.y + (end.y - start.y) * travel + arc
            )
            .onAppear {
                withAnimation(
                    .timingCurve(0.16, 0.72, 0.22, 1, duration: 0.9)
                    .delay(Double(index) * 0.07)
                ) {
                    travel = 1
                }
            }
    }
}

private struct FlyingRewardLabel: View {
    let amount: Int
    let start: CGPoint
    let end: CGPoint

    @State private var travel: CGFloat = 0

    var body: some View {
        let arc = -70 * sin(travel * .pi)
        Text(String(format: NSLocalizedString("deed.coin_reward", comment: "+%d coins"), amount))
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundColor(Color(red: 0.45, green: 0.30, blue: 0.04))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color(red: 0.99, green: 0.90, blue: 0.55))
            )
            .scaleEffect(1 - 0.35 * travel)
            .opacity(travel > 0.92 ? 0 : 1)
            .position(
                x: start.x + (end.x - start.x) * travel,
                y: start.y + (end.y - start.y) * travel + arc - 18
            )
            .onAppear {
                withAnimation(.timingCurve(0.16, 0.72, 0.22, 1, duration: 0.9).delay(0.12)) {
                    travel = 1
                }
            }
    }
}
