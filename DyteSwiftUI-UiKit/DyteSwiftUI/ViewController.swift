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
        //rk host
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjYwNzA5ZDJhLWM4M2UtNDc3YS04MTk5LWYwMGZmNjgwYzQ0ZCIsIm1lZXRpbmdJZCI6ImJiYjJmZDI3LTlmYzgtNDk1Yy04Y2Y1LWFkN2ZjOTBmNDBjNSIsInBhcnRpY2lwYW50SWQiOiJhYWFlMDgxMy0yNTYwLTQyYzMtOWQ5OC02MzYzN2EwZjBjZjYiLCJwcmVzZXRJZCI6ImZiN2RlMzU0LTk5OTgtNDZiMC05MWQwLTc0ODRmNGFjYjZkZiIsImlhdCI6MTY5MDk4MTk3OCwiZXhwIjoxNjk5NjIxOTc4fQ.CA67Fa4twHXgzAIpOM_LVgDDgvrEozDyJbzbE8nmYHmh1jFgjo2LdibzGoEq5yy5JcH8YqBTKr0hKDUnZAhK8jOy7tQvdSPEEilR5BRvOD4eGUevQqg58zCsE_OvFJDLPxfpIVK6TZ_k8WuBM0fzoJBtIyqfgM-b2tFdfZ1PQ1DvZbJ1TfSSo_RuXLa9G5mMgbfiBS14AgIxk9KPhRO5Q3ouNuuhcMn_zoIviypziLvhL9sSn3bX-Dditbsr4Xbduj70uodvpgiwVa5PNkxZbVLokaHJGu9quZd19kKr72EBgnfDENhW_aFHnMGFx-nVKqICDGUV0nVDeCIAeye6iw")
        
        //rk viewer
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjYwNzA5ZDJhLWM4M2UtNDc3YS04MTk5LWYwMGZmNjgwYzQ0ZCIsIm1lZXRpbmdJZCI6ImJiYjJmZDI3LTlmYzgtNDk1Yy04Y2Y1LWFkN2ZjOTBmNDBjNSIsInBhcnRpY2lwYW50SWQiOiJhYWE5MTc0OC05MjFlLTQyNGMtOTAwYS0xYjUzNDdiZDVhM2UiLCJwcmVzZXRJZCI6ImNmMmNlM2YwLWNiMzgtNGQ5ZS04NzkwLWE1MjBmMmJjYTg3NiIsImlhdCI6MTY5MDk2NDQ3MSwiZXhwIjoxNjk5NjA0NDcxfQ.HgCsSPRWkVRLKUa-GvxgPc6K_DYwuv7C8kIhHiOH1fC5l5BUkZ6fjsGwMBldPdJu1lnEeMLx1TS8weXqckSSR-YsQ8gSPI4hEqYHGhLH5rrbamdldCtBCkvuNzukOr671Isg73ECE6fAnj5IO1oWJyxngoKdF3OtF9AqQRSOX2nHUawzFSrvwCLBsr61AH1l-cNFMwDnCZdRblPFjCsoBj38hzeF1jWmXCtK5SDBrbmqa0Fgwv8FOnQ41RG15OExGVwycyIFwA-grGOEjCPv_HNfcNMA6aUfc1IRZHY7ysjt2q85tyLteYOEW5FUJI3Bcb611hzddzZNxsa4x2l5wQ")
        
        
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjM5MGJmMjc0LTQxMzMtNDI2ZC04NDkxLWVhN2ExYTE5MDQ4YiIsIm1lZXRpbmdJZCI6Ijc0ZDM4NTcyLTkyM2ItNDRiYS1hMDA0LTNkZjk2M2M2OTFkOCIsInBhcnRpY2lwYW50SWQiOiJhYWFlODUyNS1lOWU2LTRkYzUtODJjMC0xOTQ1MzdjYTZlODYiLCJwcmVzZXRJZCI6IjYyNDUwNmY2LTZhYjctNGZjNC04ODZlLTRjZjc2ODUwMzQ0ZCIsImlhdCI6MTY4ODYwNzE4NywiZXhwIjoxNjk3MjQ3MTg3fQ.cDQmXJqkBVm1ygnJBdATm5Rc-j-dIHx6im7gmzhckEvpp8JBCAyjLh7wjvpNfE2uuyiLE_r32DjJ-lk5LbOEItN6q3Y7_3qpDQ76uSrZPOzbaFWpVQfEx5iDeerCWjMdUIzk4i9q_v2tcJ1shbh2uAxFPiwJWHlLq4DkFMzn1HZJXzsH_AzkGwKtwyj1M6vbRu_OtHdi6na3eUDqbHfhYT2IlfT2wfGKwfM_6XcS0dg0njrbW_T8RyVa3f6bfSoHHerE_2bW0-kuKgb8702ODa6FMQ6YjDuck-dJDUETob-lG_2nE9LmGQGIXBeboFfNdSTcftxzoYwdAy4oF41ikw")
        //rk viewer
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjYwNzA5ZDJhLWM4M2UtNDc3YS04MTk5LWYwMGZmNjgwYzQ0ZCIsIm1lZXRpbmdJZCI6ImJiYmFiN2FhLTk5YmYtNGViNy1iNDMzLTRmMjlhZDI2OWJlYyIsInBhcnRpY2lwYW50SWQiOiJhYWFlYmQyNy0xODcyLTQ5YzktODUzMy00ZDliMWExZmUwMjQiLCJwcmVzZXRJZCI6ImNmMmNlM2YwLWNiMzgtNGQ5ZS04NzkwLWE1MjBmMmJjYTg3NiIsImlhdCI6MTY5MDUzNzY5NSwiZXhwIjoxNjk5MTc3Njk1fQ.XeOeOJoZPslZduYuZw79k6Yxq5iqQUYQFx1FbV8P0oOC8-dm8n77DGp0etVz0FQczqZv0ZlPQa2zRXNS3yxsMUZyERAPxRH9eRjeV5n5swEA_gPuE9NrBMSCgKdhdnq9rEmVQpvHLTJQgEcAvp8BaYsPpjvzPp5WtGggEElQeKdHjqblEMZyOdVMlqQAiCbZyTHpLZv1uow16wuJfaw0sq1zEZt9ruW35tQ2c1Q-QJTd3jnhQepHLzn65JTffvTghy9gC9aQY5HLv_egceCTTiIpVt8GK8-r9gAI4L66grxs5L1dRfTipQuUUrMLF4_B9f8T8OpbMlDsb0W9IgCiHw")
        //rk host
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjYwNzA5ZDJhLWM4M2UtNDc3YS04MTk5LWYwMGZmNjgwYzQ0ZCIsIm1lZXRpbmdJZCI6ImJiYmFiN2FhLTk5YmYtNGViNy1iNDMzLTRmMjlhZDI2OWJlYyIsInBhcnRpY2lwYW50SWQiOiJhYWEzYTgwMy1lMGViLTRhZjktOTVlMC02ZjE4OTQ2NjFkMWUiLCJwcmVzZXRJZCI6ImZiN2RlMzU0LTk5OTgtNDZiMC05MWQwLTc0ODRmNGFjYjZkZiIsImlhdCI6MTY5MDU1MTIyNSwiZXhwIjoxNjk5MTkxMjI1fQ.BVluhDv1qJYisny-hqhKvcL0kIVFbA6ivEY8eMjU3PREGL-vrHdEWP_ktQPkdwSdmFmeHrJxpEP7zBA9DyXIC74j2Zi8dH1g5fzbtvWF0pmnxnfbScfgBGhrBZbTWy1eQDjAjP00VTsxH4xlHaFEZ671OJwqiDbXyoy0DC1ZN1g9O75N7rTARA7mrB58UScWDjf2578pwb8Fo8Vh1Do5D1jOGE51m_ErBfbX1AIshuxsEW0Ki0csXZb71CiZNSeLLiGV3ChydhugMR4hQnnyEaICIr_4zi7Kfvn-ub0QaK-yQyTAsVvsS-omYYab9I_MURIC17iwEW7ib8bC0mexOQ")
//
        
        
        
//        //host
        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjQzMDAxNTUwLTU1ZGQtNDRlNC1hN2EwLTk5N2RmZjk5ZWFhYSIsIm1lZXRpbmdJZCI6ImJiYjhjZGE3LWIzOTYtNDJkNi05ZTE3LWFkNDQ4M2IwN2U3MSIsInBhcnRpY2lwYW50SWQiOiJhYWE0YWI4Yy0xNTU1LTRhMTktOGViNy1lZjc5ZThkOTg5ZTMiLCJwcmVzZXRJZCI6IjFhMjJkODFjLTQ2NDYtNDZkNi05N2M0LTBiZjFkNTc1Y2EyOSIsImlhdCI6MTY5MDUzNzA2NSwiZXhwIjoxNjk5MTc3MDY1fQ.bT5hTaSzCKtLqvfchrPF9XREvHYkq_yw1YRs8aiZ42yvQI2AaqgdpvqinlQCI82Tm0tma7qqKvFbashg3j0wBmZ_HeMlrpdZRz86B-DnKU37oxTGL1lOE-OqIbqCsaK6Am0esfGfBuzVl3Dsyc-sBg5E-gs9CqBeoNN9mAsJyMfFCyfAZ5YXjdMv3bssbZ-wD7b4I0A9HTB2PMgrk3Unmk2IOrVJElrM4kftX41DU7IeWwSfDD2lS-NCeQAsdj1fgMLgOcrintSzsDlzaaLcp9fU5v3jxXGEvdjKMMQp2q0cUeSAB-FjRjYwu9qlAqJ9taUdbkO_DPYhj9nEuZrkjA")
        
//        //viewer
//        goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjQzMDAxNTUwLTU1ZGQtNDRlNC1hN2EwLTk5N2RmZjk5ZWFhYSIsIm1lZXRpbmdJZCI6ImJiYjhjZGE3LWIzOTYtNDJkNi05ZTE3LWFkNDQ4M2IwN2U3MSIsInBhcnRpY2lwYW50SWQiOiJhYWFlOWU2NS1hMDNkLTQ2MTItOWNkNi1hZDBiYzI5OWU1ZjQiLCJwcmVzZXRJZCI6IjYwMmUyMDFlLWNlZTUtNGEzMy04M2Q0LWNhMzU3NDU1YTkxNSIsImlhdCI6MTY5MDUzNjE0MywiZXhwIjoxNjk5MTc2MTQzfQ.HEoRzzYqXMFh0Q_-VRO4GYJdniqBYEi_fpspJnH1oAOb7Z2HqjXAoeWthn_cjWcAjz_5XnjLOUMixClqP5gt1UXA_fd6fWkZULHrrADai5MvaVwFNuWYFB2JA78Go0FzQull9xkvf9uohE7Rcl7-JYzUFWHoUX0qR3ZUyX78sRtq0-DAaeg170I6Gph7KxziEJKV2de0zc0kFt4C-q21jUxs593OGIhgtgqdpO4o65i39R_A2mdl_g4ghcWhGH3TQmDXfUwwUtqZIajVd-sDiL3x7AtGtT2OBx9yQRE7T_ohgmUuCKRqEs8MaxJE0D0vsPxkplFMvOpxNN5gY2fmGQ")
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
