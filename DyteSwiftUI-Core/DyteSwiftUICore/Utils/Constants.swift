//
//  Constants.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 10/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit

struct Constants {
   
    /*
     Read this to generate authentication token which is used to join Meeting
     https://docs.dyte.io/ios
     */
    static let AUTH_TOKEN = YOUR_TOKEN_HERE
    static let BASE_URL = "https://api.cluster.dyte.in/v2"
    static let UUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
    static let errorLoadingImage = "Error Loading Image!"
    static let errorTitle = "Error!"
    static let recordingError = "Something is wrong with recording, don't worry already, we're on it!"
}
