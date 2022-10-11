
//MARK: - Here we implement FirebaseAuth for sign in our users.

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

   @IBOutlet weak var emailTextfield: UITextField!
   @IBOutlet weak var passwordTextfield: UITextField!
   @IBOutlet weak var errorMessage: UILabel!
    
//MARK: - Here we make our UINavigationBar without color and set the color for navigation buttons.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.lightPurple)
        UINavigationBar.appearance().scrollEdgeAppearance = .none
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
