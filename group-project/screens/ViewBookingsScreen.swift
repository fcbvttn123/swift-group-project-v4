import UIKit
import FirebaseFirestore

// Protocol to handle delete action
protocol DeleteBookingDelegate: AnyObject {
    func deleteBooking(at index: Int)
}

// Custom UITableViewCell for booking display
class BookingTableViewCell: UITableViewCell {
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var campusLabel: UILabel!
    weak var delegate: DeleteBookingDelegate?

    // Configure cell with booking details
       func configure(with bookingDetails: [String: Any], at index: Int) {
           eventNameLabel.text = bookingDetails["EventName"] as? String ?? ""
           dateLabel.text = "Date: \(bookingDetails["Date"] as? String ?? "")"
           addressLabel.text = "Address: \(bookingDetails["EventAddress"] as? String ?? "")"
           
           // Format and set the campus name
           if let campus = bookingDetails["Campus"] as? String {
               let formattedCampus = campus.replacingOccurrences(of: "_", with: " ").capitalized
               campusLabel.text = "Campus: \(formattedCampus)"
           } else {
               campusLabel.text = "Campus: N/A"
           }
       }


    // Handle delete button tap
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        delegate?.deleteBooking(at: tag)
    }
}

class ViewBookingsScreen: UIViewController, UITableViewDataSource, UITableViewDelegate, DeleteBookingDelegate {

    @IBOutlet var tableView: UITableView!

    var bookingId: String?
    var bookingData: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        fetchBookingData()
    }

    func fetchBookingData() {
        guard let bookingId = bookingId else {
            print("Booking ID is nil")
            return
        }

        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching booking data: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Booking document does not exist")
                return
            }

            if let bookingData = document.data()?["BookingData"] as? [[String: Any]] {
                self.bookingData = bookingData
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookingData.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookingCell", for: indexPath) as? BookingTableViewCell else {
            fatalError("Failed to dequeue BookingTableViewCell.")
        }

        cell.tag = indexPath.row
        cell.delegate = self
        cell.configure(with: bookingData[indexPath.row], at: indexPath.row)

        return cell
    }

    // MARK: - DeleteBookingDelegate

    func deleteBooking(at index: Int) {
        guard let bookingId = bookingId else {
            print("Booking ID is nil")
            return
        }

        // Remove the booking data from the array
        let removedBooking = bookingData.remove(at: index)
        tableView.reloadData()

        // Delete the booking from Firestore
        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).updateData(["BookingData": bookingData]) { error in
            if let error = error {
                print("Error updating booking data: \(error.localizedDescription)")
                // If updating Firestore fails, re-add the removed booking data
                self.bookingData.insert(removedBooking, at: index)
                self.tableView.reloadData()
            }
        }
    }
}

