//
//  Item.swift
//  Repetitor
//
//  Created by Анна on 13.12.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
