//
//  UIViewController+Extensions.swift
//  TextIt
//
//  Created by Piyush Pandey on 06/05/24.
//

import Foundation
import UIKit

extension UIViewController {
    func showSnackBar(message: String) {
        let textLabel = PaddingLabel()
        textLabel.backgroundColor = UIColor.black
        textLabel.textColor = .white
        textLabel.textAlignment = .center
        textLabel.alpha = 1.0
        textLabel.layer.cornerRadius = 8.0
        textLabel.clipsToBounds = true
        textLabel.text = message
        textLabel.numberOfLines = 0
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            textLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100),
            textLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 100)
        ])
        
        UIView.animate(withDuration: 3.0, delay: 1.0, animations: {
            textLabel.alpha = 0.0
        }) { (isCompleted) in
            textLabel.removeFromSuperview()
        }
    }
}
