
import UIKit
import FirebaseAuth

class WelcomeViewController: UIViewController {

  @IBOutlet weak var titleLabel: UILabel!
    
    //MARK: - Here we turn off navigationController because we dont need this on this screen.
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    //MARK: - Here we create welcome text animation, that looks like typing text.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = ""
        var charIndex = 0.0
        
        let titleText = K.appName
        for letter in titleText {
            Timer.scheduledTimer(withTimeInterval: 0.1 * charIndex, repeats: false) { timer in
                self.titleLabel.text?.append(letter)
            }
            charIndex += 1
        }
        validateAuth()
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "userAlreadyRegister", sender: self)
        }
    }
}
