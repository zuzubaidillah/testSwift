//
//  testProjectApp.swift
//  testProject
//
//  Created by Macbook Pro on 25/12/25.
//

import SwiftUI
import SwiftData

@main
struct testProjectApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Task.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TaskListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
