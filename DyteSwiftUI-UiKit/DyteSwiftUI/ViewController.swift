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
        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjM5MGJmMjc0LTQxMzMtNDI2ZC04NDkxLWVhN2ExYTE5MDQ4YiIsIm1lZXRpbmdJZCI6Ijc0ZDM4NTcyLTkyM2ItNDRiYS1hMDA0LTNkZjk2M2M2OTFkOCIsInBhcnRpY2lwYW50SWQiOiJhYWFlODUyNS1lOWU2LTRkYzUtODJjMC0xOTQ1MzdjYTZlODYiLCJwcmVzZXRJZCI6IjYyNDUwNmY2LTZhYjctNGZjNC04ODZlLTRjZjc2ODUwMzQ0ZCIsImlhdCI6MTY4ODYwNzE4NywiZXhwIjoxNjk3MjQ3MTg3fQ.cDQmXJqkBVm1ygnJBdATm5Rc-j-dIHx6im7gmzhckEvpp8JBCAyjLh7wjvpNfE2uuyiLE_r32DjJ-lk5LbOEItN6q3Y7_3qpDQ76uSrZPOzbaFWpVQfEx5iDeerCWjMdUIzk4i9q_v2tcJ1shbh2uAxFPiwJWHlLq4DkFMzn1HZJXzsH_AzkGwKtwyj1M6vbRu_OtHdi6na3eUDqbHfhYT2IlfT2wfGKwfM_6XcS0dg0njrbW_T8RyVa3f6bfSoHHerE_2bW0-kuKgb8702ODa6FMQ6YjDuck-dJDUETob-lG_2nE9LmGQGIXBeboFfNdSTcftxzoYwdAy4oF41ikw")
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
