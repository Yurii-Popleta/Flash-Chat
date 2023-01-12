
import UIKit
import FirebaseAuth

class WelcomeViewController: UIViewController {

  @IBOutlet weak var titleLabel: UILabel!
    
    //MARK: - Here we turn off navigationController because we dont need this on this screen.
    
    var trust = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
        titleLabel.text = ""
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        var charIndex = 0.0
        
        let titleText = K.appName
        for letter in titleText {
            Timer.scheduledTimer(withTimeInterval: 0.15 * charIndex, repeats: false) { timer in
                self.titleLabel.text?.append(letter)
            }
            charIndex += 1
        }
        validateAuth()
    }
    
    //MARK: - Here we create welcome text animation, that looks like typing text.
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser != nil {
            trust = true
            self.performSegue(withIdentifier: "userAlreadyRegister", sender: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        if trust {
            self.navigationController!.navigationBar.isHidden = true
        }
    }
    
}
