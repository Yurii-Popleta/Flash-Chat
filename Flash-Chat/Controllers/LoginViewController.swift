
//MARK: - Here we implement FirebaseAuth for sign in our users.

import UIKit
import FirebaseCore
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController, GIDSignInUIDelegate {
   
   @IBOutlet weak var emailTextfield: UITextField!
   @IBOutlet weak var passwordTextfield: UITextField!
   @IBOutlet weak var errorMessage: UILabel!
   @IBOutlet weak var logInOutlet: UIButton!
   @IBOutlet weak var signInButton: GIDSignInButton!
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var truth = false
    
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
           strongSelf.truth = true
           strongSelf.performSegue(withIdentifier: K.loginSegue, sender: strongSelf)
        }
        
        GIDSignIn.sharedInstance()?.uiDelegate = self
        
        facebookButton.delegate = self
        navigationController?.navigationBar.tintColor = UIColor(named: K.BrandColors.lightPurple)
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if truth {
            navigationController!.navigationBar.isHidden = true
        }
    }
    
//MARK: - Here we give the opportunity to sign in user based on what email and password he wrote we send this data in FireBase database and if login was success we move this user on the chat screen.
    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let email = emailTextfield.text, let password = passwordTextfield.text {
            
            spinner.show(in: view)
            
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            
            if let e = error {
                self.errorMessage.text = e.localizedDescription
                self.passwordTextfield.text = ""
                self.emailTextfield.text = ""
            } else {
                let safeEmail = DatabaseManeger.safeEmail(emailAdres: email)
                DatabaseManeger.share.getDataFor(path: safeEmail) { results in
                    switch results {
                    case .success(let data):
                        guard let userData = data as? [String: Any], let nikName = userData["userNik"] as? String else {
                            return
                        }
                        UserDefaults.standard.set("\(nikName)", forKey: "name")
                    case .failure(let error):
                        print("failed to read data with error \(error)")
                    }
                }
                self.truth = true
                UserDefaults.standard.set(email, forKey: "email")
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
        
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start { connecting, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("failed ti make facebook graph request")
                return
            }
            
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("failed to get name and email from fb result")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set(userName, forKey: "name")
            
            DatabaseManeger.share.validateNewUser(with: email) { exist in
              if !exist  {
                  let userData = UserData(userNikName: userName, userEmail: email)
                  DatabaseManeger.share.insertUser(with: userData) { success in
                      if success {
                          //upload image
                          guard let url = URL(string: pictureUrl) else {
                              return
                          }
                          
                          print("Downloading data from facebook image")
                          
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
                      }
                  }
               }
            }
                                              
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            self.spinner.show(in: self.view)
            Auth.auth().signIn(with: credential) { results, error in
                guard results != nil, error == nil else {
                     print("Facebook credential login failed ")
                    return
                }
                DispatchQueue.main.async {
                    self.spinner.dismiss()
                }
                self.truth = true
                self.performSegue(withIdentifier: K.loginSegue, sender: self)
                print("Successfuly logged user in")
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }

}
