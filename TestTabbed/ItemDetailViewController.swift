//
//  ItemDetailViewController.swift
//  TestFirebaseApp
//
//  Created by David Evans on 6/19/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import FirebaseDatabase

class ItemDetailViewController: UIViewController,UITextFieldDelegate {
    
    var item: AuctionItem = AuctionItem()
    
    @IBOutlet weak var lblName: UILabel!


    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var currentBidder: UILabel!
    @IBOutlet weak var currentBidAmount: UILabel!
    @IBOutlet weak var txtBidAmount: UITextField!
    @IBOutlet weak var form: UIView!
    @IBOutlet weak var minBidAmount: UILabel!
    
    @IBOutlet weak var bidStepper: UIStepper!
    @IBAction func swipeGesture(_ sender: Any) {
        dismiss(animated:true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "nwa_blur")?.draw(in: self.view.bounds)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        self.view.backgroundColor = UIColor(patternImage: image)
        
       
        
        txtBidAmount.delegate = self
        lblName.text = item.name
        let imgurl = item.image
        itemImage.image = dataContainer.getImage(urlString:imgurl)
 
        form.layer.cornerRadius = 8.0
        form.layer.borderColor = UIColor.black.cgColor
        form.layer.borderWidth = 1.5

        
        itemImage.layer.cornerRadius = 8.0
        itemImage.layer.borderColor = UIColor.black.cgColor
        itemImage.layer.borderWidth = 1.5
        
        itemImage.layer.shadowOffset = CGSize(width: 5.0, height: 5.0)
        itemImage.layer.shadowColor = UIColor.darkGray.cgColor
        itemImage.layer.shadowRadius = 5
        itemImage.layer.shadowOpacity = 0.5
        //itemImage.clipsToBounds = false
        
        let currentBid = item.bid
        let minBid = item.minBid
        var currentBidderName = item.bidder
        if (currentBidderName == "") {
            currentBidderName = "No bids yet"
        }
        currentBidder.text = currentBidderName
        currentBidAmount.text = String(currentBid)
        
        if (currentBid > 0) {
            txtBidAmount.text = String(currentBid + 5)
            bidStepper.value = Double(currentBid) + 5.0
            bidStepper.minimumValue = Double(currentBid + 1)
            minBidAmount.text = String(currentBid + 1)
        } else {
            txtBidAmount.text = String(minBid + 5)
            bidStepper.value = Double(minBid) + 5.0
            bidStepper.minimumValue = Double(minBid + 1)
            minBidAmount.text = String(minBid + 1)
        }
        
        
    }

    @IBAction func stepperAction(sender: AnyObject) {
        txtBidAmount.text = "\(Int(bidStepper.value))"
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (txtBidAmount.text! as NSString).replacingCharacters(in: range, with: string)
        if let intAmount = Int(text) {
            if intAmount < 1000 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
        
    }
    @IBAction func placeBid(_ sender: Any) {
        let bidAmount = Int(self.txtBidAmount.text!) ?? 0
        let requestedBidAmount = txtBidAmount.text
        let alert = UIAlertController(title: "Bid Placed", message: "Bid placed for \(requestedBidAmount ?? "")", preferredStyle: .alert)
        
        if (bidAmount <= dataContainer.currentCreditsOfUser) {
            //dataContainer.ref.child("items").child(self.item.id).updateChildValues(["bid":bidAmount,"bidder":dataContainer.currentFullNameOfUser])

            
            let confirmAlert = UIAlertController(title: "Bid", message: "Bid \(bidAmount) on this item?", preferredStyle: UIAlertControllerStyle.alert)
            
            confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                dataContainer.ref.child("items").child(self.item.id).updateChildValues(["bid":bidAmount,"bidderKey":dataContainer.emailAddressChildKey,"bidder":dataContainer.currentFullNameOfUser,"numberOfBids": self.item.numberOfBids + 1 ])
                if self.item.bid > 0 && dataContainer.emailAddressChildKey != self.item.bidderKey && self.item.bidderKey != "" {
                    // credit back the old bidder
                    dataContainer.ref.child("users").child(self.item.bidderKey).observeSingleEvent(of: .value, with: { (snapshot) in
                        let value = snapshot.value as? NSDictionary
                        let bidderCredits = value?["credits"] as? Int ?? 0
                        dataContainer.ref.child("users").child(self.item.bidderKey + "/credits").setValue(bidderCredits + self.item.bid)
                    })
                }
                // decrease the new bidder
                if dataContainer.emailAddressChildKey != self.item.bidderKey {
                    dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/credits").setValue(dataContainer.currentCreditsOfUser - bidAmount)
                } else {
                    dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/credits").setValue(dataContainer.currentCreditsOfUser - bidAmount + self.item.bid)
                }
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action: UIAlertAction!) in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true)
            }))
            
            confirmAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                //print("Handle Cancel Logic here")
            }))
            
            self.present(confirmAlert, animated: true, completion: nil)
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            alert.title = "Bid Failed"
            alert.message = "Not enough credits, you have \(String(dataContainer.currentCreditsOfUser))"
            present(alert, animated: true)
        }
    }
}
