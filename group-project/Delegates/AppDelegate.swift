import UIKit

// Created by David
// These Imports are used for Firebase - Authentication
import FirebaseCore
import GoogleSignIn
import FirebaseAuth

//Created by David
// These Imports are used for Firebase - Firestore Database
import FirebaseFirestore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Created by David
    // Currently Sign-in User Information
    // Will be changed after successful sign-in
    var isLoggedIn: Bool = false
    var username: String = ""
    var givenName: String = ""
    var email: String = ""
    var imgUrl: URL?
    var homeCampus = ""
    var DOB = "" 
    var AvailableCampuses : [String] = []
    
    static let shared = AppDelegate()
       
    var currentUserUID: String?
    
    // Created by David
    // This code is used for Google Sign-in
    var segueIdentiferForSignIn: String = "toHome"
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
    }
    func setupGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    // Created by David
    // This function is used to fetch all account information from firestore
    // This function is mostly used for checkCredentials() function
    func fetchAccountInformationFromFirestore() async throws -> [String: Any] {
        let collection = Firestore.firestore().collection("accounts")
        let querySnapshot = try await collection.getDocuments()
        var data = [String: Any]()
        for document in querySnapshot.documents {
            data[document.documentID] = document.data()
        }
        return data
    }
    
    // Created by David
    // This function is used to check entered credentials with all account information retrieved form the fetchAccountInformationFromFirestore()
    // Check the README file for how to use this function 
    func checkCredentials(userNameEntered: String, passwordEntered: String) async -> Bool {
        do {
            let fetchedData = try await fetchAccountInformationFromFirestore()
            
            for (_, value) in fetchedData {
                // Check if value is a dictionary
                guard let userData = value as? [String: Any],
                      let username = userData["username"] as? String,
                      let password = userData["password"] as? String else {
                    continue
                }
                // Check if username and password match the arguments
                if username == userNameEntered && password == passwordEntered {
                    
                    return true // Credentials match, return true
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
    
    // System Generated
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Created by David
        // This code is used to configure Google Firebase
        FirebaseApp.configure()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}

