//
//  AuctionResultsController.swift
//  TestTabbed
//
//  Created by David Evans on 7/19/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit

class AuctionResultsController : UITableViewController {
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataContainer.numExpiredItems
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpiredItem", for: indexPath)
        let value = dataContainer.expiredItems[indexPath.row]
        cell.textLabel?.text = value.name
        cell.detailTextLabel?.text = value.bidder
        return cell
    }
}
