//
//  DataContainer.swift
//  TestTabbed
//
//  Created by David Evans on 7/11/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseStorage
import Alamofire
import AlamofireImage

extension Notification.Name {
    static let reload = Notification.Name("reload")
    static let reloadStudents = Notification.Name("reloadStudents")
    static let checkAdminStatus = Notification.Name("checkAdminStatus")
    static let dismissSplash = Notification.Name("dismissSplash")
    static let updateCredits = Notification.Name("updateCredits")
}

class DataContainer {
    var images: Dictionary<String, UIImage> = Dictionary<String, UIImage>()
    func getImage(urlString:String) -> UIImage? {
        if let image = images[urlString] {
            return image
        } else {
            return nil
        }
    }
    var userImage: UIImage?
    var currentFullNameOfUser: NSString = ""
    var currentCreditsOfUser: NSInteger = 0
    var isCurrentUserAdmin: Bool = false
    var emailAddressChildKey: String = ""
    var ref: DatabaseReference!
    var numItems: NSInteger = 0
    var numExpiredItems: NSInteger = 0
    var numStudents: NSInteger = 0
    var items = [AuctionItem]()
    var expiredItems = [AuctionItem]()
    var students = [NSDictionary]()
    
    var hasInitialised: Bool = false
    
    var storage = Storage.storage()
    var storageRef: StorageReference!
    
    func observe() {
        if (!hasInitialised) {
            hasInitialised = true
            
            storageRef = storage.reference()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil);
            let auctionViewController: AuctionViewController = storyboard.instantiateViewController(withIdentifier: "AuctionViewController") as! AuctionViewController;
            let studentViewController: StudentViewController = storyboard.instantiateViewController(withIdentifier: "StudentViewController") as! StudentViewController;
            let expiredViewController: AuctionResultsController = storyboard.instantiateViewController(withIdentifier: "AuctionResultsController") as! AuctionResultsController;

            /* Auction Items */
            let itemsRef = self.ref.child("items")
            itemsRef.queryOrdered(byChild: "endDate").observe(.childAdded, with: { snapshot in
                let auctionItem = AuctionItem(from: (snapshot.value as? NSDictionary)!)
                if (!auctionItem.hasExpired()) {
                    self.items.append(auctionItem)
                    self.numItems += 1
                
                    if (auctionItem.image != "") {
                        self.getImageFromUrl(url:auctionItem.image,needsUpdate: true)
                    }

                    auctionViewController.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    NotificationCenter.default.post(name: .dismissSplash, object: nil)
                } else {
                    self.expiredItems.append(auctionItem)
                    self.numExpiredItems += 1
                    expiredViewController.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    //NotificationCenter.default.post(name: .dismissSplash, object: nil)
                }
            })
            
            itemsRef.queryOrdered(byChild: "name").observe(.childRemoved, with: { snapshot in
                let auctionItem = AuctionItem(from: (snapshot.value as? NSDictionary)!)
                let changedId = auctionItem.id
                var removedId = -1
                for (index, item) in self.items.enumerated() {
                    if (item.id == changedId) {
                        removedId = index
                    }
                }
                if (removedId != -1) {
                    self.items.remove(at:removedId)
                    self.numItems -= 1
                    auctionViewController.tableView.deleteRows(at: [IndexPath(row:removedId,section:0)], with: UITableViewRowAnimation.fade)
                    NotificationCenter.default.post(name: .reload, object: nil)

                }
            })
            
            
            itemsRef.queryOrdered(byChild: "name").observe(.childChanged, with: { snapshot in
                let auctionItem = AuctionItem(from: (snapshot.value as? NSDictionary)!)
                if (auctionItem.image != "") {
                    let image = self.getImage(urlString:auctionItem.image)
                    if (image==nil) {
                        self.getImageFromUrl(url:auctionItem.image,needsUpdate: true)
                    }
                }
               
                for (index, item) in self.items.enumerated() {
                    if (item.id == auctionItem.id) {
                        // is now expired ! - move to expired entries
                        if (auctionItem.hasExpired()) {
                            self.expiredItems.append(auctionItem)
                            self.numExpiredItems += 1
                            expiredViewController.tableView.insertRows(at: [IndexPath(row: self.items.count-1, section: 0)], with: .automatic)
                        } else {
                            self.items[index] = auctionItem
                        }
                        auctionViewController.tableView.reloadRows(at: [IndexPath(row:index,section:0)], with: .automatic)
                        NotificationCenter.default.post(name: .reload, object: nil)
                    }
                }
            })

            
            
            /* Students */
            let studentsRef = self.ref.child("users")
            studentsRef.queryOrdered(byChild: "displayName").observe(.childAdded, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                self.students.append(value!)
                self.numStudents += 1
                
                let img = value?["image"] as? String ?? ""
                studentViewController.tableView.insertRows(at: [IndexPath(row: self.students.count-1, section: 0)], with: .automatic)
                NotificationCenter.default.post(name: .reloadStudents, object: nil)
                self.getImageFromUrl(url:img,needsUpdate: true)
            })
            studentsRef.queryOrdered(byChild: "name").observe(.childChanged, with: { snapshot in
                let value = snapshot.value as? NSDictionary
                let img = value?["image"] as? String ?? ""
                let image = self.getImage(urlString:img)
                if (image==nil) {
                    self.getImageFromUrl(url:img,needsUpdate: true)
                }
                let changedId = value?["email"] as? String ?? ""
                for (index, item) in self.students.enumerated() {
                    let id = item["email"] as? String ?? ""
                    if (id == changedId) {
                        self.students[index] = value!
                        studentViewController.tableView.reloadRows(at: [IndexPath(row:index,section:0)], with: .automatic)
                        NotificationCenter.default.post(name: .reloadStudents, object: nil)
                    }
                    
                }
                
                
            })
            
        }
    }
    
    func addAuctionItem(description: String, image: UIImage, minBid: String, firstComeFirstServe: Bool, expiry: Date, id: String? = nil) -> StorageUploadTask {
        var data = Data()
        data = UIImageJPEGRepresentation(image, 0.8)! as Data
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        var uuid = UUID().uuidString
        if id != nil {
            uuid = id!
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'"
        let endTime = formatter.string(from: expiry)
        print (endTime)
        let imageRef = storageRef.child("items").child(uuid + "/image.jpg")
        
        let uploadTask = imageRef.putData(data,metadata:metaData) { (metadata,error) in
            guard let metadata = metadata else {
                return
            }
            // file has been uploaded
            let downloadURL = metadata.downloadURL()
            //let imgFromUrl = downloadURL.absoluteString
            //print (downloadURL?.absoluteString)
            self.ref.child("items").child(uuid + "/img").setValue(downloadURL?.absoluteString)
            self.ref.child("items").child(uuid + "/name").setValue(description)
            if id == nil {
                self.ref.child("items").child(uuid + "/bid").setValue(0)
                self.ref.child("items").child(uuid + "/id").setValue(uuid)
            }
            self.ref.child("items").child(uuid + "/buyout").setValue(200000)
            self.ref.child("items").child(uuid + "/endDate").setValue(endTime)
            self.ref.child("items").child(uuid + "/firstComeFirstServe").setValue(firstComeFirstServe)

            self.ref.child("items").child(uuid + "/minBid").setValue(Int(minBid))
        }
        return uploadTask
        
    }

    func getImageFromUrl(url:String, needsUpdate:Bool) {

        Alamofire.request(url).responseImage { response in
            //print(url)
            //print (response)
            //print("------------------------------------------")
            if let image = response.result.value {
                let originalUrl = response.request?.url?.absoluteString
                dataContainer.images[originalUrl!] = image
                if (needsUpdate) {
                    NotificationCenter.default.post(name: .reload, object: nil)
                }
             }
        }
    }

    
}
