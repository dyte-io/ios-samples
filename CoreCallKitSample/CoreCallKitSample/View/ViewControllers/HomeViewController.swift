//
//  ViewController.swift
//  iosApp
//
//  Created by xyz on 19/03/22.
//  Copyright © 2022 orgName. All rights reserved.
//
import DyteiOSCore
import UIKit

class HomeViewController: UIViewController {
    @IBOutlet var initButton: UIButton!
    private var dyteMobileClient: DyteMobileClient?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func goToMeetingRoom(meetingText _: String, authToken: String) {
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
        goToMeetingRoom(meetingText: "", authToken: MeetingConfig.AUTH_TOKEN)
    }
}
