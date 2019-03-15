//
//  CLLocationManager.swift
//  zakChat
//
//  Created by Umar Qattan on 1/26/19.
//  Copyright © 2019 ukaton. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation


extension CLLocation {
    
    func distance(to friendLocation: CLLocation?) -> Double {
        guard let friendLocation = friendLocation else { return 0 }
        
        let lat1 = self.coordinate.latitude
        let lat2 = friendLocation.coordinate.latitude
        
        let lon1 = self.coordinate.longitude
        let lon2 = friendLocation.coordinate.longitude
        
        let R = 6371e3
        let phi1 = lat1.toRadians()
        let phi2 = lat2.toRadians()
        let deltaPhi = (lat2 - lat1).toRadians()
        let deltaLambda = (lon2 - lon1).toRadians()
        
        let a = sin(deltaPhi / 2) * sin(deltaPhi / 2) + cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        let d = R * c
        
        return d
    }
    
    func bearing(to friendLocation: CLLocation?) -> Double {
        guard let friendLocation = friendLocation else { return 0 }
        
        let lambda1 = self.coordinate.longitude
        let lambda2 = friendLocation.coordinate.longitude
        
        let phi1 = self.coordinate.latitude
        let phi2 = friendLocation.coordinate.latitude
        
        let y = sin(lambda2 - lambda1) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(lambda2 - lambda1)
        let bear = atan2(y, x).toDegrees()
        
        return bear
    }
    
}
