import UIKit
import FirebaseFirestore

class EventDispalyScreen: UIViewController {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var dateTimeLabel: UILabel!
    @IBOutlet var sportTypeLabel: UILabel!
    @IBOutlet var NumberOfPlayerLabel: UILabel!
    @IBOutlet var PhoneNumLabel: UILabel!
    @IBOutlet var campusLabel: UILabel!
    @IBOutlet var registerButton: UIButton! // Connect this to your Register button in Interface Builder

    var selectedCampus: String?
    var selectedRow: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchEventData()
        // Set up button action
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
    }

    func fetchEventData() {
        guard let selectedCampus = selectedCampus, let selectedRow = selectedRow else {
            print("Selected campus or row is nil")
            return
        }

        // Format the campus name
        let formattedCampus = selectedCampus.replacingOccurrences(of: "_", with: " ").capitalized

        let db = Firestore.firestore()
        let documentID = selectedCampus

        db.collection("Plays").document(documentID).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching event document: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Event document does not exist for campus: \(selectedCampus)")
                return
            }

            if let eventData = document.data()?["EventData"] as? [[String: Any]], selectedRow < eventData.count {
                let selectedEvent = eventData[selectedRow]
                // Populate UI elements with event data for the selected row
                self.nameLabel.text = selectedEvent["EventName"] as? String ?? ""
                self.locationLabel.text = selectedEvent["EventAddress"] as? String ?? ""
                self.dateTimeLabel.text = selectedEvent["Date"] as? String ?? ""
                self.sportTypeLabel.text = selectedEvent["SportType"] as? String ?? ""
                self.NumberOfPlayerLabel.text = selectedEvent["NumberOfPlayers"] as? String ?? ""
                self.PhoneNumLabel.text = selectedEvent["ContactNumber"] as? String ?? ""
                // Use the formatted campus name
                self.campusLabel.text = formattedCampus
            } else {
                print("Selected row index is out of bounds")
            }
        }
    }


    @objc func registerButtonTapped() {
        guard let selectedCampus = selectedCampus, let selectedRow = selectedRow else {
            print("Selected campus or row is nil")
            return
        }

        // Check if the user has already registered for the event
        isAlreadyRegistered(selectedCampus: selectedCampus, selectedRow: selectedRow) { isRegistered in
            if isRegistered {
                let alertController = UIAlertController(title: "Already Registered", message: "You have already registered for this event.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: "Register", message: "Are you sure you want to register for this event?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                    self.registerForEvent(selectedCampus: selectedCampus, selectedRow: selectedRow)
                }))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }


    func isAlreadyRegistered(selectedCampus: String, selectedRow: Int, completion: @escaping (Bool) -> Void) {
        // Check if the selected event already exists in the user's bookings
        let currentUserUID = AppDelegate.shared.currentUserUID ?? ""
        let db = Firestore.firestore()
        let bookingRef = db.collection("Bookings").document(currentUserUID)

        bookingRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if let bookingData = document.data()?["BookingData"] as? [[String: Any]] {
                    let selectedEvent = self.getSelectedEventData(selectedCampus: selectedCampus, selectedRow: selectedRow)
                    let isRegistered = bookingData.contains { (event) -> Bool in
                        return NSDictionary(dictionary: event).isEqual(to: selectedEvent)
                    }
                    completion(isRegistered)
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }

    func registerForEvent(selectedCampus: String, selectedRow: Int) {
        let db = Firestore.firestore()
        let currentUserUID = AppDelegate.shared.currentUserUID ?? ""
        let bookingRef = db.collection("Bookings").document(currentUserUID)

        bookingRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching booking document: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                // Update existing booking
                var bookingData = document.data()?["BookingData"] as? [[String: Any]] ?? []
                let selectedEvent = self.getSelectedEventData(selectedCampus: selectedCampus, selectedRow: selectedRow)
                bookingData.append(selectedEvent)
                bookingRef.updateData(["BookingData": bookingData]) { error in
                    if let error = error {
                        print("Error updating booking document: \(error.localizedDescription)")
                    } else {
                        self.performSegue(withIdentifier: "toConfirmation", sender: currentUserUID)
                    }
                }
            } else {
                // Create new booking
                let selectedEvent = self.getSelectedEventData(selectedCampus: selectedCampus, selectedRow: selectedRow)
                bookingRef.setData(["BookingData": [selectedEvent]]) { error in
                    if let error = error {
                        print("Error creating booking document: \(error.localizedDescription)")
                    } else {
                        self.performSegue(withIdentifier: "toConfirmation", sender: currentUserUID)
                    }
                }
            }
        }
    }

    func getSelectedEventData(selectedCampus: String, selectedRow: Int) -> [String: Any] {
        // Get the event data for the selected row
        // You may need to adjust this based on your actual data structure
        // This is just a placeholder implementation
        var eventData: [String: Any] = [:]
        eventData["EventName"] = nameLabel.text ?? ""
        eventData["EventAddress"] = locationLabel.text ?? ""
        eventData["Date"] = dateTimeLabel.text ?? ""
        eventData["SportType"] = sportTypeLabel.text ?? ""
        eventData["NumberOfPlayers"] = NumberOfPlayerLabel.text ?? ""
        eventData["ContactNumber"] = PhoneNumLabel.text ?? ""
        eventData["Campus"] = selectedCampus
        return eventData
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toConfirmation", let destinationVC = segue.destination as? BookingConfirmationScreen, let bookingId = sender as? String {
            destinationVC.bookingId = bookingId
        }
    }
}

