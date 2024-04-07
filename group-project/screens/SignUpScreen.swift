import UIKit
import CryptoKit

// These Imports are used for Firebase - Firestore Database
import FirebaseFirestore

class SignUpScreen: UIViewController, UITextFieldDelegate {
    
    let mainDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        password.isSecureTextEntry = true
        // Do any additional setup after loading the view.
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // This function is used to fetch all documents from any table
    func fetchDocuments(tableName: String) async throws -> [String: Any] {
        let collection = Firestore.firestore().collection(tableName)
        let querySnapshot = try await collection.getDocuments()
        var data = [String: Any]()
        for document in querySnapshot.documents {
            data[document.documentID] = document.data()
        }
        return data
    }
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBAction func signUp(sender: Any) {
            // Ensure both text fields are not empty
            guard let usernameText = username.text, !usernameText.isEmpty,
                  let passwordText = password.text, !passwordText.isEmpty else {
                let alert = UIAlertController(title: "Error", message: "Please enter both username and password", preferredStyle: .alert)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
                print("Username and password cannot be empty")
                return
            }
            
            // Hash the password using SHA-256 algorithm
            let hashedPassword = hashPassword(passwordText)
            
            Task {
                do {
                    let documents = try await fetchDocuments(tableName: "Profiles")
                    print(documents)
                    
                    // Check if the username already exists
                    if documents.values.contains(where: { ($0 as? [String: Any])?["Username"] as? String == usernameText }) {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Error", message: "Username already exists", preferredStyle: .alert)
                            let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                            alert.addAction(closeAlertAction)
                            self.present(alert, animated: true)
                        }
                    } else {
                        let collection = Firestore.firestore().collection("Profiles")
                        
                        collection.addDocument(
                            data: ["Username": usernameText,
                                   "password": hashedPassword,
                                   "AvailableCampuses": nil,
                                   "HomeCampus": nil,
                                   "HomeCampusCoordinates": nil]
                        ) { error in
                            if let error = error {
                                print("Error adding document: \(error)")
                            } else {
                                let alert = UIAlertController(title: "Successful", message: "Please log in!", preferredStyle: .alert)
                                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                                alert.addAction(closeAlertAction)
                                self.present(alert, animated: true)
                                print("Document added successfully!")
                            }
                        }
                    }
                } catch {
                    print("Error fetching documents: \(error)")
                }
            }
        }
        
        // Function to hash the password using SHA-256 algorithm
        func hashPassword(_ password: String) -> String {
            let inputData = Data(password.utf8)
            let hashedData = SHA256.hash(data: inputData)
            let hashedString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
            return hashedString
        }
        
        
    

}
