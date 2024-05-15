//
//  StorageManager.swift
//  TextIt
//
//  Created by Piyush Pandey on 16/05/24.
//

import FirebaseStorage
import Foundation

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
}
