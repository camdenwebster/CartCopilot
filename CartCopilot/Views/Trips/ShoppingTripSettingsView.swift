//
//  ShoppingTripSettingsView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

struct ShoppingTripSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var stores: [Store]
    @State private var selectedStore: Store?
    @State private var navigateToList = false

    
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Select a Store", selection: $selectedStore) {
                    ForEach(stores) { store in
                        Text(store.name)
                            .tag(store as Store?)
                    }
                    if stores.isEmpty {
                        Text("No stores available")
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
            }
            .navigationTitle("Select a Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveTrip()
                        dismiss()
                    }
                    .bold()
                    .disabled(selectedStore == nil)
                }
            }
        }
    }
    
    func saveTrip() {
        guard let store = selectedStore else { return }
        modelContext.insert(ShoppingTrip(store: store))
    }
}

#Preview {
    ShoppingTripSettingsView()
}
