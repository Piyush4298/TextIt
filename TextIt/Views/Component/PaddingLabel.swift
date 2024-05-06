//
//  PaddingLabel.swift
//  TextIt
//
//  Created by Piyush Pandey on 06/05/24.
//

import UIKit

class PaddingLabel: UILabel {

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)))
    }
    
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 20 + 20,
                      height: size.height + 14 + 14)
    }
}
