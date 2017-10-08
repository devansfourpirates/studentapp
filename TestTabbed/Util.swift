//
//  Util.swift
//  TestTabbed
//
//  Created by David Evans on 7/21/17.
//  Copyright © 2017 David Evans. All rights reserved.
//
import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        print("kb dismiss")
        view.endEditing(true)
    }
}

class Util {
    
    static var waitingAlertController: UIAlertController? = nil
    
    static func dismissWaiting() {
        if waitingAlertController != nil {
            waitingAlertController?.dismiss(animated: false, completion: nil)
            waitingAlertController = nil
        }
        
    }
    
    static func showWaiting(viewController: UIViewController) {
        waitingAlertController = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        waitingAlertController?.view.addSubview(loadingIndicator)
        viewController.present(waitingAlertController!, animated: true, completion: nil)
    }
}
