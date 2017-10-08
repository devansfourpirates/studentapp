//
//  AppDelegate.swift
//  TestTabbed
//
//  Created by David Evans on 7/10/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn


var dataContainer: DataContainer = DataContainer()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print ("\(user.displayName) logged in")
            } else {
                print ("not logged in")
            }
        }
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /* Firebase Functions */
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
            
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {

        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential) { (user, error) in
            
            if let error = error {
                print (error.localizedDescription)
                return
            }
            
            NotificationCenter.default.post(name: .dismissSplash, object: nil)
            
            let userInfo = user?.providerData[0]
            dataContainer.currentFullNameOfUser = userInfo?.displayName! as! NSString ?? ""
            dataContainer.ref = Database.database().reference()
            let emailAddress = userInfo?.email
            let displayName = userInfo?.displayName
            
            dataContainer.emailAddressChildKey = emailAddress!.replacingOccurrences(of: ".", with: ",") as String
            let formatter = DateFormatter()
            formatter.dateStyle = DateFormatter.Style.long
            formatter.timeStyle = DateFormatter.Style.medium
            let dateString = formatter.string(from: Date())
            

            
            //let storyboard = UIStoryboard(name: "Main", bundle: nil);
            //let auctionViewController: AuctionViewController = storyboard.instantiateViewController(withIdentifier: "AuctionViewController") as! AuctionViewController;
            
            let imageURL = userInfo?.photoURL?.absoluteString
            
            // keep an eye on the credits for this user
            let creditsRef = dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey).child("credits")
            creditsRef.observe(DataEventType.value, with: { (snapshot) in
                var newCredits = 0
                if !snapshot.exists() {
                    newCredits = 0
                } else {
                    newCredits = snapshot.value as! NSInteger
                }
                dataContainer.currentCreditsOfUser = newCredits
                NotificationCenter.default.post(name: .updateCredits, object: nil)
            })
            
            let adminRef = dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey).child("isAdmin")

            adminRef.observe(DataEventType.value, with: { (snapshot) in
                if !snapshot.exists() {
                    dataContainer.isCurrentUserAdmin = false
                } else {
                    dataContainer.isCurrentUserAdmin = snapshot.value as! Bool
                }
                NotificationCenter.default.post(name: .checkAdminStatus, object: nil)
                
            })
            
            dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/email").setValue(emailAddress)
            dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/displayName").setValue(displayName)
            dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/image").setValue(imageURL)
            dataContainer.ref.child("users").child(dataContainer.emailAddressChildKey + "/lastLogin").setValue(dateString)

            
            dataContainer.observe()
            
        }
        
        
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("logout")
    }

    
    
    
}

