//
//  PollsViewController.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 01/09/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

class PollsViewController: UIViewController {
    var dyteMobileClient: DyteMobileClient?
    var meetingViewModel: MeetingViewModel?
    var questionTextView: UITextView!
    var optionOne: UITextField!
    var optionTwo: UITextField!
    private var options: [String]?

    @IBOutlet var stackView: UIStackView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var createNewPollButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        meetingViewModel?.pollDelegate = self
        createNewPollButton.isHidden = false
        tableView.register(UINib(nibName: "PollTableViewCell", bundle: nil), forCellReuseIdentifier: "PollTableViewCell")
    }

    @IBAction func createPollAction(_: Any) {
        let storyBoard = UIStoryboard(name: "Storyboard", bundle: nil)
        let createPollViewController = storyBoard.instantiateViewController(withIdentifier: "CreatePollViewController") as! CreatePollViewController
        createPollViewController.dyteMobileClient = dyteMobileClient
        present(createPollViewController, animated: true, completion: nil)
    }

    @objc func saveButtonPressed() {}
}

extension PollsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return dyteMobileClient?.polls.polls.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PollTableViewCell", for: indexPath) as? PollTableViewCell,
           (dyteMobileClient?.polls.polls.count ?? 0) > indexPath.row
        {
            cell.polll = dyteMobileClient?.polls.polls[indexPath.row]
            cell.configureUI()
            return cell
        }

        return UITableViewCell(frame: .zero)
    }
}

extension PollsViewController: PollDelegate {
    func refreshPolls(pollMessages _: [DytePollMessage]) {
        tableView.reloadData()
    }
}
