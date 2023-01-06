
//MARK: - Here we implemet FirebaseAuth, FirebaseCore, FirebaseFirestore, IQKeyboardManagerSwift, libraries with documentation.

// AppDelegate.swift
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
//import IQKeyboardManagerSwift
import FBSDKCoreKit
import GoogleSignIn


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    
    FirebaseApp.configure()
    
    let db = Firestore.firestore()
    print(db)
//  IQKeyboardManager.shared.enable = true
//  IQKeyboardManager.shared.enableAutoToolbar = false
//  IQKeyboardManager.shared.shouldResignOnTouchOutside = true

  let navigationBarAppearance = UINavigationBarAppearance()
                navigationBarAppearance.titleTextAttributes = [
                  NSAttributedString.Key.foregroundColor : UIColor.white
                ]
                navigationBarAppearance.backgroundColor = UIColor(named: K.BrandColors.purple)
                UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    
    ApplicationDelegate.shared.application(
        application,
        didFinishLaunchingWithOptions: launchOptions
    )
  
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self

    return true
}
      
func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    ApplicationDelegate.shared.application(
        app,
        open: url,
        sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
        annotation: options[UIApplication.OpenURLOptionsKey.annotation]
    )
    
    return GIDSignIn.sharedInstance().handle(url,
                                sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                annotation: [:])
}
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    
        guard error == nil else {
            print("failed to sign with google \(error.localizedDescription)")
            return
        }

        print("Did sign in with google with \(user)")
        
        guard let email = user.profile.email, let nikname = user.profile.name else { return }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set(nikname, forKey: "name")
        
        DatabaseManeger.share.validateNewUser(with: email) { exist in
            if !exist {
                let userData = UserData(userNikName: nikname, userEmail: email)
                DatabaseManeger.share.insertUser(with: userData) { success in
                    if success {
                        //upload image
                        
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { data, _, error in
                                guard let data = data else {
                                    print("failed to get data from facebook ")
                                    return
                                }
                                
                                print("got data from facebook uploading... ")
                                
                                let fileName = userData.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, filename: fileName) { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error \(error)")
                                    }
                                }
                            }.resume()
                        } else {
                            print("there no user image from google")
                        }
                    }
                }
            }
        }
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of user ")
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { authresults, error in
            guard authresults != nil, error == nil else {
                print("failed with google login credential")
                return
            }
            
           
            
            print("sucessfully sing in with google")
            NotificationCenter.default.post(name: .didlogInNotification, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("google user was disconected")
        
    }

}
