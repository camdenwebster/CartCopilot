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
            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
        
}

#Preview {
    MainTabView()
}
