    
//MARK: - Here we implement FirebaseAuth for register our users.

 import UIKit
 import FirebaseAuth

  class RegisterViewController: UIViewController {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var errorMassege: UILabel!
    
 //MARK: - Here we make our UINavigationBar without color and set the color for navigation buttons.
      
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.blue)
        UINavigationBar.appearance().scrollEdgeAppearance = .none
    }

 //MARK: - Here we register user based on what email and password he wrote we send this data in FireBase database and if register was success we move this user on the chat screen.
      
    @IBAction func registerPressed(_ sender: UIButton) {
        if let email = emailTextfield.text, let password = passwordTextfield.text {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let e = error {
                self.errorMassege.text = e.localizedDescription
                self.passwordTextfield.text = ""
                self.emailTextfield.text = ""
            } else {
                self.performSegue(withIdentifier: K.registerSegue, sender: self)
                self.errorMassege.text = ""
                }
            }
        }
    }
}
