import UIKit

struct CreateParticipantResponse: Codable {
    var authResponse: Auth?
}

struct Auth: Codable {
    var userAdded: Bool?
    var authToken: String?
    var id: String?
}
