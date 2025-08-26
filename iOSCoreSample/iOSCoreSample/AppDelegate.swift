import PushKit
import RealtimeKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate {
    var window: UIWindow?
    var meeting: RealtimeKitClient!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

        return true
    }

    func pushRegistry(_: PKPushRegistry, didUpdate _: PKPushCredentials, for _: PKPushType) {
        // Send the push credentials to your server
    }

    func pushRegistry(_: PKPushRegistry, didReceiveIncomingPushWith _: PKPushPayload, for _: PKPushType, completion _: @escaping () -> Void) {}
}
