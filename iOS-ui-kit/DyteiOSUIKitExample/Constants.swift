//
//  Constants.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 10/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit

struct Constants {
    static let UUID = (UIDevice.current.identifierForVendor?.uuidString ?? "") + Date().debugDescription
    static let PRESET_NAME = "group_call_host"
    static let BASE_URL_INIT = "https://api.cluster.dyte.in/v2"
    static let BASE_URL = "https://app.dyte.in/api/v2"
    static let ORG_ID = YOUR_ORG_ID_HERE
    static let API_KEY = YOUR_API_KEY_HERE
}

