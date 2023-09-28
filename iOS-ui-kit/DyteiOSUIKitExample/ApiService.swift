//
//  ApiService.swift
//  DyteUIKitExample
//
//  Created by Shaunak Jagtap on 27/01/23.
//

import Foundation
import DyteiOSCore


struct CreateMeetingResponse: Codable {
    var record_on_start: Bool?
    var id: String?
    var created_at: String?
    var live_stream_on_start: Bool?
    var status: String?
    var title: String?
    var updated_at: String?
}

struct PresetsResponse: Codable {
    var name: String
    var id: String
    var created_at: String
    var updated_at: String
}

struct CreateParticipantResponse: Codable {
    var created_at: String?
    var custom_participant_id: String?
    var id: String?
    var name: String?
    var preset_id: String?
    var token: String?
    var updated_at: String?
}

struct ApiService {
    
    func createParticipant( meetingId: String, createParticipantRequest: CreateParticipantRequest, success:@escaping(CreateParticipantResponse) -> Void, failure:@escaping(String) -> Void) {
        guard let url = URL(string:
                                "\(Constants.BASE_URL)/participants") else {
            return
        }
        
        if let params = ["presetName" : createParticipantRequest.preset_name ?? "",
                         "meetingId" : meetingId,
                         "clientSpecificId": createParticipantRequest.client_specific_id,
                         "displayName" : createParticipantRequest.name ?? ""] as? [String: Any] {
            NetworkManager.shared.postData(url: url, params: params, success: success, failure: failure)
        } else {
            print("Error: not able to create params for CreateMeetingApiService")
        }
    }
    
    func createMeeting(createMeetingRequest: CreateMeetingRequest, success:@escaping(CreateMeetingResponse) -> Void, failure:@escaping(String) -> Void) {
        guard let url = URL(string: "\(Constants.BASE_URL)/meetings") else {
            return
        }
        
        if let params = ["title" : createMeetingRequest.title] as? [String: Any] {
            NetworkManager.shared.postData(url: url, params: params, success: success, failure: failure)
        } else {
            print("Error: not able to create params for CreateMeetingApiService")
        }
    }
    
    func getPresets(success:@escaping([PresetsResponse]) -> Void, failure:@escaping(String) -> Void) {
        guard let url = URL(string: "\(Constants.BASE_URL)/presets") else {
            return
        }
        NetworkManager.shared.getData(url: url, success: success, failure: failure)
    }
    
}
