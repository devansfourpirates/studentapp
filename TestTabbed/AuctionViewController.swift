//
//  FirstViewController.swift
//  TestTabbed
//
//  Created by David Evans on 7/10/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class AuctionTableViewCell: UITableViewCell {
    
    var auctionItem: AuctionItem = AuctionItem()
    
    @IBOutlet weak var minBid: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var currentBid: UILabel!
    @IBOutlet weak var bidder: UILabel!
    @IBOutlet weak var expiry: UILabel!
    @IBOutlet weak var clockImage: UIImageView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var numBids: UILabel!
    @IBOutlet weak var quickBidButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBAction func editButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let auctionViewController: UINavigationController = storyboard.instantiateViewController(withIdentifier: "EditDetailNavigationViewController") as! UINavigationController;
        let detailViewcontroller = auctionViewController.viewControllers[0] as! EditDetailViewController
        detailViewcontroller.auctionItem = self.auctionItem
        UIApplication.shared.keyWindow?.rootViewController?.present(auctionViewController, animated: true)
    }

    @IBAction func quickBid(_ sender: Any) {
        
        var newBid = 0
        
        if (auctionItem.bid > 0) {
            newBid = auctionItem.bid + 5
        } else {
            newBid = auctionItem.minBid + 5
        }
        
        let alert = UIAlertController(title: "Bid Placed", message: "Bid placed for \(newBid)", preferredStyle: .alert)
        if (newBid <= dataContainer.currentCreditsOfUser) {
            
            let confirmAlert = UIAlertController(title: "Bid", message: "Bid \(newBid) on this item?", preferredStyle: UIAlertControllerStyle.alert)
            
            confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                dataContainer.ref.child("items").child(self.auctionItem.id).updateChildValues(["bid":newBid,"bidderKey":dataContainer.emailAddressChildKey,"bidder":dataContainer.currentFullNameOfUser,"numberOfBids": self.auctionItem.numberOfBids + 1 ])
                if self.auctionItem.bid > 0 && dataContainer.emailAddressChildKey != self.auctionItem.bidderKey && self.auctionItem.bidderKey != "" {
                    // credit back the old bidder
                    dataContainer.ref.child("users").child(self.auctionItem.bidderKey).observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        let bidderCredits = value?["credits"] as? Int ?? 0
                        dataContainer.ref.child("users").child(self.auctionItem.bidderKey + "/credits").setValue(bidderCredits + self.auctionItem.bid)
                    })
                }
                // decrease the new bidder
                if dataContainer.emailAddressChildKey != self.auctionItem.bidderKey {
                    dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/credits").setValue(dataContainer.currentCreditsOfUser - newBid)
                } else {
                    dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/credits").setValue(dataContainer.currentCreditsOfUser - newBid + self.auctionItem.bid)
                }
            }))
            
            confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                //print("Handle Cancel Logic here")
            }))

            UIApplication.shared.keyWindow?.rootViewController?.present(confirmAlert, animated: true, completion: nil)
            
            
            
        } else {
            alert.title = "Bid Failed"
            alert.message = "Not enough credits, you have \(String(dataContainer.currentCreditsOfUser))"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
    }
}


class AuctionViewController: UITableViewController, UISearchResultsUpdating {

    var expiryCheckTimer: Timer!
    var alertController: UIAlertController? = nil
    let searchController = UISearchController(searchResultsController: nil)
    var filteredItems = [AuctionItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

       // alertController = Util.showWaiting(viewController: self)
        
        
        myCredits.title = "0"
        

        self.tableView.backgroundView = UIImageView(image: UIImage(named: "nwa_blur"))
        self.tableView.estimatedRowHeight = 280
        self.tableView.rowHeight = UITableViewAutomaticDimension
        expiryCheckTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(runExpiryCheck), userInfo: nil, repeats: true)
        
        if let font = UIFont(name: "Quicksand", size: 22) {
            self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName:font]
        }
    }
    
    @IBOutlet weak var addButton: UIBarButtonItem!

    @IBOutlet weak var myCredits: UIBarButtonItem!
    func runExpiryCheck() {
        
        // check for expired entries
        // if there's an expired entry, means we received it before it was expired and now it it IS expired
        // only do it if NOT looking at search results
        
        if !searchController.isActive || searchController.searchBar.text == "" {
            for (index,item) in dataContainer.items.enumerated() {
                if item.hasExpired() {
                    dataContainer.items.remove(at:index)
                    dataContainer.numItems -= 1
                    self.tableView.deleteRows(at: [IndexPath(row:index,section:0)], with: UITableViewRowAnimation.fade)
   
                }
            }
        }
        
        //reload the table so it recalculates the time to expiry string
        tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        expiryCheckTimer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkAdminStatus), name: .checkAdminStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCredits), name: .updateCredits, object: nil)
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true

        tableView.tableHeaderView = searchController.searchBar
        
    }
    
    func updateCredits() {
            myCredits.title = String(dataContainer.currentCreditsOfUser)
    }
    
    func checkAdminStatus() {
        if (dataContainer.isCurrentUserAdmin) {
            self.addButton.isEnabled = true
        } else {
            self.addButton.isEnabled = false
        }
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredItems = dataContainer.items.filter { value in
            return (value.name.lowercased().range(of:searchText.lowercased()) != nil)
        }
        tableView.reloadData()
    }

    @available(iOS 8.0, *)
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func reloadTableData(_ notification: Notification) {
        tableView.reloadData()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredItems.count
        }
        return dataContainer.numItems
    }
    
    func getItem(indexPath: IndexPath) -> AuctionItem {
        let value : AuctionItem
        
        if searchController.isActive && searchController.searchBar.text != "" {
            value = filteredItems[indexPath.row]
        } else {
            value = dataContainer.items[indexPath.row]
        }
        return value
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        Util.dismissWaiting()

        let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath) as! AuctionTableViewCell
        cell.mainView.layer.cornerRadius = 10;
        cell.mainView.layer.masksToBounds = true;
        let value = self.getItem(indexPath: indexPath)
        cell.auctionItem = value

        if (value.firstComeFirstServe) {
            cell.clockImage.image = UIImage(named: "ic_alarm_off")
            cell.expiry.text = "Bid now"
        } else {

                let calendar = NSCalendar.current
                let diff = calendar.dateComponents([.year, .month, .day, .hour, .minute],from:Date(),to:value.endDate)
                var expiryText = ""

                let months = String(describing: diff.month!)
                let days = String(describing: diff.day!)
                let hours = String(describing: diff.hour!)
                let minutes = String(describing: diff.minute!)
                        
                if (diff.minute! < 0 || diff.hour! < 0) { // expired
                    cell.expiry.text = "Expired"
                    cell.clockImage.image = UIImage(named: "ic_block")
                } else {
                    cell.clockImage.image = UIImage(named: "ic_alarm")
                    expiryText = minutes + "m"
                    if (diff.hour != 0) {
                        expiryText = hours + "h:" + expiryText
                    }
                    if (diff.day! > 2) {
                        expiryText = days + " days"
                    } else if (diff.day! > 0) {
                        expiryText = days + "d:" + expiryText
                    }
                    if (diff.month != 0) {
                        expiryText = months + " mths, " + days + " days"
                    }
                    cell.expiry.text = expiryText
                }
        }

        cell.label?.text = value.name
        cell.currentBid.text = String(value.bid)
        if value.bidder == "" {
            cell.bidder.text = "No bids yet"
            cell.numBids.text = ""
        } else {
            cell.bidder.text = value.bidder
            cell.numBids.text = "\(value.numberOfBids) bids"
        }
        
        cell.minBid.text = String(value.minBid)
        cell.itemImageView?.image = nil
        if (value.image != "") {
            let image = dataContainer.getImage(urlString: value.image)
            if (image != nil) {
                cell.itemImageView?.image = image
            }
        }
        
        var quickBidAmount = 0
        
        if (value.bid > 0) {
            quickBidAmount = value.bid + 5
        } else {
            quickBidAmount = value.minBid + 5
        }
        
        if !dataContainer.isCurrentUserAdmin {
            cell.editButton.isHidden = true
        } else {
            cell.editButton.isHidden = false
        }
        
        //cell.quickBidButton.titleLabel?.text = "Bid \(quickBidAmount)"
        
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Main",bundle:Bundle.main)
        let destination = storyboard.instantiateViewController(withIdentifier:"ItemDetailViewController") as! ItemDetailViewController
        let value = self.getItem(indexPath: indexPath)
        destination.item = value
        
        navigationController?.pushViewController(destination, animated: true)
        
        
    }
}

