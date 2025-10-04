//
//  Trailer_TreasureApp.swift
//  Trailer Treasure
//
//  Created by Nico Paganelli on 9/9/25.
//

import SwiftUI

@main
struct Trailer_TreasureApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
