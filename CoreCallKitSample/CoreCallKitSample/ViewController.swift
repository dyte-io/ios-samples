//
//  ViewController.swift
//  DyteCoreExample
//
//  Created by Shaunak Jagtap on 10/01/23.
//

import DyteiOSCore
import UIKit

class ViewController: UIViewController {
    @IBOutlet var initButton: UIButton!
    private var dyteMobileClient: DyteMobileClient?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func goToMeetingRoom(authToken: String) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let meetingVC = storyBoard.instantiateViewController(withIdentifier: "MeetingRoom") as! MeetingRoomViewController

        let meetingInfo = DyteMeetingInfoV2(
            authToken: authToken, enableAudio: true,
            enableVideo: true, baseUrl: MeetingConfig.BASE_URL
        )
        meetingVC.meetingInfo = meetingInfo
        present(meetingVC, animated: true, completion: nil)
    }

    @IBAction func initMeeting(_: Any) {
        goToMeetingRoom(authToken: MeetingConfig.AUTH_TOKEN)
    }
}
