//
//  ViewController.swift
//  DyteiOSUIKitExample
//
//  Created by sudhir kumar on 27/01/23.
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
        button.frame.size.width = 150
        button.frame.size.height = 40
        button.center = self.view.center
    }
    
    @objc
    func buttonClick(button: UIButton) {
        startMeeting()
    }
    
    private func startMeeting() {
        self.dyteUikit = DyteUiKit.init(meetingInfoV2: DyteMeetingInfoV2(authToken: MeetingConfig.AUTH_TOKEN, enableAudio: false, enableVideo: false, baseUrl: MeetingConfig.BASE_URL))
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
