
import Foundation
import FirebaseFirestore

final class DatabaseManeger {
    
    static let share = DatabaseManeger()
    
    private let database = Firestore.firestore()
    
    public func validateNewUser(with useremail: String, competition: @escaping (Bool) -> Void) {
        print(useremail)
        database.collection(useremail).getDocuments(completion: { snapshotDocuments, error in
        
            if let snapshotDocument = snapshotDocuments?.documents {
                 let doc = snapshotDocument
                    if doc.isEmpty {
                        print("there no email like that")
                        competition(false)
                    } else {
                        print("email exist")
                        competition(true)
                    }
              }
        })

    }
    
    
    public func insertUser(with user: UserData) {
        database.collection(user.userEmail).addDocument(data: ["userNik": user.userNikName, "userEmail": user.userEmail]) { error in
            if let e = error {
                print("There was an issue saving data to firestore, \(e)")
            } else {
                print("Successfully saved data.")
            }
        }
    }
    
    struct UserData {
        let userNikName: String
        let userEmail: String
    }
    
}



