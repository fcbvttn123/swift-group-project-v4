import UIKit
import MessageUI
import FirebaseFirestore

class BookingConfirmationScreen: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var viewBookingsButton: UIButton!

    var bookingId: String?
    var bookingDetails: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        if let bookingId = bookingId {
            fetchBookingDetails(for: bookingId)
        }
    }

    func fetchBookingDetails(for bookingId: String) {
        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching booking details: \(error.localizedDescription)")
                return
            }

            guard let document = document, document.exists else {
                print("Booking details document does not exist")
                return
            }

            if let bookingData = document.data()?["BookingData"] as? [[String: Any]] {
                if let bookingDetails = bookingData.first {
                    self.bookingDetails = bookingDetails
                }
            }

        }
    }

    @IBAction func sendConfirmationButtonTapped(_ sender: UIButton) {
        guard let recipientEmail = emailTextField.text else {
            displayAlert(message: "Please enter your email address.")
            return
        }

        sendConfirmationEmail(to: recipientEmail)
    }

    @IBAction func viewBookingsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "toBookings", sender: nil)
    }

    func sendConfirmationEmail(to recipientEmail: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([recipientEmail])
            mailComposer.setSubject("Booking Confirmation")

            let messageBody = """
            Dear Customer,

            Thank you for booking with us!

            Here are your booking details:
            Campus: \(bookingDetails["Campus"] as? String ?? "")
            Contact Number: \(bookingDetails["ContactNumber"] as? String ?? "")
            Date: \(bookingDetails["Date"] as? String ?? "")
            Event Address: \(bookingDetails["EventAddress"] as? String ?? "")
            Event Name: \(bookingDetails["EventName"] as? String ?? "")
            Number of Players: \(bookingDetails["NumberOfPlayers"] as? String ?? "")
            Sport Type: \(bookingDetails["SportType"] as? String ?? "")

            We look forward to seeing you at the event.

            Best regards,
            Your Booking Team
            """
            mailComposer.setMessageBody(messageBody, isHTML: false)

            present(mailComposer, animated: true, completion: nil)
        } else {
            print("Device is unable to send email")
        }
    }

    func displayConfirmationPopup(to email: String) {
        let alertController = UIAlertController(title: "Confirmation Sent", message: "Confirmation sent to \(email). Thank you for booking!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            self?.performSegue(withIdentifier: "toBookings", sender: nil)
        }))
        present(alertController, animated: true, completion: nil)
    }

    func displayAlert(message: String) {
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            if result == .sent {
                if let email = self?.emailTextField.text {
                    self?.displayConfirmationPopup(to: email)
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toBookings", let destinationVC = segue.destination as? ViewBookingsScreen {
            destinationVC.bookingId = bookingId
        }
    }
}

