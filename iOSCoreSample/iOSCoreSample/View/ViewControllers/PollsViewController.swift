import RealtimeKit
import UIKit

class PollsViewController: UIViewController {
    var rtkClient: RealtimeKitClient?
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
        createPollViewController.rtkClient = rtkClient
        present(createPollViewController, animated: true, completion: nil)
    }

    @objc func saveButtonPressed() {}
}

extension PollsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return rtkClient?.polls.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PollTableViewCell", for: indexPath) as? PollTableViewCell,
           (rtkClient?.polls.items.count ?? 0) > indexPath.row
        {
            cell.poll = rtkClient?.polls.items[indexPath.row]
            cell.configureUI()
            return cell
        }

        return UITableViewCell(frame: .zero)
    }
}

extension PollsViewController: PollDelegate {
    func refreshPolls(pollMessages _: [Poll]) {
        tableView.reloadData()
    }
}
