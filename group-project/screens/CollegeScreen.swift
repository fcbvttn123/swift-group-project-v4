import UIKit
import FirebaseFirestore

class CollegeScreen: UIViewController {
    
    @IBOutlet weak var addHomeCampusButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if HomeCampus is not set
        checkHomeCampus()
        updateHomeCampusButtonTitle()
    }
    
    @IBAction func toCollegeScreen(sender: UIStoryboardSegue) {
        
    }
    
    func checkHomeCampus() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                // Document exists, check if HomeCampus is set
                let data = document.data()
                if let homeCampus = data?["HomeCampus"] as? String, !homeCampus.isEmpty {
                    // HomeCampus is set, proceed with functionality
                    self.handleProceed()
                } else {
                    // HomeCampus is not set, show pop-up to add HomeCampus
                    self.showHomeCampusPopUp()
                }
            } else {
                // Document doesn't exist, show pop-up to add HomeCampus
                self.showHomeCampusPopUp()
            }
        }
    }
    
    func showHomeCampusPopUp() {
        let alertController = UIAlertController(title: "Enter HomeCampus", message: "Please enter your HomeCampus to continue.", preferredStyle: .alert)
        
        // Add action to add HomeCampus
        let addAction = UIAlertAction(title: "Add HomeCampus", style: .default, handler: { [weak self] action in
            
            // Go to AddHomeCampusScreen
            self?.performSegue(withIdentifier: "toAddHomeCampus", sender: nil)
        })
        alertController.addAction(addAction)
        
        // Add action to cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.showPopUpAgain()
        }
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    
    func showPopUpAgain() {
        let alertController = UIAlertController(title: "Warning!", message: "Not setting a Home Campus might impact your experience.", preferredStyle: .alert)
        
        // Add action to cancel
        let cancelAction = UIAlertAction(title: "Continue Without Setting", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Add action to add HomeCampus
        let addAction = UIAlertAction(title: "Add Home Campus", style: .default, handler: { [weak self] action in
            // Go to AddHomeCampusScreen
            self?.performSegue(withIdentifier: "toAddHomeCampus", sender: nil)
        })
        alertController.addAction(addAction)
        
        // Present the warning alert controller
        present(alertController, animated: true, completion: nil)
    }

    func updateHomeCampusButtonTitle() {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let homeCampus = data?["HomeCampus"] as? String {
                    // HomeCampus is set, update the button's title
                    self.addHomeCampusButton.setTitle(homeCampus, for: .normal)
                }
            }
        }
    }

    @IBAction func addHomeCampusButtonTapped(_ sender: UIButton) {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        print(currentUserUID)
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        profilesCollection.document(currentUserUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()

                    self.performSegue(withIdentifier: "toMaps", sender: nil)
            }
        }
    }

    
    func handleProceed() {
        // Handle the functionality after checking HomeCampus
        // For example, enable buttons or perform other actions
    }

    @IBAction func pickPlayButtonTapped(_ sender: UIButton) {
        // Not handling navigation here since HomeCampus is not set
    }
    
    @IBAction func pickPalButtonTapped(_ sender: UIButton) {
        // Not handling navigation here since HomeCampus is not set
    }
    
    @IBAction func addPlayButtonTapped(_ sender: UIButton) {
        // Not handling navigation here since HomeCampus is not set
    }
}

