//
//  AppDelegate.swift
//  DyteCoreExample
//
//  Created by Shaunak Jagtap on 10/01/23.
//

import PushKit
import UIKit
import DyteiOSCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var window: UIWindow?
    var callManager: CallManager!
    var dyteClient: DyteClient!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        callManager = CallManager()
        
        let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

        return true
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // Send the push credentials to your server
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        let uuid = UUID()
        let handle = "caller_handle" // Extract this from payload
        
        callManager.reportIncomingCall(uuid: uuid, handle: handle) { error in
            if error == nil {
                self.dyteClient.joinMeeting { result, error in
                    if let e = error {
                        print("Error: \(e.message)")
                    } else {
                        completion()
                    }
                }
            }
            completion()
        }
    }
}
