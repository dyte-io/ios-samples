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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
         Read this to generate authentication token which is used to join Meeting
         https://docs.dyte.io/ios
         */
        goToMeetingRoom(authToken: YOUR_AUTH_TOKEN_HERE)
    }
    
    func goToMeetingRoom(authToken: String) {
        DyteUiKitEngine.setupV2(DyteMeetingInfoV2(authToken: authToken, enableAudio: true, enableVideo: true, baseUrl: "https://api.cluster.dyte.in/v2"))
        
        let controller = DyteUiKitEngine.shared.getInitialController {
            [weak self] in
            guard let self = self else {return}
            self.dismiss(animated: true)
        }
        
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
}
