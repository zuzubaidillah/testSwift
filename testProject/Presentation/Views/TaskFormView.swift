//
//  TaskFormView.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import SwiftUI

/// Formulir tambah/edit tugas.
/// - Menyediakan input judul (wajib), catatan (opsional), dan status selesai.
/// - Memanggil `onSave` ketika pengguna menekan Simpan jika input valid.
struct TaskFormView: View {
    let task: Task?
    /// Callback saat data valid disimpan: `(title, notes, isDone)`.
    let onSave: (String, String?, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var isDone: Bool

    /// Membuat tampilan formulir untuk tambah atau edit tugas.
    /// - Parameters:
    ///   - task: Objek tugas untuk diedit; `nil` untuk membuat baru.
    ///   - onSave: Closure yang dipanggil saat tombol Simpan ditekan.
    init(task: Task? = nil, onSave: @escaping (String, String?, Bool) -> Void) {
        self.task = task
        self.onSave = onSave
        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _isDone = State(initialValue: task?.isDone ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detail Tugas") {
                    TextField("Judul", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)

                    TextField("Catatan (opsional)", text: $notes, axis: .vertical)
                        .lineLimit(1...5)

                    Toggle("Selesai", isOn: $isDone)
                }
            }
            .navigationTitle(task == nil ? "Tambah Tugas" : "Edit Tugas")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmedTitle, trimmedNotes.isEmpty ? nil : trimmedNotes, isDone)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct TaskFormView_Previews: PreviewProvider {
    static var previews: some View {
        TaskFormView { _, _, _ in }
    }
}
