//
//  UILabel+Extensions.swift
//  TextIt
//
//  Created by Piyush Pandey on 01/06/24.
//

import Foundation
import UIKit

extension UILabel {
    func addLeading(image: UIImage?) {
        guard let image else { return }
        let attachment = NSTextAttachment()
        attachment.image = image
        let attachmentString = NSAttributedString(attachment: attachment)
        let imageString = NSMutableAttributedString(string: "")
        imageString.append(attachmentString)
        
        guard let text = self.text else { return }
        
        let actualText = NSMutableAttributedString(string: " \(text)")
        imageString.append(actualText)
        self.attributedText = imageString
    }
}
