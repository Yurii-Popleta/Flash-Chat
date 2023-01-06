
import Foundation
import FirebaseFirestore
import FirebaseDatabase
import MessageKit



final class DatabaseManeger {
    
    static let share = DatabaseManeger()
    
    
    func getDate(format: String) -> Date? {
        let dateformat = DateFormatter()
        dateformat.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return dateformat.date(from: format)
    }
    
    // private let database = Firestore.firestore()
    
    static public func safeEmail(emailAdres: String) -> String {
        var safeEmail = emailAdres.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    private let realTimeDatabase = Database.database().reference()
    
    public func validateNewUser(with useremail: String, competition: @escaping (Bool) -> Void) {
        var safeEmail = useremail.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        print(safeEmail)
        realTimeDatabase.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            if snapshot.value as? [String: String] != nil {
                print("email exist")
                competition(true)
            } else {
                print("there no email like that")
                competition(false)
            }
        }
        
    }
    
    
    public func insertUser(with user: UserData, completion: @escaping (Bool) -> Void) {
        realTimeDatabase.child(user.safeEmail).setValue(["userNik": user.userNikName, "userEmail": user.userEmail]) { error, _ in
            if let e = error {
                completion(false)
                print("There was an issue saving data to firestore, \(e)")
            } else {
                self.realTimeDatabase.child("users").observeSingleEvent(of: .value) { snapshot in
                    if var usersCollections = snapshot.value as? [[String: String]] {
                        //append to usersCollection
                        let newElement = ["name": user.userNikName, "email": user.userEmail]
                        usersCollections.append(newElement)
                        self.realTimeDatabase.child("users").setValue(usersCollections) { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        }
                    } else {
                        //create usersCollection
                        let newCollection: [[String: String]] = [
                            ["name": user.userNikName, "email": user.userEmail]
                        ]
                        
                        self.realTimeDatabase.child("users").setValue(newCollection) { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            completion(true)
                        }
                    }
                }
                
                print("Successfully saved data.")
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        realTimeDatabase.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
}

//MARK: - Sending messages/conversations


extension DatabaseManeger {
    
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.realTimeDatabase.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
}

extension DatabaseManeger {
    
    /// create a new conversation with target user emai and first message sent.
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String, let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: currentEmail)
        let ref = realTimeDatabase.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = messageDate.getFormattedDate(format: "E, d MMM yyyy HH:mm:ss Z")
            
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            ///update recipient conversation entry
            self?.realTimeDatabase.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversation = snapshot.value as? [[String: Any]] {
                    ///append
                    conversation.append(recipient_newConversationData)
                    self?.realTimeDatabase.child("\(otherUserEmail)/conversations").setValue([conversation])
                } else {
                    ///create
                    self?.realTimeDatabase.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            
            ///update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                ///conversation array exist for current user
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId, name: name, firstMessage: firstMessage, completion: completion)
                }
            } else {
                ///create new conversation array
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId, name: name, firstMessage: firstMessage, completion: completion)
                }
            }
        }
        
    }
    
    private func finishCreatingConversation(conversationId: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = messageDate.getFormattedDate(format: "E, d MMM yyyy HH:mm:ss Z")
        print(dateString)
        
        var message = ""
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let safeCurrentUserEmail = DatabaseManeger.safeEmail(emailAdres: currentUserEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString ,
            "content": message,
            "date": dateString,
            "sender_email": safeCurrentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        realTimeDatabase.child("\(conversationId)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    /// fetches and returns all conversation for the user with passed in email
    public func getAllConversation(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        realTimeDatabase.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversation: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latesMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latesMessage["date"] as? String,
                      let isRead = latesMessage["is_read"] as? Bool,
                      let message = latesMessage["message"] as? String else {
                    return nil
                }
                let latestMessageObject = LatestMessage(data: date, text: message, isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversation))
        }
    }
    
    /// get all messages for a given conversation
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        realTimeDatabase.child("\(id)/messages").observe(.value) { snapshot, _  in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            print("\(id)/messages")
            if ChattViewController.dateFormater.date(from: value[0]["date"] as! String) != nil {
                print("there no error")
            }
            print(value[0]["date"] as! String)
            let  messages: [Message] = value.compactMap { dictionary in
                guard let messageId = dictionary["id"] as? String,
                      let type = dictionary["type"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let date = self.getDate(format: dateString) else {
                    print("error ")
                    return nil
                }
                
                var kind: MessageKind?
                if type == "photo" {
                    /// photo
                    guard let imageUrl = URL(string: content), let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else {
                    /// text
                    kind = .text(content)
                }
                guard let finalKind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    /// sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        ///add new message to messages
        ///update sender latest sender message
        ///update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeMyEmail = DatabaseManeger.safeEmail(emailAdres: myEmail)
        
        realTimeDatabase.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = messageDate.getFormattedDate(format: "E, d MMM yyyy HH:mm:ss Z")
            print(dateString)
            
            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let safeCurrentUserEmail = DatabaseManeger.safeEmail(emailAdres: currentUserEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString ,
                "content": message,
                "date": dateString,
                "sender_email": safeCurrentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.realTimeDatabase.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil  else {
                    completion(false)
                    return
                }
                
                strongSelf.realTimeDatabase.child("\(safeCurrentUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    var updateValue: [String: Any] = [
                        "date": dateString,
                        "message": message,
                        "is_read": false
                    ]
                    
                    for (i, conversationDict) in currentUserConversations.enumerated() {
                        if let id = conversationDict["id"] as? String, id == conversation {
                            currentUserConversations[i]["latest_message"] = updateValue
                            break
                        }
                    }
                    strongSelf.realTimeDatabase.child("\(safeCurrentUserEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        ///update latest message for the recipient user
                        
                        strongSelf.realTimeDatabase.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            var updateValue: [String: Any] = [
                                "date": dateString,
                                "message": message,
                                "is_read": false
                            ]
                            
                            for (i, conversationDict) in otherUserConversations.enumerated() {
                                if let id = conversationDict["id"] as? String, id == conversation {
                                    otherUserConversations[i]["latest_message"] = updateValue
                                    break
                                }
                            }
                            strongSelf.realTimeDatabase.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct UserData {
    let userNikName: String
    let userEmail: String
    
    var safeEmail: String {
        var safeEmail = userEmail.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}

extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
    
}
