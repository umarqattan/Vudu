//
//  CGFloat.swift
//  zakChat
//
//  Created by Umar Qattan on 1/26/19.
//  Copyright © 2019 ukaton. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat {
    func toRadians() -> CGFloat {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> CGFloat {
        return self * 180.0 / .pi
    }
}

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}
