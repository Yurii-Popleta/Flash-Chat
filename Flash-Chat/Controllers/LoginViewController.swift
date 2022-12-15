
//MARK: - Here we implement FirebaseAuth for sign in our users.

import UIKit
import FirebaseCore
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class LoginViewController: UIViewController, GIDSignInUIDelegate {

   @IBOutlet weak var emailTextfield: UITextField!
   @IBOutlet weak var passwordTextfield: UITextField!
   @IBOutlet weak var errorMessage: UILabel!
   @IBOutlet weak var logInOutlet: UIButton!

    @IBOutlet weak var signInButton: GIDSignInButton!
    
    
    
    private let facebookButton: FBLoginButton = {
        
     let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    
//MARK: - Here we make our UINavigationBar without color and set the color for navigation buttons.
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didlogInNotification, object: nil, queue: .main) { [weak self] _ in
           guard let strongSelf = self else {
               return
           }
           
           strongSelf.performSegue(withIdentifier: K.loginSegue, sender: strongSelf)
        }
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        facebookButton.delegate = self
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.lightPurple)
        UINavigationBar.appearance().scrollEdgeAppearance = .none

        
        facebookButton.frame = CGRect(x: (self.view.frame.size.width - 110) / 2, y: facebookButton.frame.origin.y+370 , width: 110, height: 40)
        facebookButton.center = view.center
      // loginButton.frame.origin.y = logInOutlet.frame.origin.y-20
              view.addSubview(facebookButton)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
//MARK: - Here we give the opportunity to sign in user based on what email and password he wrote we send this data in FireBase database and if login was success we move this user on the chat screen.
    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextfield.text, let password = passwordTextfield.text {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let e = error {
                self.errorMessage.text = e.localizedDescription
                self.passwordTextfield.text = ""
                self.emailTextfield.text = ""
            } else {
                self.performSegue(withIdentifier: K.loginSegue, sender: self)
                self.errorMessage.text = ""
            }
          }
       }
    }
 }


extension LoginViewController: LoginButtonDelegate {
   
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("user fail to login to facebook")
            return
        }
        
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, name"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start { connecting, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("failed ti make facebook graph request")
                return
            }
            
            guard let userName = result["name"] as? String, let email = result["email"] as? String else {
                print("failed to get name and email from fb result")
                return
            }
            
            DatabaseManeger.share.validateNewUser(with: email) { exist in
              if !exist  {
                  DatabaseManeger.share.insertUser(with: DatabaseManeger.UserData(userNikName: userName, userEmail: email))
                }
            }
            
           
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            Auth.auth().signIn(with: credential) { results, error in
                guard results != nil, error == nil else {
                     print("Facebook credential login failed ")
                    return
                }
                self.performSegue(withIdentifier: K.loginSegue, sender: self)
                print("Successfuly logged user in")
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }

}
