//
//  SecondViewController.swift
//  TestTabbed
//
//  Created by David Evans on 7/10/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit

class StudentTableViewCell: UITableViewCell {
    
    var student: NSDictionary = NSDictionary()
    
    @IBOutlet weak var adminImage: UIImageView!
    @IBOutlet weak var studentImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var credits: UILabel!
    
    @IBOutlet weak var add1CreditButton: UIButton!
    @IBOutlet weak var add5CreditsButton: UIButton!
    
    func set(from: NSDictionary) {
        student = from
    }
    
    func addCredits(numberOfCredits:Int) {
        let email = student["email"] as! String
        let emailAddressChildKey = email.replacingOccurrences(of: ".", with: ",")
        var newCredits = 0
        if let currentCredits = student["credits"] as? NSInteger {
            newCredits = currentCredits + numberOfCredits
        } else {
            newCredits = numberOfCredits
        }
        
        dataContainer.ref.child("users").child(emailAddressChildKey).updateChildValues(["credits":newCredits])
        
        var suffix = ""
        if numberOfCredits > 1 {
            suffix = "s"
        }
        
        let alert = UIAlertController(title: "Credit Added", message: "\(numberOfCredits) credit\(suffix) added", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true)
        
    }
    
    @IBAction func addOneCredit(_ sender: Any) {
        addCredits(numberOfCredits: 1)
        
    }
    @IBAction func addFiveCredits(_ sender: Any) {
        addCredits(numberOfCredits: 5)
    }
}

class StudentViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reloadStudents, object: nil)

        self.tableView.backgroundView = UIImageView(image: UIImage(named: "nwa_blur"))
        self.tableView.estimatedRowHeight = 280
        self.tableView.rowHeight = UITableViewAutomaticDimension
        if let font = UIFont(name: "Quicksand", size: 22) {
            self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName:font]
        }
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataContainer.numStudents
    }
   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Student", for: indexPath) as! StudentTableViewCell

        //cell.mainView.layer.cornerRadius = 10;
        //cell.mainView.layer.masksToBounds = true;
        
        let value = dataContainer.students[indexPath.row]
        cell.set(from: value)
        
        let displayName = value["displayName"] as? String ?? ""
        let email = value["email"] as? String ?? ""
        let imgurl = value["image"] as? String ?? ""
        var currentCredits = 0
        if let credits = value["credits"] as? NSInteger {
            currentCredits = credits
        } else {
            currentCredits = 0
        }
        cell.name?.text = displayName
        cell.email?.text = email
        cell.credits?.text = String(currentCredits)

        let image = dataContainer.getImage(urlString: imgurl)
        if (image != nil) {
            cell.studentImage?.image = image
        }
        
        if (dataContainer.isCurrentUserAdmin) {
            cell.add1CreditButton.isEnabled = true
            cell.add5CreditsButton.isEnabled = true
        } else {
            cell.add1CreditButton.isEnabled = false
            cell.add5CreditsButton.isEnabled = false
        }
    
        cell.studentImage.layer.cornerRadius = cell.studentImage.frame.size.height / 2
        cell.studentImage.layer.masksToBounds = true
        cell.studentImage.layer.borderWidth = 0
        let isAdmin = value["isAdmin"] as? Bool ?? false
        if (!isAdmin) {
            cell.adminImage?.image = UIImage(named: "ic_account_circle")
        }
        
        return cell
    }
}

