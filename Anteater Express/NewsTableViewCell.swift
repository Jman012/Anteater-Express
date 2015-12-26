//
//  NewsTableViewCell.swift
//  Anteater Express
//
//  Created by Eric Shively on 12/23/15.
//
//

import Foundation

class NewsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var date: UILabel!
    
    override func prepareForReuse() {
        title.text = nil
        info.text = nil
        date.text = nil
    }
}