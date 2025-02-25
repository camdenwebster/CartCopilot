//
//  MainTabView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ShoppingTripListView()
                .tabItem {
                    Label("Trips", systemImage: "cart.badge.plus")
                }
                .tag(0)
            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
                .tag(1)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .onChange(of: 0) { oldValue, newValue in
            // Track tab selection with telemetry
            let tabName: String
            switch newValue {
            case 0: tabName = "trips"
            case 1: tabName = "items"
            case 2: tabName = "settings"
            default: tabName = "unknown"
            }
            TelemetryManager.shared.trackTabSelected(tab: tabName)
        }
    }
        
}

#Preview {
    MainTabView()
}
