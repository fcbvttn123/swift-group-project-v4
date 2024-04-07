//
//  AccountScreen.swift
//  group-project
//
//  Created by fizza imran on 2024-04-03.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import MapKit

class AccountScreen: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Outlets for UI elements
    @IBOutlet var givenNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var locationLabel: UILabel!

    // Property to store selected map item
    var mapItem: MKMapItem?
    var address: String?

    // Key constants for UserDefaults
    let givenNameKey = "GivenName"
    let emailKey = "Email"
    let dateOfBirthKey = "DateOfBirth"
    let homeCampusKey = "HomeCampus"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Restore saved data
        givenNameTextField.text = UserDefaults.standard.string(forKey: givenNameKey)
        emailTextField.text = UserDefaults.standard.string(forKey: emailKey)
        locationLabel.text = UserDefaults.standard.string(forKey: homeCampusKey)

        if let dateOfBirthString = UserDefaults.standard.string(forKey: dateOfBirthKey),
           let date = DateFormatter().date(from: dateOfBirthString) {
            datePicker.date = date
        }

        // Display location details if mapItem is provided
        if let mapItem = mapItem {
            address = "\(mapItem.placemark.thoroughfare ?? ""), \(mapItem.placemark.locality ?? ""), \(mapItem.placemark.administrativeArea ?? "")"
            locationLabel.text = address
        }
    }

    // Function to handle saving changes
    @IBAction func saveChanges(_ sender: UIButton) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error: Current user ID not found")
            return
        }

        let db = Firestore.firestore()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let selectedDate = dateFormatter.string(from: datePicker.date)

        // Construct data to be saved
        var userData: [String: Any] = [:]
        userData["dateOfBirth"] = selectedDate
        userData["email"] = emailTextField.text ?? ""
        userData["givenName"] = givenNameTextField.text ?? ""
        userData["homeCampus"] = address

        // Save data to UserDefaults
        UserDefaults.standard.set(givenNameTextField.text, forKey: givenNameKey)
        UserDefaults.standard.set(emailTextField.text, forKey: emailKey)
        UserDefaults.standard.set(selectedDate, forKey: dateOfBirthKey)
        UserDefaults.standard.set(address, forKey: homeCampusKey)

        // Save data to Firestore
        db.collection("accounts").document(currentUserID).setData(userData) { error in
            if let error = error {
                print("Error updating Account Information: \(error)")
                let alert = UIAlertController(title: "Error", message: "Error Updating Account", preferredStyle: .alert)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
            } else {
                print("Account successfully updated")
                let alert = UIAlertController(title: "Successful", message: "Account Updated", preferredStyle: .alert)
                let closeAlertAction = UIAlertAction(title: "Close", style: .cancel)
                alert.addAction(closeAlertAction)
                self.present(alert, animated: true)
            }
        }
    }
}
