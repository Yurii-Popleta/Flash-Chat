
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn


class ProfileViewController: UIViewController {
  
    @IBOutlet weak var profileImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                self.downloadImage(imageView: self.profileImage, url: url)
                print("successful dowload image here")
            case .failure(let error):
                print("error to download image \(error)")
               // print(UserDefaults.standard.value(forKey: "profile_picture_url") as! String)
            }
        }
    }


    func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                imageView.image = UIImage(data: data)
            }
        }.resume()
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
