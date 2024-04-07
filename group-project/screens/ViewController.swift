import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppDelegate.shared.setupGoogleSignIn()
        password.isSecureTextEntry = true
    }
    
    @IBAction func toLoginScreen(sender: UIStoryboardSegue) {
        // This function is used to come back to this view controller
    }
    
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var btn: UIButton!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // Created by David
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
    
    func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashedString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashedString
    }
    
    
    // Created by David
    // This function is used to check entered credentials with all account information retrieved form the fetchAccountInformationFromFirestore()
    // Check the README file for how to use this function
    // Function to hash the password using SHA-256 algorithm
    
        func checkCredentials(userNameEntered: String, passwordEntered: String) async -> Bool {
            do {
                let fetchedData = try await fetchDocuments(tableName: "Profiles")
                
                for (documentId, value) in fetchedData {
                    // Check if value is a dictionary
                    guard let userData = value as? [String: Any],
                          let username = userData["Username"] as? String,
                          let storedPasswordHash = userData["password"] as? String else {
                        continue
                    }
                    // Check if username matches
                    if username == userNameEntered {
                        // Hash the entered password
                        let enteredPasswordHash = hashPassword(passwordEntered)
                        // Compare hashed passwords
                        if storedPasswordHash == enteredPasswordHash {
                            AppDelegate.shared.currentUserUID = documentId
                            return true // Credentials match, return true
                        }
                    }
                }
                // No matching credentials found
                return false
            } catch {
                print("Error fetching data from Firestore: \(error)")
                // Return false in case of any error
                return false
            }
        }
    
    @IBAction func signIn(_ sender: UIButton) {
        guard let usernameText = username.text, let passwordText = password.text else {
            return
        }
        
        Task {
            //let success = await AppDelegate.shared.checkCredentials(userNameEntered: usernameText, passwordEntered: passwordText)
            let success = await checkCredentials(userNameEntered: usernameText, passwordEntered: passwordText)
            if success {
                print(AppDelegate.shared.currentUserUID)
                self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                AppDelegate.shared.isLoggedIn = true
            } else {
                let alert = UIAlertController(title: "Error", message: "No Account with these credentials", preferredStyle: .alert)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
            }
        }
    }

    func addNewDocument(for documentReference: DocumentReference) {
        documentReference.setData([
            "Username": AppDelegate.shared.username
        ]) { error in
            if let error = error {
                print("Error adding document to profiles (Manual Sign-in): \(error)")
            } else {
                print("Document added successfully to profiles (Manual Sign-in)!")
                self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                AppDelegate.shared.isLoggedIn = true
            }
        }
    }

    @IBAction func signInWithGoogle(_ sender: UIButton) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [self] authentication, error in
            
            if error != nil {
                print("Google Sign-In error")
                return
            }
            
            guard let user = authentication?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            // Set values in AppDelegate
            AppDelegate.shared.username = user.profile?.name ?? ""
            AppDelegate.shared.givenName = user.profile?.givenName ?? ""
            AppDelegate.shared.email = user.profile?.email ?? ""
            
            if let currentUser = Auth.auth().currentUser {
                // Set values in AppDelegate
                AppDelegate.shared.currentUserUID = currentUser.uid
                
                // Print user info from App Delegate
                print("userID: \(AppDelegate.shared.currentUserUID!) \n" )
                print("username: \(AppDelegate.shared.username) \n" )
                print("givenname: \(AppDelegate.shared.givenName) \n" )
                print("email: \(AppDelegate.shared.email) \n" )
                print("Date of Birth: \(AppDelegate.shared.DOB) \n" )
                print("Home Campus: \(AppDelegate.shared.homeCampus) \n" )
                
                // Check if a document exists for the current user
                let collection = Firestore.firestore().collection("Profiles")
                let userDocument = collection.document(AppDelegate.shared.currentUserUID!)
                
                userDocument.getDocument { document, error in
                    if let document = document, document.exists {
                        print("Document already exists for the user")
                        // No need to add a new document, proceed with segue
                        self.performSegue(withIdentifier: AppDelegate.shared.segueIdentiferForSignIn, sender: nil)
                        AppDelegate.shared.isLoggedIn = true
                    } else {
                        // Document doesn't exist, add a new one
                        self.addNewDocument(for: userDocument)
                    }
                }
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            Auth.auth().signIn(with: credential) { _, _ in }
        }
    }
}

