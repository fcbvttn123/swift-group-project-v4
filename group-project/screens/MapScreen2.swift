//
//  MapScreen2.swift
//  group-project
//
//  Created by fizza imran on 2024-04-04.
//

import UIKit
import MapKit

class MapScreen2: UIViewController {
    
    var selectedMapItem: MKMapItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use selectedMapItem here
        if let selectedMapItem = selectedMapItem {
            // Perform actions with the selected map item
            print("Selected map item: \(selectedMapItem.name ?? "")")
        }
    }
}

