
//MARK: - Here we implemet FirebaseAuth, FirebaseCore, FirebaseFirestore, IQKeyboardManagerSwift, libraries with documentation.

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import IQKeyboardManagerSwift

//MARK: - Here we put FirebaseApp.configure() with Firebase documentation, and create test FireBase database, and also set the IQKeyboardManagerSwift for keyboard, and set navigation bar.

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
          FirebaseApp.configure()
          let db = Firestore.firestore()
          print(db)
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true

        let navigationBarAppearance = UINavigationBarAppearance()
                      navigationBarAppearance.titleTextAttributes = [
                        NSAttributedString.Key.foregroundColor : UIColor.white
                      ]
                      navigationBarAppearance.backgroundColor = UIColor(named: K.BrandColors.purple)
                      UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    
}

