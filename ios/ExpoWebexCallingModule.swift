import ExpoModulesCore
import Foundation
import AVFoundation
import React
import WebexSDK
import os

enum EventTypes: String, CaseIterable {
    case onChange="onChange"
    case onLogin="onLogin"
    case onCallIncoming="onCallIncoming"
    case onCallParticipantsChange="onCallParticipantsChange"
    case OnCallStatusChange="OnCallStatusChange"
}

internal class WebexCallAnswerException: GenericException<String> {
    override var reason: String {
        "Failed to answer call. \(param)"
    }
}

internal class WebexAuthenticatorInitializationException: Exception {
    override var reason: String {
        "Webex authenticator failed to initialized."
    }
}

internal class WebexAuthenticationLoggedInException: Exception {
    override var reason: String {
        "Already logged in."
    }
}

internal class WebexAuthenticationException: GenericException<String> {
    override var reason: String {
        "Authentication failed with message: \(param)"
    }
}


public class ExpoWebexCallingModule: Module {
    private var webex: Webex!
    private var isLoggedIn = false
    private var activeCall: Call? = nil
    private var callingViewRef: ExpoWebexCallingView? = nil
    
    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    public func definition() -> ModuleDefinition {
        Name("ExpoWebexCalling")
        
        // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
        Constants([
            "PI": Double.pi
        ])
        
        // Defines event names that the module can send to JavaScript.
        Events(EventTypes.onChange.rawValue, EventTypes.onLogin.rawValue, EventTypes.onCallIncoming.rawValue, EventTypes.onCallParticipantsChange.rawValue, EventTypes.OnCallStatusChange.rawValue)
        
        // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
        Function("hello") {
            return "Hello world! 👋👋"
        }
        
        // Defines a JavaScript function that always returns a Promise and whose native code
        // is by default dispatched on the different thread than the JavaScript runtime runs on.
        AsyncFunction("setValueAsync") { (value: String) in
            // Send an event to JavaScript.
            self.sendEvent("onChange", [
                "value": value
            ])
        }
        
        
        AsyncFunction("initWebex") { (promise: Promise) in
            DispatchQueue.main.sync {
                NSLog("dLog: initializing webex")
                self.isLoggedIn = false
                self.activeCall = nil
                let authenticator = TokenAuthenticator()
                
                self.webex = Webex(authenticator: authenticator)
                self.webex.enableConsoleLogger = false
                //                self.webex.logLevel = .error // .verbose or .error
                
                self.webex.initialize { isLoggedIn in
                    print("dLog: webex initialized successfully. isLoggedIn: \(isLoggedIn)")
                    self.isLoggedIn = isLoggedIn
                    
                    if isLoggedIn {
                        self.sendIsLoggedInEvent()
                        self.setIncomingCallListener()
                    }
                    
                    promise.resolve(isLoggedIn)
                }
            }
        }
        
        
        AsyncFunction("authenticate") { (accessToken: String, promise: Promise) in
            print("dLog: Authenticate called with access token: \(accessToken)")
            
            if(self.isLoggedIn) {
                NSLog("dLog: authenticate called on a logged in user")
                self.sendIsLoggedInEvent()
                self.setIncomingCallListener()
                promise.resolve(true)
                return
            }
            
            guard let authenticator = self.webex.authenticator as? TokenAuthenticator else {
                print("dLog: Unable to access Webex Authenticator.")
                promise.reject(WebexAuthenticatorInitializationException())
                return
            }
            
            print("dLog: authorized: \(authenticator.authorized)")
            
            authenticator.authorizedWith(accessToken: accessToken, expiryInSeconds: nil, completionHandler: { result in
                print("dLog: authorize result = \(result)")
                
                if(result == .success) {
                    print("dLog: authenticate - 3")
                    self.isLoggedIn = true
                    self.sendIsLoggedInEvent()
                    self.setIncomingCallListener()
                    promise.resolve(true)
                } else {
                    print("dLog: authenticate - 4")
                    self.isLoggedIn = false
                    self.sendIsLoggedInEvent()
                    promise.reject(WebexAuthenticationException(String(describing: result)))
                }
            })
            
        }
        
        
        
        AsyncFunction("answerCall") { (promise: Promise) in
            NSLog("dLog: answerCall")
            
            guard let call = self.activeCall else {
                print("dLog: CallManager.answer - call not found. (dError)")
                promise.reject(WebexCallAnswerException("Active call not found."))
                return
            }
            
            AVCaptureDevice.requestAccess(for: .audio) { audioRequestResponse in
                if audioRequestResponse == false {
                    promise.reject(WebexCallAnswerException("Audio permission denied."))
                    return
                }
                
                AVCaptureDevice.requestAccess(for: .video) { videoRequestResponse in
                    if videoRequestResponse == false {
                        promise.reject(WebexCallAnswerException("Video permission denied."))
                        return
                    }
                    
                    let mediaOption = self.getMediaOption(isModerator: false, pin: nil)
                    self.callingViewRef?.connectToCall()
                    call.answer(option: mediaOption, completionHandler: { error in
                        if error == nil {
                            self.updatePhoneSettings()
                            self.emitCallEvents()
                            
                            promise.resolve(true)
                        } else {
                            promise.reject(WebexCallAnswerException(error?.localizedDescription ?? "Unknown error"))
                        }
                    })
                }
            }
            
        }
        
        AsyncFunction("asyncFunction") { (message: String, promise: Promise) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                promise.resolve(message)
            }
        }
        
        // Enables the module to be used as a view manager. The view manager definition is built from
        // the definition components used in the closure passed to viewManager.
        // Definition components that are accepted as part of the view manager definition: `View`, `Prop`.
        ViewManager {
            // Defines the factory creating a native view when the module is used as a view.
            View {
                let view = ExpoWebexCallingView()
                view.webex = self.webex
                view.activeCall = self.activeCall
                
                self.callingViewRef = view
                
                return view
            }
            
            // Defines a setter for the `name` prop.
            Prop("name") { (view: ExpoWebexCallingView, prop: String) in
                view.name = prop
            }
        }
    }
}

extension ExpoWebexCallingModule {
    func setIncomingCallListener() {
        print("dLog: CallManager.setIncomingCallListener -> listening for incoming calls.")
        
        self.webex.phone.onIncoming = { call in
            print("dLog: CallManager.setIncomingCallListener -> Incoming call received!!!")
            // TODO: Implement call hold logic.
            //            if(self.activeCall == nil) {
            self.activeCall = call
            self.emitCallMembership()
            self.emitCallEvents()
            //            }
            
            self.sendEvent(EventTypes.onCallIncoming.rawValue, [
                "callId": call.callId
            ])
            
        }
    }
    
    func emitCallEvents() {
        guard let call = self.activeCall else {
            print("dLog: emitCallEvents no active call.")
            return
        }
        
        call.onRinging = {
            print("dLog: call.onRinging called!")
            
            self.sendCallStatusChange(status: "ringing")
        }
        
        call.onConnected = {
            print("dLog: call.onConnected (CallManager)")
            
            self.sendCallStatusChange(status: "connected")
            self.callingViewRef?.connectToCall()
        }
        
        call.onDisconnected = { reason in
            print("dLog: call.onDisconnected \(reason)")
            
            self.sendCallStatusChange(status: "disconnected")
            self.activeCall = nil
        }
        
        call.onCallMembershipChanged = { membershipChangeType in
            print("dLog: call.onCallMembershipChanged \(membershipChangeType)")
            
            self.sendCallStatusChange(status: "participants-changed")
            self.emitCallMembership();
        }
        
        call.onFailed = { reason in
            print("dLog: call.onFailed.")
            
            self.sendCallStatusChange(status: "failed")
            self.activeCall = nil
        }
    }
    
    func getMediaOption(isModerator: Bool, pin: String?) -> MediaOption {
        var mediaOption = MediaOption.audioVideo()
        
        mediaOption.moderator = isModerator
        mediaOption.pin = pin
        mediaOption.compositedVideoLayout = .grid
        
        return mediaOption
    }
    
    
    func emitCallMembership() {
        guard let call = self.activeCall else {
            print("dLog: emitCallMembership no call.")
            return
        }
        
        var memberships: [[String: Any]] = []
        for membership in call.memberships {
            memberships.append(["displayName": membership.displayName!, "personId": membership.personId!, "state": membership.state, "isSelf": membership.isSelf])
        }
        
        print ("dLog: memberships: \(memberships)")
        
        self.sendEvent(EventTypes.onCallParticipantsChange.rawValue, [
            "memberships": memberships
        ])
    }
    
    func sendIsLoggedInEvent() {
        self.sendEvent(EventTypes.onLogin.rawValue, [
            "isLoggedIn": self.isLoggedIn
        ])
    }
    
    func sendCallStatusChange(status: String) {
        self.sendEvent(EventTypes.OnCallStatusChange.rawValue, [
            "status": status
        ])
    }
    
    
    func updatePhoneSettings() {
        guard let webex = self.webex else {return}
        
        webex.phone.videoStreamMode = .auxiliary
        webex.phone.audioBNREnabled = true
        webex.phone.audioBNRMode = .LP
        webex.phone.defaultFacingMode = .user
        webex.phone.videoMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue
        webex.phone.videoMaxTxBandwidth = Phone.DefaultBandwidth.maxBandwidth1080p.rawValue
        webex.phone.sharingMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthSession.rawValue
        webex.phone.audioMaxRxBandwidth = Phone.DefaultBandwidth.maxBandwidthAudio.rawValue
        webex.phone.enableBackgroundConnection = true
        webex.phone.defaultLoudSpeaker = true
        
        
        var advancedSettings: [Phone.AdvancedSettings] = []
        let videoMosaic = Phone.AdvancedSettings.videoEnableDecoderMosaic(true)
        let videoMaxFPS = Phone.AdvancedSettings.videoMaxTxFPS(30)
        advancedSettings.append(videoMosaic)
        advancedSettings.append(videoMaxFPS)
        webex.phone.advancedSettings = advancedSettings
    }
}
