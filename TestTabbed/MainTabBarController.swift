//
//  MainTabBarController.swift
//  TestTabbed
//
//  Created by David Evans on 7/22/17.
//  Copyright © 2017 David Evans. All rights reserved.
//
import UIKit
import GoogleSignIn
import FirebaseAuth

class MainTabBarController :  UITabBarController, GIDSignInUIDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        
        if (signIn.hasAuthInKeychain()) { // the user is signed in, and the delegate doesn't need to show the signin screen
            Util.showWaiting(viewController: self)
        }
    }
 
}
