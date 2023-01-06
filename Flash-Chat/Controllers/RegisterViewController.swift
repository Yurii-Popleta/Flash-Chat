    
//MARK: - Here we implement FirebaseAuth for register our users.

 import UIKit
 import FirebaseAuth
 import JGProgressHUD
class RegisterViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var nikNmae: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var errorMassege: UILabel!
    
//    enum EnamCase {
//        case camera
//        case photoLibrary
//    }
    
    private var truth = false
    private let spinner = JGProgressHUD(style: .dark)
    
    //MARK: - Here we make our UINavigationBar without color and set the color for navigation buttons.
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController!.navigationBar.isHidden = false
    }
    
    override func viewDidLoad() {
            super.viewDidLoad()
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.blue)
        UINavigationBar.appearance().scrollEdgeAppearance = .none
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:  #selector(imageTapped(tapGestureRecognizer:)))
        userImage.isUserInteractionEnabled = true
        userImage.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if truth {
            navigationController!.navigationBar.isHidden = true
        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        // let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        presentPhotoAction()
    }
    
    //MARK: - Here we register user based on what email and password he wrote we send this data in FireBase database and if register was success we move this user on the chat screen.
    
    @IBAction func registerPressed(_ sender: UIButton) {
        print("work")
        if let email = emailTextfield.text, let password = passwordTextfield.text, let nikname = nikNmae.text {
            spinner.show(in: view)
            DatabaseManeger.share.validateNewUser(with: email) { exists in
                print(exists)
                guard exists == false else {
                    self.errorMassege.text = "this email already exist"
                    return
                }
            
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                   
                    if let e = error {
                        self.errorMassege.text = e.localizedDescription
                        self.passwordTextfield.text = ""
                        self.emailTextfield.text = ""
                    } else if authResult != nil {
                        let userData = UserData(userNikName: nikname, userEmail: email)
                        DatabaseManeger.share.insertUser(with: userData) { success in
                            if success {
                                //upload image
                                guard let image = self.userImage.image, let data = image.pngData() else {
                                    return
                                }
                                let fileName = userData.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, filename: fileName) { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                        self.truth = true
                                        UserDefaults.standard.set(email, forKey: "email")
                                        UserDefaults.standard.set(nikname, forKey: "name")
                                        self.performSegue(withIdentifier: K.registerSegue, sender: self)
                                        self.errorMassege.text = ""
                                        DispatchQueue.main.async {
                                            self.spinner.dismiss()
                                        }
                                    case .failure(let error):
                                        print("Storage manager error \(error)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

//MARK: - user image

extension RegisterViewController: UIImagePickerControllerDelegate {

    func presentPhotoAction() {

        let actionSheet = UIAlertController(title: "Profile picture", message: "How whould you like to select a picture?", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "take photo", style: .default, handler: { [weak self] _ in
            self?.presentCameraOrLibrary(enamCase: .camera)
        }))
        actionSheet.addAction(UIAlertAction(title: "choose photo", style: .default, handler: { [weak self] _ in
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

        if let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            userImage.image = selectedImage
            userImage.layer.cornerRadius = userImage.frame.width/2
            userImage.layer.borderWidth = 1
            userImage.layer.masksToBounds = false
            userImage.layer.borderColor = UIColor.lightGray.cgColor
            userImage.clipsToBounds = true
            
            DispatchQueue.main.async {
                self.userImage.frame.origin.y -= 250
                UIView.animate(withDuration: 2, animations: {
                    self.userImage.frame.origin.y += 250
                }, completion: nil)
            }
         }
      }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


