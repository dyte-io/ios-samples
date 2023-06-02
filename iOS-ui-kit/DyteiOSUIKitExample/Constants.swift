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
    static let BASE_URL = "https://api.cluster.dyte.in/v2"
    static let IP_ADDRESS = "api.cluster.dyte.in/v2"
    static let ORG_ID = YOUR_ORG_ID
    static let API_KEY = YOUR_API_KEY
}

