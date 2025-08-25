import RealtimeKit
import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var initButton: UIButton!
    private var rtkClient: RealtimeKitClient?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func goToMeetingRoom(authToken: String) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let meetingVC = storyBoard.instantiateViewController(withIdentifier: "MeetingRoom") as! MeetingRoomViewController

        let meetingInfo = RtkMeetingInfo(
            authToken: authToken, enableAudio: true,
            enableVideo: true, baseDomain: MeetingConfig.BASE_URL
        )
        meetingVC.meetingInfo = meetingInfo
        present(meetingVC, animated: true, completion: nil)
    }

    @IBAction func initMeeting(_: Any) {
        goToMeetingRoom(authToken: MeetingConfig.AUTH_TOKEN)
    }
}
