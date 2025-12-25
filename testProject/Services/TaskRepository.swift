//
//  TaskRepository.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import Foundation
import SwiftData

/// Repositori sederhana untuk operasi persistence `Task` menggunakan SwiftData.
final class TaskRepository {
    /// Menyisipkan `Task` ke dalam konteks model.
    /// - Parameters:
    ///   - task: Objek `Task` yang akan disimpan.
    ///   - context: `ModelContext` tujuan penyimpanan.
    func insert(_ task: Task, in context: ModelContext) {
        context.insert(task)
    }

    /// Menghapus `Task` dari konteks model.
    /// - Parameters:
    ///   - task: Objek `Task` yang akan dihapus.
    ///   - context: `ModelContext` sumber penghapusan.
    func delete(_ task: Task, from context: ModelContext) {
        context.delete(task)
    }

    /// Menghapus beberapa `Task` sekaligus dari konteks model.
    /// - Parameters:
    ///   - tasks: Kumpulan `Task` yang akan dihapus.
    ///   - context: `ModelContext` sumber penghapusan.
    func delete(tasks: [Task], from context: ModelContext) {
        for t in tasks { context.delete(t) }
    }
}

