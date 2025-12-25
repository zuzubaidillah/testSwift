//
//  ContentView.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import SwiftUI
import SwiftData

/// Tampilan utama To-Do List berbasis SwiftUI + SwiftData.
/// Menyediakan operasi CRUD: tambah, baca, ubah, hapus tugas.
struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Task.createdAt, order: .reverse) private var tasks: [Task]

    @State private var showAddSheet = false
    @State private var taskForEdit: Task? = nil
    @AppStorage("todo.searchText") private var searchText: String = ""
    @AppStorage("todo.selectedFilter") private var selectedFilterRaw: String = Filter.all.rawValue
    @AppStorage("todo.sortOption") private var sortOptionRaw: String = SortOption.newest.rawValue
    @AppStorage("todo.seeded100") private var hasSeededInitialData: Bool = false
    @State private var itemsToShow: Int = 15
    @State private var isLoadingMore: Bool = false

    @StateObject private var viewModel = TaskListViewModel()

    /// Filter status tugas untuk tampilan daftar.
    private enum Filter: String, CaseIterable, Identifiable {
        case all = "Semua"
        case active = "Aktif"
        case completed = "Selesai"
        var id: String { rawValue }
    }

    /// Opsi pengurutan daftar tugas.
    private enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Terbaru"
        case oldest = "Terlama"
        case titleAZ = "Judul A-Z"
        case titleZA = "Judul Z-A"
        var id: String { rawValue }
    }

    /// Binding untuk `Filter` via AppStorage raw value.
    private var selectedFilter: Filter {
        get { Filter.allCases.first { $0.rawValue == selectedFilterRaw } ?? .all }
        set { selectedFilterRaw = newValue.rawValue }
    }

    /// Binding untuk `SortOption` via AppStorage raw value.
    private var sortOption: SortOption {
        get { SortOption.allCases.first { $0.rawValue == sortOptionRaw } ?? .newest }
        set { sortOptionRaw = newValue.rawValue }
    }

    /// Daftar tugas yang sudah difilter dan diurutkan berdasarkan `selectedFilter`, `searchText`, dan `sortOption`.
    private var visibleTasks: [Task] {
        let base: [Task]
        switch selectedFilter {
        case .all: base = tasks
        case .active: base = tasks.filter { !$0.isDone }
        case .completed: base = tasks.filter { $0.isDone }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = q.isEmpty ? base : base.filter { task in
            task.title.localizedCaseInsensitiveContains(q) || (task.notes?.localizedCaseInsensitiveContains(q) ?? false)
        }
        return filtered.sorted(by: { lhs, rhs in
            switch sortOption {
            case .newest: return lhs.createdAt > rhs.createdAt
            case .oldest: return lhs.createdAt < rhs.createdAt
            case .titleAZ: return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .titleZA: return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedDescending
            }
        })
    }

    /// Subset tugas yang ditampilkan pada halaman saat ini (pagination 15 per muatan).
    private var pagedTasks: [Task] {
        Array(visibleTasks.prefix(itemsToShow))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // Pemilih filter status (Semua/Aktif/Selesai)
                Picker("Filter", selection: $selectedFilterRaw) {
                    ForEach(Filter.allCases) { f in
                        Text(f.rawValue).tag(f.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    if visibleTasks.isEmpty {
                        ContentUnavailableView("Tidak ada tugas", systemImage: "checklist", description: Text("Coba ubah filter atau kata kunci."))
                    } else {
                        List {
                            ForEach(pagedTasks) { task in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(task.isDone ? .green : .secondary)
                                        .imageScale(.large)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.headline)
                                            .strikethrough(task.isDone, color: .secondary)

                                        if let notes = task.notes, !notes.isEmpty {
                                            Text(notes)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }

                                        Text(task.createdAt, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }

                                    Spacer()

                                    HStack(spacing: 8) {
                                        Button(role: .destructive) {
                                            viewModel.deleteTask(task, modelContext: modelContext)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .tint(.red)

                                        Button {
                                            viewModel.toggleDone(task)
                                        } label: {
                                            Text(task.isDone ? "Belum" : "Selesai")
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { taskForEdit = task }
                                .onAppear { loadMoreIfNeeded(currentItem: task) }
                                .tint(.primary)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) { viewModel.deleteTask(task, modelContext: modelContext) } label: {
                                        Label("Hapus", systemImage: "trash")
                                    }
                                    Button { taskForEdit = task } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .onDelete { offsets in
                                viewModel.deleteTasks(at: offsets, in: visibleTasks, modelContext: modelContext)
                            }

                            if itemsToShow < visibleTasks.count {
                                Section(footer:
                                    VStack(spacing: 8) {
                                        if isLoadingMore {
                                            HStack {
                                                ProgressView()
                                                Text("Memuat lebih banyak…")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .accessibilityLabel("Memuat lebih banyak")
                                        } else {
                                            Button(action: {
                                                loadMoreManually()
                                            }) {
                                                HStack {
                                                    Spacer()
                                                    Text("Muat Lagi")
                                                    Spacer()
                                                }
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .accessibilityHint("Memuat 15 item lagi")
                                        }
                                    }
                                ) { EmptyView() }
                            }
                        }
                        .refreshable { await viewModel.refreshData() }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("To-Do List")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Cari tugas")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Urutkan", selection: $sortOptionRaw) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                    } label: {
                        Label("Urutkan", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Tambah", systemImage: "plus")
                    }
                }
            }
            .onChange(of: selectedFilterRaw) { _, _ in resetPagination() }
            .onChange(of: sortOptionRaw) { _, _ in resetPagination() }
            .onChange(of: searchText) { _, _ in resetPagination() }
            .onAppear { seedInitialDataIfNeeded() }
            .sheet(isPresented: $showAddSheet) {
                TaskFormView { title, notes, isDone in
                    viewModel.addTask(title: title, notes: notes, isDone: isDone, modelContext: modelContext)
                }
            }
            .sheet(item: $taskForEdit) { task in
                TaskFormView(task: task) { title, notes, isDone in
                    viewModel.updateTask(task, title: title, notes: notes, isDone: isDone)
                }
            }
        }
    }
}

/// Menyuntikkan 100 data awal saat aplikasi pertama kali dibuka.
/// Menggunakan `@AppStorage("todo.seeded100")` sebagai penanda agar tidak duplikat.
private extension TaskListView {
    /// Memuat lebih banyak item secara manual (aksesibilitas).
    func loadMoreManually() {
        guard !isLoadingMore, itemsToShow < visibleTasks.count else { return }
        isLoadingMore = true
        withAnimation {
            itemsToShow = min(itemsToShow + 15, visibleTasks.count)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isLoadingMore = false
        }
    }

    /// Memuat lebih banyak item ketika baris terakhir halaman muncul.
    /// - Parameter currentItem: Item yang baru muncul di layar.
    func loadMoreIfNeeded(currentItem: Task) {
        guard let last = pagedTasks.last, currentItem.id == last.id else { return }
        guard itemsToShow < visibleTasks.count, !isLoadingMore else { return }
        isLoadingMore = true
        withAnimation { itemsToShow = min(itemsToShow + 15, visibleTasks.count) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { isLoadingMore = false }
    }

    /// Mereset pagination kembali ke 15 saat filter/pencarian/sort berubah.
    func resetPagination() {
        itemsToShow = 15
    }
    func seedInitialDataIfNeeded() {
        guard !hasSeededInitialData, tasks.isEmpty else { return }
        withAnimation {
            let now = Date()
            for i in 1...100 {
                let title = "Tugas \(i)"
                let created = now.addingTimeInterval(Double(-i) * 3600)
                let task = Task(title: title, notes: nil, isDone: false, createdAt: created, updatedAt: created)
                modelContext.insert(task)
            }
        }
        hasSeededInitialData = true
    }
}

// Kompatibilitas: gunakan PreviewProvider tradisional jika #Preview bermasalah.
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .modelContainer(for: Task.self, inMemory: true)
    }
}

