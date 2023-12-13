//
//  MeetingSetupViewModel.swift
//  DyteUIKitExample
//
//  Created by Shaunak Jagtap on 27/01/23.
//

import Foundation
import DyteiOSCore

protocol MeetingSetupDelegate {
    func startMeetingSuccess(createMeetingResponse: CreateMeetingResponse)
    func hideActivityIndicator()
    func createParticipantSuccess(authToken: String, meetingID: String)
}

final class MeetingSetupViewModel {
    
    var meetingSetupDelegate : MeetingSetupDelegate?
    var createMeetingResponse: CreateMeetingResponse?
    var createParticipantResponse: CreateParticipantResponse?
    var isHost = true
    
    func startMeeting(request: CreateMeetingRequest) {
        ApiService().createMeeting(createMeetingRequest: request, success: { [weak self] response in
            print("response: \(response)")
            self?.createMeetingResponse = response
            self?.meetingSetupDelegate?.startMeetingSuccess(createMeetingResponse: response)
        }) { [weak self] errorString in
            self?.meetingSetupDelegate?.hideActivityIndicator()
            print("CreateMeeting API Error:\(errorString)")
        }
    }
    
    func joinCreatedMeeting(displayName: String, meetingID: String) {
        let req = CreateParticipantRequest(
            client_specific_id: Constants.UUID,
            name: displayName,
            preset_name: Constants.PRESET_NAME, picture: "")
        
        ApiService().createParticipant(meetingId: meetingID, createParticipantRequest: req, success: { [weak self] response in
            self?.meetingSetupDelegate?.hideActivityIndicator()
            self?.createParticipantResponse = response
            if let authToken = response.token {
                //Store token for future use
                UserDefaults.standard.setValue(authToken, forKey: meetingID)
                self?.meetingSetupDelegate?.createParticipantSuccess(authToken: authToken, meetingID: meetingID)
            } else {
                print("Error: missing authToken: \(response.token ?? "")")
            }
            
        }, failure: { [weak self] errorString in
            DispatchQueue.main.async {
                self?.meetingSetupDelegate?.hideActivityIndicator()
            }
            print("Error: createParticipant API :\(errorString)")
        })
    }
}
