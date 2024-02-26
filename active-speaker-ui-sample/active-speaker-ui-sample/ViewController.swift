//
//  ViewController.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import UIKit
import DyteUiKit
import DyteiOSCore

class ViewController: UIViewController{
    
    private var dyteUikit: DyteUiKit!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton()
    }
    
    func addButton() {
        let button = DyteUIUTility.createButton(text: "Start Meeting")
        button.addTarget(self, action: #selector(buttonClick(button:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.set(.centerView(self.view))
    }
    
    @objc
    func buttonClick(button: UIButton) {
        startMeeting()
    }
    
    private func startMeeting() {
        self.dyteUikit = DyteUiKit.init(meetingInfoV2: DyteMeetingInfoV2(authToken: MeetingConfig.AUTH_TOKEN, enableAudio: true, enableVideo: true, baseUrl: "dyte.io"), flowDelegate: self)
         let controller =  self.dyteUikit.startMeeting {
            [weak self] in
            guard let self = self else {return}
            self.dismiss(animated: true)
             // you can restart meeting on leave call here
             //startMeeting()
        }
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
    
}

//return nil in case you want to use DyteUiKit's UI
extension ViewController: DyteUIKitFlowCoordinatorDelegate {
    
    func showGroupCallMeetingScreen(meeting: DyteMobileClient, completion: @escaping() -> Void) -> UIViewController? {
        let controller =  ActiveSpeakerMeetingViewController(meeting: meeting, completion: completion)
        return controller
    }
    
    func showWebinarMeetingScreen(meeting: DyteMobileClient, completion: @escaping() -> Void) -> UIViewController? {
        self.dyteUikit.mobileClient.participants.disableCache()
        let controller =  ActiveSpeakerWebinarMeetingViewController(meeting: meeting, completion: completion)
        return controller
    }
    
    func showSetUpScreen(completion: () -> Void) -> SetupViewControllerDataSource? {
        return nil
    }
}
