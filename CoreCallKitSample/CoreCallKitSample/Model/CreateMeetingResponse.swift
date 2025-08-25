struct CreateMeetingResponse: Codable {
    var meeting: MeetingResponse?
}

struct MeetingResponse: Codable {
    var id: String?
    var title: String?
    var roomName: String?
    var status: String?
    var createdAt: String?
}
