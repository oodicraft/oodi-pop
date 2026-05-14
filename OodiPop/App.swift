//
//  OodiPopApp.swift
//  OodiPop
//
//  Created by 唐浪 on 2026.05.14.
//

import SwiftUI

@main
struct OodiPopApp: App {
    @StateObject private var store = OodiPopStore()

    var body: some Scene {
        MenuBarExtra {
            OodiPopMenuView()
                .environmentObject(store)
                .frame(width: 420, height: 620)
        } label: {
            Image(systemName: "sparkles.rectangle.stack")
        }
        .menuBarExtraStyle(.window)
    }
}
