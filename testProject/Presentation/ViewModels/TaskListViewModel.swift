//
//  TaskListViewModel.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// ViewModel untuk mengelola operasi CRUD daftar tugas.
/// Berinteraksi dengan `TaskRepository` dan memberikan haptic/animasi melalui pemanggilan dari View.
final class TaskListViewModel: ObservableObject {
    private let repository = TaskRepository()

    /// Menambahkan tugas baru ke penyimpanan.
    /// - Parameters:
    ///   - title: Judul tugas (wajib, non-kosong setelah trim).
    ///   - notes: Catatan opsional untuk detail tambahan.
    ///   - isDone: Status penyelesaian tugas.
    ///   - modelContext: Context SwiftData untuk operasi penyimpanan.
    func addTask(title: String, notes: String?, isDone: Bool, modelContext: ModelContext) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTask = Task(title: trimmed, notes: notes, isDone: isDone, createdAt: Date(), updatedAt: Date())
        withAnimation { repository.insert(newTask, in: modelContext) }
        hapticSuccess()
    }

    /// Memperbarui tugas yang ada dengan nilai baru.
    /// - Parameters:
    ///   - task: Referensi `Task` yang akan diperbarui.
    ///   - title: Judul baru (wajib, non-kosong setelah trim).
    ///   - notes: Catatan opsional.
    ///   - isDone: Status penyelesaian baru.
    func updateTask(_ task: Task, title: String, notes: String?, isDone: Bool) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            task.title = trimmed
            task.notes = notes
            task.isDone = isDone
            task.updatedAt = Date()
        }
    }

    /// Menghapus satu tugas tertentu dari penyimpanan.
    /// - Parameters:
    ///   - task: Objek `Task` yang akan dihapus.
    ///   - modelContext: Context SwiftData untuk operasi penyimpanan.
    func deleteTask(_ task: Task, modelContext: ModelContext) {
        withAnimation { repository.delete(task, from: modelContext) }
        hapticImpact(.medium)
    }

    /// Menghapus kumpulan tugas berdasarkan indeks pada daftar terfilter (setelah filter + cari).
    /// - Parameters:
    ///   - offsets: Indeks baris pada tampilan `visibleTasks`.
    ///   - visibleTasks: Snapshot daftar tugas yang sedang ditampilkan.
    ///   - modelContext: Context SwiftData untuk operasi penyimpanan.
    func deleteTasks(at offsets: IndexSet, in visibleTasks: [Task], modelContext: ModelContext) {
        withAnimation {
            let targets = offsets.map { visibleTasks[$0] }
            repository.delete(tasks: targets, from: modelContext)
        }
    }

    /// Mengubah status selesai/belum-selesai pada tugas dan memperbarui cap waktu.
    /// - Parameter task: Objek `Task` yang akan di-toggle statusnya.
    func toggleDone(_ task: Task) {
        let newValue = !task.isDone
        withAnimation { task.isDone = newValue; task.updatedAt = Date() }
        if newValue { hapticSuccess() } else { hapticImpact(.light) }
    }

    /// Menjalankan pull-to-refresh dummy untuk memberikan umpan balik visual.
    /// Karena data bersifat lokal, fungsi ini hanya menunda sesaat.
    func refreshData() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                continuation.resume()
            }
        }
    }

    private enum ImpactStyle { case light, medium }

    /// Memicu haptic notifikasi sukses (iOS, bila tersedia) untuk menandai aksi berhasil.
    private func hapticSuccess() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    /// Memicu haptic impact dengan gaya tertentu (iOS, bila tersedia).
    /// - Parameter style: `.light` atau `.medium`.
    private func hapticImpact(_ style: ImpactStyle) {
        #if canImport(UIKit)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle = (style == .light) ? .light : .medium
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.impactOccurred()
        #endif
    }
}
