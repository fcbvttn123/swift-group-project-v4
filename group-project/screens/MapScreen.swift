import UIKit
import CoreLocation
import MapKit
import FirebaseFirestore

class MapScreen: UIViewController, UITextFieldDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 1000
    var locations: [CLLocation] = [] // Array to store locations
    var homeCampusLocation: CLLocation? // Variable to store the home campus location
    var selectedLocation: CLLocation? // Variable to store the selected location
    var selectedMapItem: MKMapItem? // Variable to store the selected map item
    
    var searchResults: [MKMapItem] = []
    
    @IBOutlet var myMapView: MKMapView!
    @IBOutlet var tbLocEntered: UITextField!
    @IBOutlet var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myMapView.delegate = self
        tbLocEntered.delegate = self
        myTableView.dataSource = self
        myTableView.delegate = self
        
        tbLocEntered.placeholder = "Search for your campus"
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
        if let selectedLocation = selectedMapItem.placemark.location {
            self.selectedLocation = selectedLocation
            myMapView.removeAnnotations(myMapView.annotations) // Clear existing annotations
            
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = selectedLocation.coordinate
            dropPin.title = selectedMapItem.name
            myMapView.addAnnotation(dropPin)
            myMapView.selectAnnotation(dropPin, animated: true)
            
            centerMapOnLocation(location: selectedLocation)
            
            // Update the database with the selected location
            updateDatabase(with: selectedMapItem)
        }
    }
    
    // Function to update the database with the selected location
    func updateDatabase(with mapItem: MKMapItem) {
        guard let currentUserUID = AppDelegate.shared.currentUserUID else {
            return
        }
        
        let profilesCollection = Firestore.firestore().collection("Profiles")
        
        // Convert the MKMapItem to a string
        let mapItemString = mapItemToString(mapItem: mapItem)
        
        // Update HomeCampus property for the current user in the Profiles collection
        profilesCollection.document(currentUserUID).setData(["HomeCampus": mapItemString], merge: true) { error in
            if let error = error {
                print("Error updating HomeCampus: \(error)")
            } else {
                print("HomeCampus updated successfully")
                
                // Add the coordinates of the home campus to AvailableCampuses
                if let homeLocation = mapItem.placemark.location {
                    // Extract placemark details
                    let placemark = mapItem.placemark
                    
                    // Add the home campus map item and coordinates to HomeCampus
                    let homeDictionary: [String: Any] = [
                        "name": mapItem.name ?? "",
                        "latitude": homeLocation.coordinate.latitude,
                        "longitude": homeLocation.coordinate.longitude,
                        "street": placemark.thoroughfare ?? "",
                        "city": placemark.locality ?? "",
                        "state": placemark.administrativeArea ?? "",
                        "postalCode": placemark.postalCode ?? "",
                        "number": mapItem.phoneNumber ?? "",
                        "url": mapItem.url?.absoluteString ?? ""
                    ]
                    
                    profilesCollection.document(currentUserUID).updateData([
                        "Campuses": FieldValue.arrayUnion([homeDictionary])
                    ]) { error in
                        if let error = error {
                            print("Error updating MapItemCampuses: \(error)")
                        } else {
                            print("MapItemCampuses updated successfully")
                            
                            // Show pop-up to confirm HomeCampus and AvailableCampuses added
                            self.showAlert(message: "Home campus and available campuses added successfully")
                        }
                    }
                }
            }
        }
    }



// Function to convert MKMapItem to a string
func mapItemToString(mapItem: MKMapItem) -> String {
    return mapItem.name ?? ""
}

// Function to convert CLLocation to a string
func locationToString(location: CLLocation) -> String {
    return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
}

// Function to show alert pop-up
func showAlert(message: String) {
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
        self.performSegue(withIdentifier: "toMapScreen2", sender: nil)
    })
    alertController.addAction(okAction)
    present(alertController, animated: true, completion: nil)
}

// MARK: - Navigation

override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "toMapScreen2" {
        if let destinationVC = segue.destination as? MapScreenCampus {
        }
    }
}
}


