//
//  PollTableViewCell.swift
//  iosApp
//
//  Created by Shaunak Jagtap on 01/09/22.
//  Copyright © 2022 orgName. All rights reserved.
//

import UIKit
import DyteiOSCore

class PollTableViewCell: UITableViewCell {
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var pollByLabel: UILabel!
    
    @IBOutlet weak var checkButtonOne: UIButton!
    @IBOutlet weak var optionOneLabel: UILabel!
    
    @IBOutlet weak var checkButtonTwo: UIButton!
    @IBOutlet weak var optionTwoLabel: UILabel!

    var poll: DytePoll?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureUI() {
        self.checkButtonOne.setTitle("", for: .normal)
        self.checkButtonTwo.setTitle("", for: .normal)
        if let checkOneCount = poll?.options.first?.count as? Int {
            let shouldShowCheckOne = checkOneCount > 0
            self.checkButtonOne.setImage(UIImage(systemName: shouldShowCheckOne ? "checkmark.rectangle" : "rectangle"), for: .normal)
        }
        
        self.questionLabel.text = poll?.question ?? ""
        self.pollByLabel.text = "Poll By \(poll?.createdBy ?? "")"
        self.optionOneLabel.text = "\(poll?.options.first?.text ?? "") (\(poll?.options.first?.count ?? 0))"
        if poll?.options.count ?? 0 > 1 {
            self.optionTwoLabel.text = "\(poll?.options[1].text ?? "") (\(poll?.options[1].count ?? 0))"
            if let checkTwoCount = poll?.options[1].count as? Int {
                let shouldShowCheckTwo = checkTwoCount > 0
                self.checkButtonTwo.setImage(UIImage(systemName: shouldShowCheckTwo ? "checkmark.rectangle" : "rectangle"), for: .normal)
            }
        }
    }
}
