//
//  SplashScreen.swift
//  TestTabbed
//
//  Created by David Evans on 7/16/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import GoogleSignIn

class SplashScreen: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(dismissSplash), name: .dismissSplash, object: nil)
    }
    
    @IBAction func loginPressed(_ sender: Any) {


    }
    func dismissSplash() {
        NotificationCenter.default.removeObserver(self,name: .dismissSplash,object:nil)
        print("dismiss")
        dismiss(animated: true, completion: nil)
    }
   
    
}
