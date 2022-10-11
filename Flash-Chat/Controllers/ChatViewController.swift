
//MARK: - Here we implement FirebaseAuth ana FirebaseFirestore libraries to save a user messages and to use this data from FireBase database.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController, UITableViewDelegate {

   @IBOutlet weak var tableView: UITableView!
   @IBOutlet weak var messageTextfield: UITextField!

//MARK: - Here we create a new FireBase database and empty array where we will put users email and messages.
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
   
 //MARK: - Here we indications who is delegate for tableView and who is data source for tableView, also we turn off back button, set a title, set a color for logout button and register our two custom cells.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        navigationItem.hidesBackButton = true
        title = K.appName
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.lightPurple)
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        tableView.register(UINib(nibName: K.secondCellNibName, bundle: nil), forCellReuseIdentifier: K.secondCellIdentifire)
        loadMessages()
    }
    
//MARK: - Here we pull out data from FireBase database collection based on key date in this collection for hierarchies and with for loop we pull all data and casting this all data in type String and connect this data by using struct Message and then we append this initial struct into array messages. After this we reload tableView for showing this data on screen and set showing the last cells. Also with method addSnapshotListener we update this array messages automatically when database updates.
    
    func loadMessages() {

        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { querySnapshot, error in

            self.messages = []
            if let e = error {
                print("There was an issue saving data to firestore, \(e)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)

                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }

    //MARK: - Here we save data in FireBase database in new collection about what user wrote in message, who send this message his email and when this message was sended, and if its was success we clean messageTextfield.
    
   @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
            if messageBody != "" {
                db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField: messageSender, K.FStore.bodyField: messageBody, K.FStore.dateField: Date().timeIntervalSince1970]) { (error) in
                    if let e = error {
                        print("There was an issue saving data to firestore, \(e)")
                    } else {
                        print("Successfully saved data.")
                        DispatchQueue.main.async {
                            self.messageTextfield.text = ""
                            self.messageTextfield.placeholder = "Write a message..."
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.messageTextfield.placeholder = "print something to send"
                }
            }
        }
    }

//MARK: - Here we log out user and move he on first welcome screen.
    
  @IBAction func logOutPressed(_ sender: UIBarButtonItem) {

    do {
      try Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)
        
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
        }
    }
}

//MARK: - Here we set our tableView and set our custom cells, what they should look like and what they should show.

extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        if message.sender == Auth.auth().currentUser?.email {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath)
            as! MessageCell
            cell.label.text = message.body
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
            cell.label.textAlignment = .right
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.secondCellIdentifire, for: indexPath)
            as! MessageCell2
            cell.lable.text = message.body
            cell.rightImage.isHidden = true
            cell.leftImage.isHidden = false
            cell.messageBody.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.lable.textColor = UIColor(named: K.BrandColors.lightPurple)
            cell.lable.textAlignment = .left
            return cell
        }
    }
}


