
//MARK: - Here we implement FirebaseAuth ana FirebaseFirestore libraries to save a user messages and to use this data from FireBase database.

import UIKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let data: String
    let text: String
    let isRead: Bool
}

class ConversationController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Here we create a new FireBase database and empty array where we will put users email and messages.
    
    
    private let noConversation: UILabel = {
        let lable = UILabel()
        lable.text = "no converstion"
        lable.textAlignment = .center
        lable.textColor = .gray
        lable.font = .systemFont(ofSize: 21, weight: .medium)
        return lable
    }()
    
    private var conversations = [Conversation]()
    
    //MARK: - Here we indications who is delegate for tableView and who is data source for tableView, also we turn off back button, set a title, set a color for logout button and register our two custom cells.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  tableView.isHidden = true
        // view.addSubview(noConversation)
        self.tabBarController?.navigationItem.hidesBackButton = true
        tableView.dataSource = self
        tableView.delegate = self
        title = K.appName
        navigationController!.navigationBar.tintColor = UIColor(named: K.BrandColors.lightPurple)
        //tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        tableView.register(UINib(nibName: K.secondCellNibName, bundle: nil), forCellReuseIdentifier: K.secondCellIdentifire)
        //  loadMessages()
        tableView.allowsSelection = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        startListeningForConversations()
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationController()
        vc.completion = { [weak self] results in
            print("\(results)")
            self?.createNewConversation(result: results)
        }
        let navVc = UINavigationController(rootViewController: vc)
        present(navVc, animated: true)
    }
    
    private func createNewConversation(result: [String: String]) {
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: email)
        let vc = ChattViewController(with: safeEmail, id: nil)
        vc.isNewConversation = true
        vc.title = name
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noConversation.frame = view.bounds
    }
    
    //MARK: - Here we pull out data from FireBase database collection based on key date in this collection for hierarchies and with for loop we pull all data and casting this all data in type String and connect this data by using struct Message and then we append this initial struct into array messages. After this we reload tableView for showing this data on screen and set showing the last cells. Also with method addSnapshotListener we update this array messages automatically when database updates.
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else  {
            return
        }
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: email)
        DatabaseManeger.share.getAllConversation(for: safeEmail) { [weak self] results in
            switch results {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("failed to get conversations \(error)")
            }
        }
    }
}
//MARK: - Here we set our tableView and set our custom cells, what they should look like and what they should show.

extension ConversationController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let model = conversations[indexPath.row]
        
            func getUserImage(cell: MessageCell2) {
                let fileName = model.otherUserEmail + "_profile_picture.png"
                let path = "images/" + fileName
                StorageManager.shared.downloadUrl(for: path) { results in
                    switch results {
                    case .success(let url):
                        cell.leftImage.sd_setImage(with: url, completed: nil)
                        cell.leftImage.contentMode = .scaleAspectFill
                        cell.leftImage.layer.cornerRadius =  cell.leftImage.frame.width/2
                        cell.leftImage.layer.masksToBounds = false
                        cell.leftImage.clipsToBounds = true
                    case .failure(let error):
                        print("error to download image \(error)")
                }
            }
        }
    
            let cell = tableView.dequeueReusableCell(withIdentifier: K.secondCellIdentifire, for: indexPath)
            as! MessageCell2
            getUserImage(cell: cell)
            cell.selectionStyle = .blue
            cell.lable.text = model.latestMessage.text
            cell.nikName.text = model.name
            cell.leftImage.isHidden = false
            cell.accessoryType = .disclosureIndicator
           // cell.messageBody.backgroundColor = UIColor(named: K.BrandColors.purple)
           // cell.lable.textColor = UIColor(named: K.BrandColors.lightPurple)
            cell.lable.textAlignment = .left
            return cell
    }
   
          func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
             tableView.deselectRow(at: indexPath, animated: true)
              let model = conversations[indexPath.row]
              let vc = ChattViewController(with: model.otherUserEmail, id: model.id)
              if let curentcell = tableView.cellForRow(at: indexPath) as? MessageCell2 {
                  vc.title = model.name
                  navigationController?.pushViewController(vc, animated: true)
        }
    }
}


