//
//  Constants.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 10/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit
import UIKit

struct Constants {
   
    static let AUTH_TOKEN = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6ImY3NjNiODI5LWQyZWUtNGQ4Ni1hNDgyLTg2OGE3YWRhMTU3NiIsIm1lZXRpbmdJZCI6ImJiYjIyN2M2LTE5OGQtNDQ4YS05ZTBmLTc0NjU0YmMwZWI3YyIsInBhcnRpY2lwYW50SWQiOiJhYWEzMDJmYy04NTQ0LTQxMDQtYmNjNy02ZWY2YzM1YmZmYTQiLCJwcmVzZXRJZCI6IjI3MWUwMmU0LTI4ZmEtNDUyMS1hZTQ3LTgxYmZiZTk0OWM3ZiIsImlhdCI6MTY3OTY1NTEwOSwiZXhwIjoxNjg4Mjk1MTA5fQ.HKunx0f4U3fmEEvUuDgJ4PURV5eeF6I1fJ0qr6a2suLgb2x5i6ygsM5wpPyDzY0a8tnN7kqd9xwIgFDQcTgMiR6w7hXNYwPWfco4mrCJxdzT_NCEdfl2QkzwLqzr8YdDTLDDM-JH_fhnHhujopE6XNY1uvrUSs1U8QCtglTOaFej94GS0KzpWzABXZZvNPDE8ZAPsVjVTYuB3X1BHnu6VXOxjIYnM1z0u3TUs7-xzixN0RyHJk6hZ-WB0-GsTvfGygeegglT-5LBX1V1-kMK1M2md7pV_jezTFPfmoB6pco77tSmmNG_o51_0_I54RejgYax83z0K-UogC1OvhJtpQ"

    static let BASE_URL = "https://api.cluster.dyte.in/v2"
    
    static let UUID = UIDevice.current.identifierForVendor?.uuidString ?? ""
    static let errorLoadingImage = "Error Loading Image!"
    static let errorTitle = "Error!"
    static let recordingError = "Something is wrong with recording, don't worry already, we're on it!"
}
