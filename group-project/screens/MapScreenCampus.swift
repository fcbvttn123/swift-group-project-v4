import UIKit
import CoreLocation
import MapKit
import FirebaseFirestore

class MapScreenCampus: UIViewController, UITextFieldDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {

    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 1000
    var locations: [CLLocation] = [] // Array to store locations
    var homeCampusLocation: CLLocation? // Variable to store the home campus location
    var selectedLocation: CLLocation? // Variable to store the selected location
    var selectedMapItem: MKMapItem? // Variable to store the selected map item
    var searchedLocation: String? // Property to store the searched location string
    var searchResults: [MKMapItem] = []
    var selectedCampuses: [String] = [] // Array to store selected campuses

    @IBOutlet var myMapView: MKMapView!
    @IBOutlet var tbLocEntered: UITextField!
    @IBOutlet var myTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        myMapView.delegate = self
        tbLocEntered.delegate = self
        myTableView.dataSource = self
        myTableView.delegate = self

        tbLocEntered.placeholder = "Search other college"
        // Initialize locations array with some sample locations (you can replace these with your desired locations)
        let homeCampusLatitude = 43.7315
        let homeCampusLongitude = -79.7624
        homeCampusLocation = CLLocation(latitude: homeCampusLatitude, longitude: homeCampusLongitude)
        locations.append(homeCampusLocation!) // Add home campus to locations array
        locations.append(CLLocation(latitude: 43.7315, longitude: -79.7624)) // Brampton coordinates
        locations.append(CLLocation(latitude: 43.5890, longitude: -79.6441)) // Mississauga coordinates

        centerMapOnLocation(location: locations[0]) // Center map on the first location
        addAnnotationsForLocations(locations: locations) // Add annotations for all locations
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        myMapView.setRegion(coordinateRegion, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func findNewLocation(sender: Any) {
        myMapView.removeAnnotations(myMapView.annotations) // Clear existing annotations

        guard let locEnteredText = tbLocEntered.text else { return }
        searchedLocation = locEnteredText // Store the searched location string
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = locEnteredText
        let localSearch = MKLocalSearch(request: localSearchRequest)

        localSearch.start { [weak self] (response, error) in
            guard let self = self else { return }
            guard error == nil else {
                print("Error searching for your College: \(error!)")
                return
            }

            if let mapItems = response?.mapItems {
                self.searchResults = mapItems
                self.myTableView.reloadData()

                for item in mapItems {
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = item.placemark.coordinate
                    dropPin.title = item.name
                    self.myMapView.addAnnotation(dropPin)
                    self.myMapView.selectAnnotation(dropPin, animated: true)
                }

                if let firstItem = mapItems.first {
                    self.centerMapOnLocation(location: firstItem.placemark.location!)
                }
            }
        }
    }

    func addAnnotationsForLocations(locations: [CLLocation]) {
        for location in locations {
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = location.coordinate
            myMapView.addAnnotation(dropPin)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let mapItem = searchResults[indexPath.row]

        var addressDetails = ""

        if let street = mapItem.placemark.thoroughfare {
            addressDetails += "\nStreet: \(street)"
        }
        if let city = mapItem.placemark.locality {
            addressDetails += "\nCity: \(city)"
        }
        if let state = mapItem.placemark.administrativeArea {
            addressDetails += "\nState: \(state)"
        }
        if let postalCode = mapItem.placemark.postalCode {
            addressDetails += "\nPostal Code: \(postalCode)"
        }

        // Create attributed string for the cell's text label
        let attributedString = NSMutableAttributedString()
        let name = NSAttributedString(string: mapItem.name ?? "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)])
        let details = NSAttributedString(string: addressDetails, attributes: nil)
        attributedString.append(name)
        attributedString.append(details)

        // Display attributed string in cell
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = attributedString

        return cell
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMapItem = searchResults[indexPath.row]

        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }

        let selectedLocationDictionary: [String: Any] = [
            "name": selectedMapItem.name ?? "",
            "latitude": selectedMapItem.placemark.coordinate.latitude,
            "longitude": selectedMapItem.placemark.coordinate.longitude,
            "street": selectedMapItem.placemark.thoroughfare ?? "",
            "city": selectedMapItem.placemark.locality ?? "",
            "state": selectedMapItem.placemark.administrativeArea ?? "",
            "postalCode": selectedMapItem.placemark.postalCode ?? "",
            "number": selectedMapItem.phoneNumber ?? "",
            "url": selectedMapItem.url?.absoluteString ?? ""
        ]


        let profilesCollection = Firestore.firestore().collection("Profiles")

        if let selectedLocationString = selectedLocationToString(location: selectedLocationDictionary) {
            if selectedCampuses.contains(selectedLocationString) {
                showAlert(message: "This campus has already been selected!")
            } else {
                selectedCampuses.append(selectedLocationString)

                profilesCollection.document(currentUserUID).updateData([
                    "Campuses": FieldValue.arrayUnion([selectedLocationDictionary])
                ]) { error in
                    if let error = error {
                        print("Error updating user profile: \(error)")
                    } else {
                        // Show alert that campus has been added
                        self.showAddCampusAlert()
                    }
                }
            }
        }
    }

    // Function to convert selected location dictionary to a string
    func selectedLocationToString(location: [String: Any]) -> String? {
        guard let latitude = location["latitude"] as? CLLocationDegrees, let longitude = location["longitude"] as? CLLocationDegrees else {
            return nil
        }
        return "\(latitude), \(longitude)"
    }



    // Function to show alert pop-up
    func showAlert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    // Function to show add campus alert pop-up
    func showAddCampusAlert() {
        let alertController = UIAlertController(title: "Campus Added", message: "Campus added successfully!", preferredStyle: .alert)
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            self.performSegue(withIdentifier: "toHome", sender: nil)
        }
        let addMoreAction = UIAlertAction(title: "Add More Campuses", style: .default)
        alertController.addAction(doneAction)
        alertController.addAction(addMoreAction)
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toHome" {
            // Prepare for segue to CollegeScreen
        }
    }
}


