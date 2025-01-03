//
//  ParticipantsViewController.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 22/08/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit
import DyteiOSCore

class ParticipantsViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var participantsCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var participants = [DyteMeetingParticipant]()
    var filteredData = [DyteMeetingParticipant]()
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
    
    private func showHostControlOptions(for participant: DyteRemoteParticipant) {
        if let localUser = dyteMobileClient?.localUser {
            var alertActions: [UIAlertAction] = []
            
            if DyteUtils.canLocalUserDisableParticipantAudio(localUser) {
                let muteAudioAction = UIAlertAction(title: "Mute audio", style: .default) { (action) in
                    if let error = participant.disableAudio() {
                        print("Error: \(error.description())")
                    }
                }
                alertActions.append(muteAudioAction)
            }
            
            if DyteUtils.canLocalUserDisableParticipantVideo(localUser) {
                let turnOffVideoAction = UIAlertAction(title: "Turn off video", style: .default) { (action) in
                    if let error = participant.disableVideo() {
                        print("Error: \(error.description())")
                    }
                }
                alertActions.append(turnOffVideoAction)
            }
            
            if DyteUtils.canLocalUserKickParticipant(localUser) {
                let kickParticipantAction = UIAlertAction(title: "Kick", style: .destructive) { (action) in

                    if let error = participant.kick() {
                        print("Error: \(error.description())")
                    }
                }
                alertActions.append(kickParticipantAction)
            }
            
            if !alertActions.isEmpty {
                let participantActionSheet = UIAlertController(title: participant.name, message: "", preferredStyle: .actionSheet)
                
                alertActions.forEach { action in
                    participantActionSheet.addAction(action)
                }
                participantActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                self.present(participantActionSheet, animated: true)
            }
        }
    }
}

extension ParticipantsViewController: ParticipantsDelegate {
    func refreshList() {
        guard let meeting = dyteMobileClient else {
            return
        }
        
        participants.removeAll()
        participants = [meeting.localUser] + meeting.participants.joined
        filteredData = participants
        tableView.reloadData()
    }
}

extension ParticipantsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantTableViewCell", for: indexPath) as? ParticipantTableViewCell, filteredData.count > indexPath.row
        {
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
                    showHostControlOptions(for: selectedParticipant as! DyteRemoteParticipant)
                } else {
                    self.showNormalAlert(withTitle: "Not Allowed", havingMessage: "You do not have the host permissions.")
                }
            }
        }
    }
}

extension ParticipantsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredData = participants

        if searchText.isEmpty == false {
            filteredData = participants.filter({ $0.name.lowercased().contains(searchText.lowercased()) })
        }

        tableView.reloadData()
    }
}
