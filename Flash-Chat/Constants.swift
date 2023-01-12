
//MARK: - Here we create a static constants because this a safe version of using strings keys.

import UIKit

    struct K {
        static let appName = "⚡️FlashChat⚡️"
        static let cellIdentifier = "ReusableCell"
        static let secondCellIdentifire = "ReusableCell2"
        static let cellNibName = "MessageCell"
        static let secondCellNibName = "MessageCell2"
        static let registerSegue = "RegisterToChat"
        static let loginSegue = "LoginToChat"
        
        struct BrandColors {
            static let purple = "BrandPurple"
            static let lightPurple = "BrandLightPurple"
            static let blue = "BrandBlue"
            static let lighBlue = "BrandLightBlue"
        }
        
        struct FStore {
            static let collectionName = "messages"
            static let senderField = "sender"
            static let bodyField = "body"
            static let dateField = "date"
        }
    }

extension Notification.Name {
    static let didlogInNotification = Notification.Name("didlogInNotification")
    static let pictureObserv = Notification.Name("pictureObserv")
}


