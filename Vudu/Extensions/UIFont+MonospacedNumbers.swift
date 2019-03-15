//
//  UIFont+MonospacedNumbers.swift
//  Common
//
//  Created by Paul Calnan on 8/13/18.
//  Copyright © 2018 Bose Corporation. All rights reserved.
//

import UIKit

extension UIFont {

    /// Utility to return a copy of this font using monospaced numbers, if supported.
    var withMonospacedNumbers: UIFont {
        let originalFontDescriptor = self.fontDescriptor
        let fontDescriptorFeatureSettings = [
            [
                UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
            ]
        ]

        let fontDescriptorAttributes = [UIFontDescriptor.AttributeName.featureSettings: fontDescriptorFeatureSettings]
        let fontDescriptor = originalFontDescriptor.addingAttributes(fontDescriptorAttributes)

        return UIFont(descriptor: fontDescriptor, size: 0)
    }
}

extension UILabel {

    /// Utility to use a copy of the current font using monospaced numbers, if supported.
    func useMonospacedNumbers() {
        self.font = self.font.withMonospacedNumbers
    }
}
