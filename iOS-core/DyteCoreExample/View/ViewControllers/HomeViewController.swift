//
//  ViewController.swift
//  iosApp
//
//  Created by xyz on 19/03/22.
//  Copyright © 2022 orgName. All rights reserved.
//
import UIKit
import DyteiOSCore
class HomeViewController: UIViewController {
    
    @IBOutlet weak var initButton: UIButton!
    private var dyteMobileClient: DyteMobileClient?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func goToMeetingRoom(meetingText: String, authToken: String) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Storyboard", bundle:nil)
        let meetingVC = storyBoard.instantiateViewController(withIdentifier: "MeetingRoom") as! MeetingRoomViewController
        
        let meetingInfo = DyteMeetingInfoV2(authToken: authToken, enableAudio: true, enableVideo: true)
        meetingVC.meetingInfo = meetingInfo
        self.present(meetingVC, animated:true, completion:nil)
    }
    
    
    @IBAction func initMeeting(_ sender: Any) {
        self.goToMeetingRoom(meetingText: "", authToken: MeetingConfig.AUTH_TOKEN)
    }
}
