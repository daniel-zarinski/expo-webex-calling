import ExpoModulesCore
import UIKit
import WebexSDK

class ExpoWebexCallingView: ExpoView {
    public var webex: Webex!
    public var activeCall: Call? = nil
    public var name: String?
    
    required init?(coder: NSCoder) {
        fatalError("init with coder not implemented.")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.callingLabel)
        self.addSubview(self.selfVideoView)
        self.addSubview(self.callingLabel)
        
        selfVideoView.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -120).isActive = true
        selfVideoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 70).isActive = true
        
        
        self.callingLabel.alignCenter()
    }
    
    lazy var selfVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setSize(width: 100, height: 180)
        view.flipX()
        
        view.alpha = 1
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.layer.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleSelfViewGesture)))
        
        return view
    }()
    
    lazy var remoteVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.alpha = 1
        
        return view
    }()
    
    lazy var callingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.accessibilityIdentifier = "callLabel"
        label.textColor = .white
        label.textAlignment = .center
        label.text = "No video"
        label.isHidden = false
        
        return label
    }()
    
    @objc func handleSelfViewGesture(gesture: UIPanGestureRecognizer){
        let location = gesture.location(in: self)
        let draggedView = gesture.view
        draggedView?.center = location
        
        let verticalBound = self.layer.frame.height / 4
        let selfViewHeight = self.selfVideoView.frame.height - 20
        
        if gesture.state == .ended {
            if self.selfVideoView.frame.midY >= verticalBound {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = verticalBound
                }, completion: nil)
            }
            
            if self.selfVideoView.frame.midY <= selfViewHeight {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = selfViewHeight
                }, completion: nil)
            }
            
            if self.selfVideoView.frame.midY >= verticalBound {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = verticalBound
                }, completion: nil)
            }
            
            
            if self.selfVideoView.frame.midX >= self.layer.frame.width / 2 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.x = self.layer.frame.width - 60
                }, completion: nil)
            }else{
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.x = 60
                }, completion: nil)
            }
        }
    }
    
}

extension ExpoWebexCallingView {
    func connectToCall() {
        guard let call = self.activeCall else {
            fatalError("Call does not exist..")
            return
        }
        
        print("dLog: CallViewController.connectToCall with callId: \(call.callId)")
        print("dLog: CallViewController.connectToCall call.spaceId: \(String(describing: call.spaceId))")
        
        print("dLog: connectToCall - isSendingVideo: \(call.sendingVideo)")
        
        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
        self.selfVideoView.alpha = 1
        self.callingLabel.text = "active call"
    }
}



extension UIView {
    func fillSuperView(padded: CGFloat = 0) {
        guard let superview = superview else { fatalError("View doesn't have a superview") }
        fill(view: superview, padded: padded)
    }
    
    func fillWidth(of view: UIView, padded: CGFloat = 0) {
        leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padded).isActive = true
        trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padded).isActive = true
    }
    
    func fillHeight(of view: UIView, padded: CGFloat = 0) {
        topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padded).isActive = true
        bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padded).isActive = true
    }
    
    func fill(view: UIView, padded: CGFloat = 0) {
        fillWidth(of: view, padded: padded)
        fillHeight(of: view, padded: padded)
    }
    
    func alignCenter(in view: UIView? = nil) {
        guard let viewB = view ?? superview else { fatalError("No View to anchor") }
        centerXAnchor.constraint(equalTo: viewB.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: viewB.centerYAnchor).isActive = true
    }
    
    func setWidth(_ width: CGFloat) {
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func setHeight(_ height: CGFloat) {
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    
    func setSize(width: CGFloat, height: CGFloat) {
        setWidth(width)
        setHeight(height)
    }
    
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }
    
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
}
