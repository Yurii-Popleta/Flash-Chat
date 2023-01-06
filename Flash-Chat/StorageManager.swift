
import Foundation
import FirebaseStorage


final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    public func uploadProfilePicture(with data: Data, filename: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("images/\(filename)").putData(data, metadata: nil) { metaData, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase to picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
         }
            self.storage.child("images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    //failed
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                  }
                let urlString = url.absoluteString
                print("download url returned \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// upload image that will be send in a conversation message
    public func uploadMessagePhoto(with data: Data, filename: String, completion: @escaping UploadPictureCompletion) {
        
        storage.child("message_images/\(filename)").putData(data, metadata: nil) { metaData, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase to picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
         }
            self.storage.child("message_images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    //failed
                    print("failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                  }
                let urlString = url.absoluteString
                print("download url returned \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadUrl(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
       
        let refenence = storage.child(path)
        refenence.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
       }
    }
 }

