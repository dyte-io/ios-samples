//
//  ViewController.swift
//  DyteiOSUIKitExample
//
//  Created by sudhir kumar on 27/01/23.
//

import UIKit
import DyteUiKit
import DyteiOSCore
import AVKit


class ViewController: UIViewController {
        
    @IBOutlet weak var meetingCodeTextField: UITextField!
    @IBOutlet weak var meetingNameTextField: UITextField!
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var joinUserNameTextField: UITextField!
    private var meetingSetupViewModel =  MeetingSetupViewModel()
    
    
    private var dyteUIKitEngine: DyteUiKit!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        
        //set delegate to catch pest action
        meetingCodeTextField.text = ""
        meetingCodeTextField.delegate = self
        
        meetingSetupViewModel.meetingSetupDelegate = self
        
        //Handle keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        joinUserNameTextField.isHidden = true
        userNameTextField.isHidden = true
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: routeChange)
    }
    
    private func routeChange(_ notification: Notification) {
        guard let info = notification.userInfo,
                let value = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: value) else { return }

            switch reason {
            case .categoryChange:
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            case .oldDeviceUnavailable:
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            default:
                print("Error: other reason for speaker route change!")
            }
    }
    
    @IBAction func joinMeeting(_ sender: Any) {
        meetingCodeTextField.resignFirstResponder()
        
        if let text = meetingCodeTextField.text, !text.isEmpty {
            self.view.showActivityIndicator()
            if let meetingId = meetingCodeTextField.text {
                if meetingId.contains("https://demo.dyte.io/v2/meeting?id=") {
                    if let meeting = meetingId.components(separatedBy:"=").last {
                        self.meetingSetupViewModel.joinCreatedMeeting(displayName: "Join as XYZ", meetingID: meeting)
                    }
                } else {
                    self.meetingSetupViewModel.joinCreatedMeeting(displayName: "Join as XYZ", meetingID: meetingId)
                }
                meetingCodeTextField.text = ""
            }
        } else {
            Utils.displayAlert(alertTitle: "Error", message: "Invalid Meeting")
        }
    }
    
    @IBAction func startMeeting(_ sender: Any) {

        meetingNameTextField.resignFirstResponder()
        if let text = meetingNameTextField.text, !text.isEmpty {
            self.view.showActivityIndicator()
            let req = CreateMeetingRequest(title: meetingNameTextField.text ?? "" , preferred_region: "ap-south-1")
            meetingSetupViewModel.startMeeting(request: req)
            meetingNameTextField.text = ""
        } else {
            Utils.displayAlert(alertTitle: "Error", message: "Meeting Name Required")
        }
    }
    
    func goToMeetingRoom(authToken: String) {
        dyteUIKitEngine = DyteUiKit(meetingInfoV2: DyteMeetingInfoV2(authToken: authToken, enableAudio: false, enableVideo: false, baseUrl: Constants.BASE_URL_INIT))
        let controller = dyteUIKitEngine.startMeeting(completion: {
            [weak self] in
           guard let self = self else {return}
            self.dismiss(animated: true)
            self.view.hideActivityIndicator()
        })
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ViewController: MeetingSetupDelegate {
    func createParticipantSuccess(authToken: String, meetingID: String) {
        self.goToMeetingRoom(authToken: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjM5MGJmMjc0LTQxMzMtNDI2ZC04NDkxLWVhN2ExYTE5MDQ4YiIsIm1lZXRpbmdJZCI6ImJiYmEyYjg0LTI5OGYtNGVjYy1hNWRmLTQ0OGVkZTJlOTg2NiIsInBhcnRpY2lwYW50SWQiOiJhYWExYzk0Ny1mNjEyLTQ3MDMtOWE5Mi1kZGU3OTI3MGFmMDYiLCJwcmVzZXRJZCI6IjQwMDgxZjQ2LTk5MmYtNDZlNy04MDY0LTAxMzYzNWIyMzBlYSIsImlhdCI6MTY5MDM3NDgyNSwiZXhwIjoxNjk5MDE0ODI1fQ.GhIeyuLbg6vgzw2retsb7--AK4KL4KEvx6IUFGopMZ9VFpb6X-EzrcjP3abLcp6cJzkKO_yjGvEAMU-oxgOB9ytYuziQzdP064W7EEw6Sfc6_qoYFKSX7TDxekT3GuLX4Acx85nBR8R-1tIxU9fkgL3LXDMm1Q3LPASNNVO-bRhPWH46rB_g7aKOSmYXSRO1IYjUAj-eFFDydVaq5ylbhTanNXIDNEWZkzQ5PXkykSSoMIiTywmw9FZsGAHohvLfjWz7aGPqXm4wI1JO9_g1R9swLbXvUlg4BrbvlQD-4oS5CI053eaWJSAnGoeLRxnxTDzFf6I5LE035K48cGX0UQ")
    }
    
    
    func startMeetingSuccess(createMeetingResponse: CreateMeetingResponse) {
        if let meetingId = createMeetingResponse.id {
            self.meetingSetupViewModel.joinCreatedMeeting(displayName: "Join as XYZ", meetingID: meetingId)
        }
    }
    
    func hideActivityIndicator() {
        self.view.hideActivityIndicator()
    }
}

extension ViewController: UITextFieldDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let paste = UIPasteboard.general.string, text == paste {
            meetingCodeTextField.text = paste
        }
        return true
    }
}
