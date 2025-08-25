import PushKit
import RealtimeKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var window: UIWindow?
    var callManager: CallManager!
    var meeting: RealtimeKitClient!

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
                self.meeting.joinRoom {
                    completion()
                } onFailure: { error in
                    print("Error: \(error.message)")
                }
            }
            completion()
        }
    }
}
