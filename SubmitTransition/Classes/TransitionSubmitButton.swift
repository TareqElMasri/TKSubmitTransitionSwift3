import Foundation
import UIKit

@IBDesignable
open class TKTransitionSubmitButton : UIButton, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    lazy var spiner: SpinerLayer! = {
        let s = SpinerLayer(frame: self.frame)
        self.layer.addSublayer(s)
        return s
    }()
    
    @IBInspectable
    open var spinnerColor: UIColor = UIColor.white {
        didSet {
            spiner.spinnerColor = spinnerColor
        }
    }
    
    //Normal state bg and border
    @IBInspectable
    var normalBorderColor: UIColor? {
        didSet {
            layer.borderColor = normalBorderColor?.cgColor
        }
    }
    
    @IBInspectable
    var normalBackgroundColor: UIColor? {
        didSet {
            setBgColorForState(color: normalBackgroundColor, forState: .normal)
        }
    }
    
    
    //Highlighted state bg and border
    @IBInspectable
    var highlightedBorderColor: UIColor?
    
    @IBInspectable
    var highlightedBackgroundColor: UIColor? {
        didSet {
            setBgColorForState(color: highlightedBackgroundColor, forState: .highlighted)
        }
    }
    
    private func setBgColorForState(color: UIColor?, forState: UIControlState) {
        if color != nil {
            setBackgroundImage(UIImage.imageWithColor(color: color!), for: forState)
            
        } else {
            setBackgroundImage(nil, for: forState)
        }
    }
    
    @IBInspectable
    open var normalCornerRadius: CGFloat? = 0.0 {
        didSet {
            self.layer.cornerRadius = normalCornerRadius!
        }
    }
    
    
    open var didEndFinishAnimation : (()->())? = nil
    
    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    let shrinkCurve = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval  = 0.1
    
    var cachedTitle: String?
    
    private var originalWidth: CGFloat?
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if let value = value as? CGFloat?, key == "normalCornerRadius" {
            self.normalCornerRadius = value
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }
    
    func setup() {
        self.clipsToBounds = true
        spiner.spinnerColor = spinnerColor
    }
    
    open func startLoadingAnimation() {
        self.cachedTitle = title(for: UIControlState())
        self.setTitle("", for: UIControlState())
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.layer.cornerRadius = self.frame.height / 2
        }, completion: { (done) -> Void in
            self.shrink()
            _ = Timer.schedule(delay: self.shrinkDuration - 0.25) { _ in
                self.spiner.animation()
            }
        })
    }
    
    open func stopLoadingAnimation(_ delay: TimeInterval, beExpand: Bool = false, completion:(()->())?) {
        _ = Timer.schedule(delay: delay) { _ in
            self.didEndFinishAnimation = completion
            if beExpand { self.expand() } else { self.reset() }
            self.spiner.stopAnimation()
        }
    }
    
    
    open func startFinishAnimation(_ delay: TimeInterval, completion:(()->())?) {
        _ = Timer.schedule(delay: delay) { _ in
            self.didEndFinishAnimation = completion
            self.expand()
            self.spiner.stopAnimation()
        }
    }
    
    open func animate(_ duration: TimeInterval, completion:(()->())?) {
        startLoadingAnimation()
        startFinishAnimation(duration, completion: completion)
    }
    
    open func setOriginalState() {
        self.returnToOriginalState()
        self.spiner.stopAnimation()
    }
    
    open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let a = anim as! CABasicAnimation
        if a.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            _ = Timer.schedule(delay: 1) { _ in
                self.returnToOriginalState()
            }
        }
    }
    
    open func returnToOriginalState() {
        
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, for: UIControlState())
        self.spiner.stopAnimation()
    }
    
    func shrink() {
        self.originalWidth = self.bounds.size.width
        
        CATransaction.begin()
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = kCAFillModeForwards
        shrinkAnim.isRemovedOnCompletion = false
        layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)
        CATransaction.commit()
    }
    
    func reset() {
        CATransaction.begin()
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.fromValue = frame.height
        shrinkAnim.toValue = self.originalWidth
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = kCAFillModeForwards
        shrinkAnim.isRemovedOnCompletion = false
        CATransaction.setCompletionBlock { 
            self.setOriginalState()
            self.didEndFinishAnimation?()
        }
        layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)
        CATransaction.commit()
    }
    
    func expand() {
        CATransaction.begin()
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        expandAnim.fromValue = 1.0
        expandAnim.toValue = 26.0
        expandAnim.timingFunction = expandCurve
        expandAnim.duration = 0.3
        expandAnim.delegate = self
        expandAnim.fillMode = kCAFillModeForwards
        expandAnim.isRemovedOnCompletion = false
        CATransaction.setCompletionBlock {
            self.layer.cornerRadius = self.normalCornerRadius!
        }
        layer.add(expandAnim, forKey: expandAnim.keyPath)
        CATransaction.commit()
    }
    
}
