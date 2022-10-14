//
//  SlidingBanner.swift
//  SlidingBanner
//
//  Created by Aimar Ugarte on 14/10/22.
//

import UIKit

// MARK: SlidingBannerDelegate
public protocol SlidingBannerDelegate: AnyObject {
    func slideInAnimationFinished()
    func slideOutAnimationFinished()
}

// MARK: Banner starting types
public enum BannerSlideStyle: Int {
    case top = 0
    // TODO: Create new slide styles
    // case botom = 1
    // case topLeft = 2
    // case topRight = 3
    // case left = 4
    // case right = 5
    public init() { self = .top }
}

public class SlidingBanner: UIView {

    // MARK: - Public variables
    public weak var delegate: SlidingBannerDelegate?
    public var slideStyle: BannerSlideStyle = .top
    
    public var bannerHeight = 175.0
    
    public var bannerDuration = 6.0
    public var bannerAnimationIn = 0.6
    public var bannerAnimationOut = 0.3
    
    public var dismissOnOutsidePress = true
    public var dismissOnSwipeUp = true
    public var dismissAfterBannerDuration = true
    public var removeAfterSlideOut = true
    
    public var view: UIView? {
        didSet {
            view?.translatesAutoresizingMaskIntoConstraints = false
            addSubview()
        }
    }

    public init(height: CGFloat) {
        super.init(frame: CGRect(x: .zero,
                                 y: -height,
                                 width: UIScreen.main.bounds.width,
                                 height: height))
        bannerHeight = height
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        bannerHeight = frame.height
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        keyWindow.addSubview(self)
        
        addSubview()
        setSwipeGesture()
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if dismissOnOutsidePress && !bounds.contains(point) {
            dismiss()
        }
        return super.point(inside: point, with: event)
    }
}

// MARK: View Setups
extension SlidingBanner {
    
    private func addSubview() {
        guard let view = view else { return }
        
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setSwipeGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .up
        addGestureRecognizer(swipeGesture)
    }
}

// MARK: Public functions
extension SlidingBanner {
    
    public func showBanner() {
        slideInAnimation()
        
        if dismissAfterBannerDuration {
            // UIView animation delay breaks the interaction with the view
            perform(#selector(dismiss), with: nil, afterDelay: bannerDuration)
        }
    }
    
    public func hideBanner() {
        dismiss()
    }
}

// MARK: Private functions
extension SlidingBanner {
    
    private func calculateAnimationDuration() -> TimeInterval {
        var duration = bannerAnimationOut
        if let presentation = layer.presentation() {
            let currentY = presentation.frame.origin.y
            frame.origin.y = currentY
    
            let safeAreaInsets = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets
            let expectedY = safeAreaInsets?.top ?? 0
            let starting = -bannerHeight
            let totalRange = expectedY - starting
            let completed = currentY - starting
            duration = (completed/totalRange) * bannerAnimationOut
        }
        return TimeInterval(duration)
    }
}

// MARK: Actions
extension SlidingBanner {
    
    @objc private func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard dismissOnSwipeUp else { return }
        dismiss()
    }
    
    @objc private func dismiss() {
        guard superview != nil else { return }
        
        if layer.animationKeys() != nil {
            layer.removeAllAnimations()
        }
        slideOutAnimation()
    }
}

// MARK: Animations
extension SlidingBanner {
    
    private func slideInAnimation() {
        UIView.animate(withDuration: TimeInterval(bannerAnimationIn),
                       delay: .zero,
                       options: .allowUserInteraction,
                       animations: { [weak self] in
            let safeAreaInsets = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets
            self?.frame.origin.y = safeAreaInsets?.top ?? .zero
        }) { [weak self] _ in
            self?.delegate?.slideOutAnimationFinished()
        }
    }
    
    private func slideOutAnimation() {
        UIView.animate(withDuration: calculateAnimationDuration(),
                       delay: .zero,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
            guard let self = self else { return }
            self.frame.origin.y =  -self.bannerHeight
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            if self.removeAfterSlideOut {
                self.removeFromSuperview()
            }
            self.delegate?.slideOutAnimationFinished()
        })
    }
}
