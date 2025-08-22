import RealtimeKit
import UIKit

class PollTableViewCell: UITableViewCell {
    @IBOutlet var questionLabel: UILabel!
    @IBOutlet var pollByLabel: UILabel!

    @IBOutlet var checkButtonOne: UIButton!
    @IBOutlet var optionOneLabel: UILabel!

    @IBOutlet var checkButtonTwo: UIButton!
    @IBOutlet var optionTwoLabel: UILabel!

    var poll: Poll?

    func configureUI() {
        checkButtonOne.setTitle("", for: .normal)
        checkButtonTwo.setTitle("", for: .normal)
        if let checkOneCount = poll?.options.first?.count as? Int {
            let shouldShowCheckOne = checkOneCount > 0
            checkButtonOne.setImage(UIImage(systemName: shouldShowCheckOne ? "checkmark.rectangle" : "rectangle"), for: .normal)
        }

        questionLabel.text = poll?.question ?? ""
        pollByLabel.text = "Poll By \(poll?.createdBy ?? "")"
        optionOneLabel.text = "\(poll?.options.first?.text ?? "") (\(poll?.options.first?.count ?? 0))"
        if poll?.options.count ?? 0 > 1 {
            optionTwoLabel.text = "\(poll?.options[1].text ?? "") (\(poll?.options[1].count ?? 0))"
            if let checkTwoCount = poll?.options[1].count as? Int {
                let shouldShowCheckTwo = checkTwoCount > 0
                checkButtonTwo.setImage(UIImage(systemName: shouldShowCheckTwo ? "checkmark.rectangle" : "rectangle"), for: .normal)
            }
        }
    }
}
