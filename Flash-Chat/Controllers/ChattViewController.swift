
import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

struct Message: MessageType {
    var sender: MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributet_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "linkPreview"
        case .custom(_):
            return "custom"
        }
    }
}

class ChattViewController: MessagesViewController {
    
    public static let dateFormater: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmaul: String
    private let conversationId: String?
    public var isNewConversation = false
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManeger.safeEmail(emailAdres: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmaul = email
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId {
            listenerForMessage(id: conversationId)
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach media", message: "What whould you like to attache?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presantLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func presantLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
           
            guard let strongSelf = self else {
                return
            }
            
            guard let messageId = strongSelf.createMessageId(), let conversationId = strongSelf.conversationId, let name = strongSelf.title, let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            print("long=\(longitude) lat=\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            DatabaseManeger.share.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmaul, name: name, newMessage: message) { success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to send location message")
                }
            }
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputAction() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where whould you like to attache photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputAction() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where whould you like to attache video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    private func listenerForMessage(id: String) {
        DatabaseManeger.share.getAllMessagesForConversations(with: id) { [weak self] results in
            switch results {
            case .success(let messages):
                print("success in getting messages")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
            case .failure(let error):
                print("failed to get messages \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChattViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let messageId = createMessageId(), let conversationId = conversationId, let name = self.title, let selfSender = selfSender else {
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_\(messageId.replacingOccurrences(of: " ", with: "-")).png"
            ///upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, filename: fileName) { [weak self] results in
                guard let strongSelf = self else {
                    return
                }
                switch results {
                case .success(let urlString):
                    ///send message
                    print("uploaded message photo: \(urlString) ")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    DatabaseManeger.share.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmaul, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        } else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_\(messageId.replacingOccurrences(of: " ", with: "-")).mov"
            /// upload url
            StorageManager.shared.uploadMessageVideo(with: videoUrl, filename: fileName) { [weak self] results in
                guard let strongSelf = self else {
                    return
                }
                switch results {
                case .success(let urlString):
                    ///send message
                    print("uploaded message video: \(urlString) ")
                    
                    guard let url = URL(string: urlString), let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    DatabaseManeger.share.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmaul, name: name, newMessage: message) { success in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
    }
}

extension ChattViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageId = createMessageId() else {
            return
        }
        let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        print("sendig text: \(text)")
        // send message
        if isNewConversation {
            /// create new conversation
            DatabaseManeger.share.createNewConversation(with: otherUserEmaul, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                if success {
                    self?.isNewConversation = false
                    print("message sent")
                } else {
                    print("failed to send")
                }
                
            }
        } else {
            /// append to the existing conversation data
            guard let conversationId = conversationId, let name = self.title else {
                return
            }
            
            DatabaseManeger.share.sendMessage(to: conversationId, otherUserEmail: otherUserEmaul, name: name, newMessage: message) { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentUserEmail = DatabaseManeger.safeEmail(emailAdres: currentUserEmail)
        let dateString = Date().getFormattedDate(format: "E, d MMM yyyy HH:mm:ss Z")
        let safeDateString = dateString.replacingOccurrences(of: ".", with: "-")
        let newIdentifier = "\(otherUserEmaul)_\(safeCurrentUserEmail)_\(safeDateString)"
        return newIdentifier
    }
    
}

extension ChattViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("self sender is nil email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl)
        default:
            break
        }
    }
}

extension ChattViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }

        
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
             let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
}
