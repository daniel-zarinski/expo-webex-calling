//import ExpoModulesCore
//import Foundation
//import React
//import os
//import AVFoundation
//import WebexSDK
//
//internal class CallManager: NSObject {
//    public static var call:Call? = nil
//    public static var currentCallId: String?
//    public static var isLocalAudioMuted = false
//    public static var isLocalVideoMuted = true
//    public static var isLocalScreenSharing = false
//    public static var isReceivingScreenshare = false
//    public static var isCallControlsHidden = false
//    public static var isReceivingAudio = false
//    public static var isReceivingVideo = false
//    public static var isFrontCamera = true
//    public static var onHold = false
//    public static var renderMode: Call.VideoRenderMode = .fit
//    public static var compositedLayout: MediaOption.CompositedVideoLayout = .single
//    public static var participants: [CallMembership] = []
//    public static var address: String?
//    
//    func dial(_ address: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let webex = WebexManager.webex else {return}
//        print("dLog: attempting to dial \(address)")
//        
//        self.updatePhoneSettings()
//        CallManager.address = address
//        
//        AVCaptureDevice.requestAccess(for: .audio) { audioRequestResponse in
//            if audioRequestResponse == false {
//                reject("event_failure", "Unable to get access to audio device", nil)
//                return
//            }
//            print("dLog: dial: User has audio access.")
//            
//            AVCaptureDevice.requestAccess(for: .video) { videoRequestResponse in
//                if videoRequestResponse == false {
//                    reject("event_failure", "Unable to get access to video device", nil)
//                    return
//                }
//                print("dLog: dial: User has video access.")
//                
//                let mediaOption = self.getMediaOption(isModerator: false, pin: nil)
//                
//                webex.phone.dial(address, option: mediaOption, completionHandler: { result in
//                    switch result {
//                    case .success(let call):
//                        print("dLog: dial was successful!")
//                        print("dLog: call memberships: \(call.memberships)")
//                        
//                        CallManager.call = call
//                        CallManager.currentCallId = call.callId
//                        CallManager.handleCallEvents()
//                        CallManager.emitCallMembership()
//                        
//                        resolve(true)
//                    case .failure(let error):
//                        print("dLog: call failure \(error.localizedDescription)")
//                        print(error)
//                        CallManager.call = nil
//                        reject("event_failure", error.localizedDescription, nil)
//                    @unknown default:
//                        print("dLog: an unexpected error occurred.")
//                        CallManager.call = nil
//                        reject("event_failure", "Failed to dial, unexpected error occured.", nil)
//                    }
//                })
//            }
//        }
//    }
//    
//    @objc func hangup(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let call = CallManager.call else {
//            print("dLog: CallViewController - handleEndCallAction - call not found. (dError)")
//            reject("event_error", "no call in progress.", nil)
//            return
//        }
//        print("dLog: hangup called. Will attempt to hang up now.")
//        
//        call.hangup(completionHandler: { error in
//            if error == nil {
//                NSLog("dLog: handleEndCallAction: call ended.")
//                CallManager.call = nil
//                resolve(true)
//            } else {
//                print("dLog: handleEndCallAction: call failed to end with error. \(String(describing: error))")
//                reject("event_error", error?.localizedDescription, nil)
//            }
//        })
//        
//        call.reject(completionHandler: { error in
//            if error == nil {
//                print("dLog: call rejected successfully. No error")
//            }
//            print("dLog: call.reject error: \(String(describing: error))")
//        })
//    }
//    
//    // Used for incoming calls
//    @objc func answer(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let call = CallManager.call else {
//            print("dLog: CallManager.answer - call not found. (dError)")
//            reject("event_error", "no call in progress.", nil)
//            return
//        }
//        
//        AVCaptureDevice.requestAccess(for: .audio) { audioRequestResponse in
//            if audioRequestResponse == false {
//                reject("event_failure", "Unable to get access to audio device", nil)
//                return
//            }
//            
//            AVCaptureDevice.requestAccess(for: .video) { videoRequestResponse in
//                if videoRequestResponse == false {
//                    reject("event_failure", "Unable to get access to video device", nil)
//                    return
//                }
//                
//                let mediaOption = self.getMediaOption(isModerator: false, pin: nil)
//                call.answer(option: mediaOption, completionHandler: { error in
//                    if error == nil {
//                        self.updatePhoneSettings()
//                        self.isCUCMCall = call.isCUCMCall
//                        
//                        CallManager.currentCallId = call.callId
//                        CallManager.handleCallEvents()
//                        CallManager.emitCallMembership()
//                        
//                        resolve(true)
//                    } else {
//                        reject("event_failure", error?.localizedDescription, nil)
//                    }
//                })
//                
//            }
//        }
//    }
//    
//    @objc func toggleSelfAudio(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let call = CallManager.call else { return }
//        
//        CallManager.isLocalAudioMuted.toggle()
//        call.sendingAudio = !CallManager.isLocalAudioMuted
//        
//        resolve(CallManager.isLocalAudioMuted)
//    }
//    
//    @objc func toggleSelfVideo(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let call = CallManager.call else { return }
//        
//        AVCaptureDevice.requestAccess(for: .video) { videoRequestResponse in
//            if !videoRequestResponse {
//                reject("promise_error", "Unable to access local video.", nil)
//                return
//            }
//            
//            CallManager.isLocalVideoMuted.toggle()
//            call.sendingVideo = !CallManager.isLocalVideoMuted
//            
//            print("dLog: CallManager.toggleSelfVideo: sendingVideo: \(call.sendingVideo) \(CallManager.isLocalVideoMuted)")
//            
//            resolve(CallManager.isLocalVideoMuted)
//        }
//    }
//    
//    @objc func toggleSelfVideoDirection(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
//        guard let call = CallManager.call else { return }
//        print("dLog: toggleSelfVideoDirection. Initial CallManager.isFrontCamera=\(CallManager.isFrontCamera)")
//        
//        CallManager.isFrontCamera.toggle()
//        
//        print("dLog: Changed CallManager.isFrontCamera=\(CallManager.isFrontCamera)")
//        call.facingMode = CallManager.isFrontCamera ? .user : .environment
//        resolve(CallManager.isFrontCamera)
//    }
//}
//
//extension CallManager {
//    func getMediaOption(isModerator: Bool, pin: String?) -> MediaOption {
//        var mediaOption = MediaOption.audioVideo()
//        
//        mediaOption.moderator = isModerator
//        mediaOption.pin = pin
//        mediaOption.compositedVideoLayout = .grid
//        
//        return mediaOption
//    }
//    
//    func updatePhoneSettings() {
//        guard let webex = WebexManager.webex else {return}
//        
//        webex.phone.videoStreamMode = .auxiliary
//        webex.phone.audioBNREnabled = true
//        webex.phone.audioBNRMode = .LP
//        webex.phone.defaultFacingMode = .user
//        webex.phone.videoMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue
//        webex.phone.videoMaxTxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue
//        webex.phone.sharingMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthSession.rawValue
//        webex.phone.audioMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthAudio.rawValue
//        webex.phone.enableBackgroundConnection = true
//        webex.phone.defaultLoudSpeaker = true
//        
//        
//        var advancedSettings: [Phone.AdvancedSettings] = []
//        let videoMosaic = Phone.AdvancedSettings.videoEnableDecoderMosaic(true)
//        let videoMaxFPS = Phone.AdvancedSettings.videoMaxTxFPS(30)
//        advancedSettings.append(videoMosaic)
//        advancedSettings.append(videoMaxFPS)
//        webex.phone.advancedSettings = advancedSettings
//    }
//    
//    
//    static func handleCallEvents() {
//        guard let call = CallManager.call else {return}
//        print("dLog: handleCallEvents running with a call.")
//        
//        call.onRinging = {
//            print("dLog: call.onRinging called!")
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onRinging.rawValue, body: [])
//            CallManager.emitCallMembership()
//        }
//        
//        call.onConnected = {
//            print("dLog: call.onConnected (CallManager)")
//            
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onConnected.rawValue, body: [])
//        }
//        
//        call.onCapabilitiesChanged = { result in
//            print("dLog: call capabilities changed: \(result)")
//        }
//        
//        call.onDisconnected = { reason in
//            print("dLog: call.onDisconnected \(reason)")
//            CallManager.call = nil
//            CallManager.currentCallId = nil
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onDisconnected.rawValue, body: ["reason" : String(describing: reason)])
//        }
//        
//        call.onCallMembershipChanged = { membershipChangeType in
//            print("dLog: call.onCallMembershipChanged \(membershipChangeType)")
//            
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onCallMembershipChanged.rawValue, body: ["membershipChangeType" : membershipChangeType])
//            CallManager.emitCallMembership()
//        }
//        
//        call.onFailed = { reason in
//            print("dLog: call.onFailed.");
//            CallManager.call = nil
//            CallManager.currentCallId = nil
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onDisconnected.rawValue, body: ["reason" : "failed"])
//        }
//    }
//    
//    static func emitCallMembership() {
//        guard let call = CallManager.call else {
//            print("dLog: emitCallMembership no call.")
//            return
//        }
//        
//        var memberships: [[String: Any]] = []
//        for membership in call.memberships {
//            print(membership)
//            
//            memberships.append(["displayName": membership.displayName!, "personId": membership.personId!, "state": membership.state, "isSelf": membership.isSelf])
//        }
//        
//        print ("dLog: memberships: \(memberships)")
//        
//        CallEventEmitter.emitter.sendEvent(withName: CallEventType.onCallMembershipChanged.rawValue, body: ["membershipChangeType" : "", "memberships": memberships])
//    }
//    
//    static func requiresMainQueueSetup() -> Bool {
//        return true
//    }
//    
//    static func setIncomingCallListener() {
//        guard let webex = WebexManager.webex else {return}
//        print("dLog: CallManager.setIncomingCallListener -> listening for incoming calls.")
//        
//        webex.phone.onIncoming = { call in
//            print("dLog: CallManager.setIncomingCallListener -> Incoming call received!!!")
//            CallManager.call = call
//            CallManager.currentCallId = call.callId
//            CallManager.handleCallEvents()
//            
//            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onIncomingCall.rawValue, body: ["callId": call.callId])
//            CallManager.emitCallMembership()
//        }
//    }
//}
//
