//
//  DyteUtils.swift
//  iosApp
//
//  Created by Swapnil Madavi on 26/09/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

// TODO: Remove Utils and integrate in app
class DyteUtils {
    static func canLocalUserDisableParticipantAudio(_ localUser: DyteSelfParticipant) -> Bool {
        return localUser.permissions.host.canMuteAudio
    }

    static func canLocalUserDisableParticipantVideo(_ localUser: DyteSelfParticipant) -> Bool {
        return localUser.permissions.host.canMuteVideo
    }

    static func canLocalUserKickParticipant(_ localUser: DyteSelfParticipant) -> Bool {
        return localUser.permissions.host.canKickParticipant
    }

    static func canPinParticipant(_ localUser: DyteSelfParticipant) -> Bool {
        return localUser.permissions.host.canPinParticipant
    }
}
