//
//  AppDelegate.swift
//  DyteCoreExample
//
//  Created by Shaunak Jagtap on 10/01/23.
//

import DyteiOSCore
import PushKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var window: UIWindow?
    var callManager: CallManager!
    var dyteClient: DyteClient!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        callManager = CallManager()

        let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

        return true
    }

    func pushRegistry(_: PKPushRegistry, didUpdate _: PKPushCredentials, for _: PKPushType) {
        // Send the push credentials to your server
    }

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith _: PKPushPayload, for _: PKPushType, completion: @escaping () -> Void) {
        let uuid = UUID()
        let handle = "caller_handle" // Extract this from payload

        callManager.reportIncomingCall(uuid: uuid, handle: handle) { error in
            if error == nil {
                self.dyteClient.joinMeeting { _, error in
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
