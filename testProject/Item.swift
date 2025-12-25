//
//  Item.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
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
