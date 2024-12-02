//
//  ViewController.swift
//  DyteCoreExample
//
//  Created by Shaunak Jagtap on 10/01/23.
//

import UIKit
import DyteiOSCore
class ViewController: UIViewController {
    
    @IBOutlet weak var initButton: UIButton!
    private var dyteMobileClient: DyteMobileClient?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func goToMeetingRoom(authToken: String) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Storyboard", bundle:nil)
        let meetingVC = storyBoard.instantiateViewController(withIdentifier: "MeetingRoom") as! MeetingRoomViewController
        
        let meetingInfo = DyteMeetingInfoV2(
            authToken: authToken, enableAudio: true,
            enableVideo: true, baseDomain: MeetingConfig.BASE_URL
        )
        meetingVC.meetingInfo = meetingInfo
        self.present(meetingVC, animated:true, completion:nil)
    }
    
    
    @IBAction func initMeeting(_ sender: Any) {
        self.goToMeetingRoom(authToken: MeetingConfig.AUTH_TOKEN)
    }
}


