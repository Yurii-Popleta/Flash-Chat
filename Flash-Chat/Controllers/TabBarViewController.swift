//
//  TabBarViewController.swift
//  Flash-Chat
//
//  Created by Admin on 03/12/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class TabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    

    @IBAction func logOutButton(_ sender: UIBarButtonItem) {
       
        //LOG OUT FACEBOOK
        FBSDKLoginKit.LoginManager().logOut()
        
        GIDSignIn.sharedInstance().signOut()
        
        //LOG OUT FIREBASE
        do {
          try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
            }
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
