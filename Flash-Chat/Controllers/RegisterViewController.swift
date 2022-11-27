    
//MARK: - Here we implement FirebaseAuth for register our users.

 import UIKit
 import FirebaseAuth

class RegisterViewController: UIViewController, UINavigationControllerDelegate {
    var userDoAnimation: Bool = false
    
    enum EnamCase {
        case camera
        case photoLibrary
    }
    
    
    
      
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var errorMassege: UILabel!
    
 //MARK: - Here we make our UINavigationBar without color and set the color for navigation buttons.
      
      
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.blue)
        UINavigationBar.appearance().scrollEdgeAppearance = .none
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(imageTapped(tapGestureRecognizer:)))
           userImage.isUserInteractionEnabled = true
           userImage.addGestureRecognizer(tapGestureRecognizer)
          
    }
     
      @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
      {
         // let tappedImage = tapGestureRecognizer.view as! UIImageView

          presentPhotoAction()
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

extension RegisterViewController: UIImagePickerControllerDelegate {
    
    func presentPhotoAction() {
        
        let actionSheet = UIAlertController(title: "Profile picture", message: "How whould you like to select a picture?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "take photo", style: .default, handler: { [weak self] _ in
            self?.presentCameraOrLibrary(enamCase: .camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "choose photo", style: .default, handler: {  [weak self] _ in
            self?.presentCameraOrLibrary(enamCase: .photoLibrary)
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCameraOrLibrary(enamCase: UIImagePickerController.SourceType) {
         
        let picker = UIImagePickerController()
            picker.delegate = self
        picker.allowsEditing = true
            picker.sourceType = enamCase
         
            present(picker, animated: true, completion: nil)
        }
   
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
   
        
        
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        userImage.image = selectedImage
        userImage.layer.borderWidth = 1
        userImage.layer.masksToBounds = false
        userImage.layer.borderColor = UIColor.lightGray.cgColor
        userImage.layer.cornerRadius = userImage.frame.height/2
        userImage.clipsToBounds = true
        if !userDoAnimation {
            UIView.animate(withDuration: 2, animations: {
                self.userImage.frame.origin.y += 250
                self.userDoAnimation = true
            }, completion: nil)
        } else {
            self.userImage.frame.origin.y -= 250
            UIView.animate(withDuration: 2, animations: {
                self.userImage.frame.origin.y += 250
                self.userDoAnimation = true
            }, completion: nil)
        }
        
        
      }
    
         
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


