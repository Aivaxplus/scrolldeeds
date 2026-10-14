//
//  PaywallCloseButton.swift
//  scrolldeeds
//
//  UIKit-based close button - 100% reliable touch handling on real devices.
//  SwiftUI Button can have hit-testing issues on device; UIButton does not.
//

import SwiftUI
import UIKit

/// Expands hit area beyond visual bounds for easier tapping (min 44pt per Apple HIG).
private final class ExpandableHitButton: UIButton {
    private let minHitSize: CGFloat = 44
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let dx = max(0, (minHitSize - bounds.width) / 2)
        let dy = max(0, (minHitSize - bounds.height) / 2)
        let expanded = bounds.insetBy(dx: -dx, dy: -dy)
        return expanded.contains(point)
    }
}

struct PaywallCloseButton: UIViewRepresentable {
    var iconColor: UIColor = UIColor(AppTheme.textMuted)
    var backgroundColor: UIColor = UIColor(AppTheme.cardSecondary)
    let action: () -> Void
    
    init(iconColor: UIColor? = nil, backgroundColor: UIColor? = nil, action: @escaping () -> Void) {
        if let c = iconColor { self.iconColor = c }
        if let c = backgroundColor { self.backgroundColor = c }
        self.action = action
    }
    
    func makeUIView(context: Context) -> UIButton {
        let button = ExpandableHitButton(type: .system)
        button.isUserInteractionEnabled = true
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = iconColor
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 14
        
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.action = action
        uiView.tintColor = iconColor
        uiView.backgroundColor = backgroundColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() {
            HapticManager.shared.soft()
            DispatchQueue.main.async { [weak self] in
                self?.action()
            }
        }
    }
}
