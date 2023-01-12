
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage


class ProfileViewController: UIViewController {
  
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nikName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nikName.text = UserDefaults.standard.value(forKey: "name") as? String ?? "no name"
        userEmail.text = UserDefaults.standard.value(forKey: "email") as? String ?? "no email"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(LogoutTapped))
        navigationItem.rightBarButtonItem?.tintColor = .black
        createImage()
        profileImage.layer.cornerRadius = profileImage.frame.width/2
    }
 
    func createImage() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadUrl(for: path) { results in
            switch results {
            case .success(let url):
                self.profileImage.sd_setImage(with: url)
                print("successful dowload image here")
            case .failure(let error):
                print("error to download image \(error)")
                // print(UserDefaults.standard.value(forKey: "profile_picture_url") as! String)
            }
        }
    }
    
    @objc func LogoutTapped() {
        
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "profile_picture_url")
        //LOG OUT FACEBOOK
        FBSDKLoginKit.LoginManager().logOut()

        GIDSignIn.sharedInstance().signOut()

        //LOG OUT FIREBASE
        do {
          try Auth.auth().signOut()
            self.performSegue(withIdentifier: "backToTheRoot", sender: self)
            
            
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
            }
    }
    
}
