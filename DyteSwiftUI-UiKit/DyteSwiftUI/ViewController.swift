//
//  ViewController.swift
//  DyteSwiftUI
//
//  Created by Shaunak Jagtap on 31/05/23.
//

import Foundation
import UIKit
import DyteUiKit
import DyteiOSCore

class ViewController: UIViewController {
    var dyteUIKitEngine: DyteUiKit!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
         Read this to generate authentication token which is used to join Meeting
         https://docs.dyte.io/ios
         */
        self.goToMeetingRoom(authToken: authToken)
    }
    
    func goToMeetingRoom(authToken: String) {
        dyteUIKitEngine = DyteUiKit(meetingInfoV2: DyteMeetingInfoV2(authToken: authToken, enableAudio: false, enableVideo: false, baseUrl: "https://api.cluster.dyte.in/v2"))
        let controller = dyteUIKitEngine.startMeeting(completion: {
            [weak self] in
           guard let self = self else {return}
            self.dismiss(animated: true)
            
        })
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
}
