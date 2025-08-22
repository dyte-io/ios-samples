import RealtimeKit
import UIKit

class RtkUtils {
    static func canLocalUserDisableParticipantAudio(_ localUser: RtkSelfParticipant) -> Bool {
        return localUser.permissions.host.canMuteAudio
    }

    static func canLocalUserDisableParticipantVideo(_ localUser: RtkSelfParticipant) -> Bool {
        return localUser.permissions.host.canMuteVideo
    }

    static func canLocalUserKickParticipant(_ localUser: RtkSelfParticipant) -> Bool {
        return localUser.permissions.host.canKickParticipant
    }

    static func canPinParticipant(_ localUser: RtkSelfParticipant) -> Bool {
        return localUser.permissions.host.canPinParticipant
    }
}
