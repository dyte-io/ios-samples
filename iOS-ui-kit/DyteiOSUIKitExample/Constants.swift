//
//  Constants.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 10/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit

struct Constants {
    static var BASE_URL = "https://app.dyte.io/api/v2"
    static let UUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
    static var PRESET_NAME = "group_call_host"
    static let MEETING_ROOM_NAME = ""
    static var BASE_URL_INIT = "https://api.cluster.dyte.in/v2"
    
    static let errorLoadingImage = "Error Loading Image!"
    static let errorTitle = "Error!"
    static let recordingError = "Something is wrong with recording, don't worry already, we're on it!"
}

