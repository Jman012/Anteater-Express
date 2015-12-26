//
//  NewsTableViewController.swift
//  Anteater Express
//
//  Created by Eric Shively on 12/23/15.
//
//

import Foundation

class NewsTableViewController: UIViewController {
    
    @IBOutlet weak var newsTableView: UITableView!
    
    override func viewDidLoad() {
        newsTableView.delegate = self
        newsTableView.dataSource = self
    }
}

extension NewsTableViewController: UITableViewDataSource {
    
}

extension NewsTableViewController: UITableViewDelegate {
    
}