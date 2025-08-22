//
//  ParticipantsViewController.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 22/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

class ParticipantsViewController: UIViewController {
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var participantsCountLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    var participants = [DyteJoinedMeetingParticipant]()
    var filteredData = [DyteJoinedMeetingParticipant]()
    var meetingViewModel: MeetingViewModel?
    var dyteMobileClient: DyteMobileClient?
    private var shouldShowHostControlOptions: Bool = false

    override func viewDidLoad() {
        searchBar.delegate = self
        meetingViewModel?.participantsDelegate = self

        if let localUser = dyteMobileClient?.localUser {
            shouldShowHostControlOptions = DyteUtils.canLocalUserDisableParticipantAudio(localUser) || DyteUtils.canLocalUserDisableParticipantVideo(localUser) || DyteUtils.canLocalUserKickParticipant(localUser)
        }

        tableView.register(UINib(nibName: "ParticipantTableViewCell", bundle: nil), forCellReuseIdentifier: "ParticipantTableViewCell")
        refreshList()
    }

    private func showHostControlOptions(for participant: DyteJoinedMeetingParticipant) {
        if let localUser = dyteMobileClient?.localUser {
            var alertActions: [UIAlertAction] = []

            if DyteUtils.canLocalUserDisableParticipantAudio(localUser) {
                let muteAudioAction = UIAlertAction(title: "Mute audio", style: .default) { _ in
                    do {
                        try participant.disableAudio()
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                alertActions.append(muteAudioAction)
            }

            if DyteUtils.canLocalUserDisableParticipantVideo(localUser) {
                let turnOffVideoAction = UIAlertAction(title: "Turn off video", style: .default) { _ in
                    do {
                        try participant.disableVideo()
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                alertActions.append(turnOffVideoAction)
            }

            if DyteUtils.canLocalUserKickParticipant(localUser) {
                let kickParticipantAction = UIAlertAction(title: "Kick", style: .destructive) { _ in
                    do {
                        try participant.kick()
                    } catch {
                        print("Error: \(error.localizedDescription)")
                    }
                }
                alertActions.append(kickParticipantAction)
            }

            if !alertActions.isEmpty {
                let participantActionSheet = UIAlertController(title: participant.name, message: "", preferredStyle: .actionSheet)

                for action in alertActions {
                    participantActionSheet.addAction(action)
                }
                participantActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

                present(participantActionSheet, animated: true)
            }
        }
    }
}

extension ParticipantsViewController: ParticipantsDelegate {
    func refreshList() {
        participants.removeAll()
        if let array = dyteMobileClient?.participants.joined {
            participants = array
            if let screenshares = dyteMobileClient?.participants.screenshares {
                participants.append(contentsOf: screenshares)
            }
            filteredData = participants
        }
        tableView.reloadData()
    }
}

extension ParticipantsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return participants.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantTableViewCell", for: indexPath) as? ParticipantTableViewCell, filteredData.count > indexPath.row {
            cell.participant = filteredData[indexPath.row]
            let participantIsLocalUser = cell.participant?.userId == dyteMobileClient?.localUser.userId
            if participantIsLocalUser {
                cell.moreOptionsImageView.isHidden = true
            } else {
                cell.moreOptionsImageView.isHidden = false
            }
            return cell
        }

        return UITableViewCell(frame: .zero)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if !filteredData.isEmpty {
            let selectedParticipant = filteredData[indexPath.row]
            if selectedParticipant.userId != dyteMobileClient?.localUser.userId {
                if shouldShowHostControlOptions {
                    showHostControlOptions(for: selectedParticipant)
                } else {
                    showNormalAlert(withTitle: "Not Allowed", havingMessage: "You do not have the host permissions.")
                }
            }
        }
    }
}

extension ParticipantsViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        filteredData = participants

        if searchText.isEmpty == false {
            filteredData = participants.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }

        tableView.reloadData()
    }
}
