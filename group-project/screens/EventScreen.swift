import UIKit
import FirebaseFirestore

class EventScreen: UIViewController {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var dateTimeLabel: UILabel!
    @IBOutlet var sportTypeLabel: UILabel!
    @IBOutlet var NumberOfPlayerLabel: UILabel!
    @IBOutlet var PhoneNumLabel: UILabel!
    @IBOutlet var campusLabel: UILabel!

    var selectedCampus: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchEventData()
    }

    func fetchEventData() {
        guard let selectedCampus = selectedCampus else {
            print("Selected campus is nil")
            return
        }

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

            if let eventData = document.data()?["EventData"] as? [[String: Any]], let firstEvent = eventData.first {
                // Populate UI elements with event data
                self.nameLabel.text = firstEvent["EventName"] as? String ?? ""
                self.locationLabel.text = firstEvent["EventAddress"] as? String ?? ""
                self.dateTimeLabel.text = firstEvent["Date"] as? String ?? ""
                self.sportTypeLabel.text = firstEvent["SportType"] as? String ?? ""
                self.NumberOfPlayerLabel.text = firstEvent["NumberOfPlayers"] as? String ?? ""
                self.PhoneNumLabel.text = firstEvent["ContactNumber"] as? String ?? ""
                self.campusLabel.text = selectedCampus
            }
        }
    }
}

