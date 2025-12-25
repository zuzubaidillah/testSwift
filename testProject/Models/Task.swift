//
//  Task.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import Foundation
import SwiftData

@Model
final class Task {
    var title: String
    var notes: String?
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(title: String, notes: String? = nil, isDone: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.title = title
        self.notes = notes
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

