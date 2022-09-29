import ExpoModulesCore
import UIKit
import WebexSDK
import AVFoundation

class ExpoWebexCallingView: ExpoView, MultiStreamObserver {
    public var webex: Webex!
    public var activeCall: Call? = nil
    public var name: String?
    
    /// onAuxStreamChanged represent a call back when a existing auxiliary stream status changed.
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)?
    
    /// onAuxStreamAvailable represent the call back when current call have a new auxiliary stream.
    var onAuxStreamAvailable: (() -> MediaRenderView?)?
    
    /// onAuxStreamUnavailable represent the call back when current call have an existing auxiliary stream being unavailable.
    var onAuxStreamUnavailable: (() -> MediaRenderView?)?
    
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
        label.textColor = .black
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
        self.handleWebexCallEvents()
    }
    
    func disconnectFromCall() {
        guard let call = self.activeCall else {
            fatalError("disconnectFromCall: Call does not exist..")
        }
        
    }
}


extension ExpoWebexCallingView {
    private func syncInternalStateWithCall() {
        guard let call = self.activeCall else {
            fatalError("Unable to update internal call state. Active call was not found.")
        }
        
        //    CallManager.renderMode = call.remoteVideoRenderMode
        //    CallManager.compositedLayout = call.compositedVideoLayout ?? .single
        //    CallManager.isLocalAudioMuted = !call.sendingAudio
        //    CallManager.isLocalVideoMuted = !call.sendingVideo
        //    CallManager.isLocalScreenSharing = call.sendingScreenShare
        //    CallManager.isReceivingAudio = call.receivingAudio
        //    CallManager.isReceivingVideo = call.receivingVideo
        //    CallManager.isReceivingScreenshare = call.receivingScreenShare
        //    CallManager.isFrontCamera = call.facingMode == .user ? true : false
    }
    
    func handleWebexCallEvents() {
        guard let call = self.activeCall else {
            fatalError("Unable to handle webex call events. Active call was not found.")
        }
        
        print("dLog: Call Status: \(call.status)")
        
        call.onConnected = {
            print("dLog: CallViewController:call.onConnected called")
            
            self.syncInternalStateWithCall()
            call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
        }
        
        
        call.onMediaChanged = { [weak self] mediaEvents in
            print("dLog: onMediaChanged Call, events: \(mediaEvents)")
            
            if let self = self {
                self.syncInternalStateWithCall()
                
                switch mediaEvents {
                    /* Local/Remote video rendering view size has changed */
                case .localVideoViewSize, .remoteVideoViewSize, .remoteScreenShareViewSize, .localScreenShareViewSize:
                    break
                    
                    /* This might be triggered when the remote party muted or unmuted the audio. */
                case .remoteSendingAudio(let isSending):
                    print("dLog: Remote is sending Audio- \(isSending)")
                    
                    /* This might be triggered when the remote party muted or unmuted the video. */
                case .remoteSendingVideo(let isSending):
                    print("dLog: call onMediaChanged: remoteSendingVideo isSending: \(isSending)")
                    self.remoteVideoView.alpha = isSending ? 1 : 0
                    
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    break
                    
                    /* This might be triggered when the local party muted or unmuted the audio. */
                case .sendingAudio(let isSending):
                    print("dLog: CallViewController:call.sendingAudio \(isSending)")
                    //          CallManager.isLocalAudioMuted = !isSending
                    break
                    
                    /* This might be triggered when the local party muted or unmuted the video. */
                case .sendingVideo(let isSending):
                    print("dLog: call.sendingVideo \(isSending) @!@!@!@!@!@!@!@!@!@!@!@!")
                    
                    //          CallManager.isLocalVideoMuted = !isSending
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                        self.selfVideoView.alpha = 1
                    } else {
                        self.selfVideoView.alpha = 0
                    }
                    break
                case .receivingAudio(let isReceiving):
                    print("Remote is receiving Audio- \(isReceiving)")
                    
                case .receivingVideo(let isSending):
                    print("dLog: CallViewController: .receivingVideo \(isSending)")
                    if isSending {
                        self.remoteVideoView.alpha = 1
                    } else {
                        self.remoteVideoView.alpha = 0
                    }
                    
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    break
                    
                    /* Camera FacingMode on local device has switched. */
                case .cameraSwitched:
                    //          CallManager.isFrontCamera.toggle()
                    break
                    
                    
                    /* Whether Screen share is blocked by local*/
                case .receivingScreenShare(let isReceiving):
                    print("dLog: receiving screen share: \(isReceiving)")
                    
                    /* Whether Remote began to send Screen share */
                case .remoteSendingScreenShare(let remoteSending):
                    print("dLog: remoteSendingScreenShare: \(remoteSending)")
                    
                    
                    /* Whether local began to send Screen share */
                case .sendingScreenShare(let startedSending):
                    print("dLog sendingScreenShare \(startedSending)")
                    
                    /* This might be triggered when the remote video's speaker has changed.
                     */
                case .activeSpeakerChangedEvent(let from, let to):
                    print("Active speaker changed from \(String(describing: from)) to \(String(describing: to))")
                    
                default:
                    break
                }
            }
        }
        
        call.onFailed = { reason in
            print("dLog: Call Failed!")
            // self.player.stop()
        }
        
        call.onWaiting = { reason in
            print("dLog: CallViewController:call.onWaiting \(reason)")
        }
        
        call.onInfoChanged = {
            print("dLog: CallViewController:call.onInfoChanged isOnHold: \(call.isOnHold)")
            
            call.videoRenderViews?.local.isHidden = call.isOnHold
            call.videoRenderViews?.remote.isHidden = call.isOnHold
            call.screenShareRenderView?.isHidden = call.isOnHold
            self.selfVideoView.isHidden = call.isOnHold
            self.remoteVideoView.isHidden = call.isOnHold
        }
        
        /* set the observer of this call to get multi stream event */
        call.multiStreamObserver = self
        
        
        /* Callback when an existing multi stream media being unavailable. The SDK will close the last auxiliary stream if you don't return the specified view*/
        self.onAuxStreamUnavailable = {
            return nil
        }
        
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
