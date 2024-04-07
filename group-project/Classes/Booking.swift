//
//  Booking.swift
//  group-project
//
//  Created by fizza imran on 2024-04-03.
//

import Foundation

class Booking {
    var bookingID: Int
    var userID: Int
    var teamID: Int
    var status: String
    
    init(bookingID: Int, userID: Int, teamID: Int, status: String) {
        self.bookingID = bookingID
        self.userID = userID
        self.teamID = teamID
        self.status = status
    }
}
