//
//  SettingsMenu.swift
//  TestTabbed
//
//  Created by David Evans on 7/22/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn

class SettingsMenu : UITableViewController {

    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func logoutButtonPressed(_ sender: Any) {
        dismiss(animated: false)
        GIDSignIn.sharedInstance().signOut()
    }
}
