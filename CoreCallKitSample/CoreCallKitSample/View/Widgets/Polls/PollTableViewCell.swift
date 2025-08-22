//
//  PollTableViewCell.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 01/09/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import DyteiOSCore
import UIKit

class PollTableViewCell: UITableViewCell {
    @IBOutlet var questionLabel: UILabel!
    @IBOutlet var pollByLabel: UILabel!

    @IBOutlet var checkButtonOne: UIButton!
    @IBOutlet var optionOneLabel: UILabel!

    @IBOutlet var checkButtonTwo: UIButton!
    @IBOutlet var optionTwoLabel: UILabel!

    var polll: DytePollMessage?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureUI() {
        checkButtonOne.setTitle("", for: .normal)
        checkButtonTwo.setTitle("", for: .normal)
        if let checkOneCount = polll?.options.first?.count as? Int {
            let shouldShowCheckOne = checkOneCount > 0
            checkButtonOne.setImage(UIImage(systemName: shouldShowCheckOne ? "checkmark.rectangle" : "rectangle"), for: .normal)
        }

        questionLabel.text = polll?.question ?? ""
        pollByLabel.text = "Poll By \(polll?.createdBy ?? "")"
        optionOneLabel.text = "\(polll?.options.first?.text ?? "") (\(polll?.options.first?.count ?? 0))"
        if polll?.options.count ?? 0 > 1 {
            optionTwoLabel.text = "\(polll?.options[1].text ?? "") (\(polll?.options[1].count ?? 0))"
            if let checkTwoCount = polll?.options[1].count as? Int {
                let shouldShowCheckTwo = checkTwoCount > 0
                checkButtonTwo.setImage(UIImage(systemName: shouldShowCheckTwo ? "checkmark.rectangle" : "rectangle"), for: .normal)
            }
        }
    }
}
