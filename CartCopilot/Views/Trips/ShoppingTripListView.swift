//
//  ShoppingTripListView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

struct ShoppingTripListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.locale) var locale
    @Query(sort: [SortDescriptor(\ShoppingTrip.date, order: .reverse)]) private var trips: [ShoppingTrip]
    @State private var showingNewTrip = false
    @State private var selectedTrip: ShoppingTrip?

    private var currencyCode: String {
        locale.currency?.identifier ?? "USD"
    }

    private let theme: Theme = DefaultTheme()

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTrip) {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Shopping Trips",
                        systemImage: "cart",
                        description: Text("Add a new shopping trip to get started")
                    )
                    .foregroundStyle(theme.primaryText)
                } else {
                    ForEach(trips) { trip in
                        NavigationLink(value: trip) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(trip.store.name)
                                        .foregroundStyle(theme.primaryText)
                                    Text(trip.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(theme.secondaryAccent)
                                }
                                Spacer()
                                Text(trip.total.formatted(.currency(code: currencyCode)))
                                    .foregroundStyle(theme.accent)
                            }
                        }
                    }
                    .onDelete(perform: deleteTrips)
                }
            }
            .navigationTitle("Shopping Trips")
            .tint(theme.secondaryAccent)
            .scrollContentBackground(.hidden)
            .background(theme.primaryBackground)
            .toolbar {
                Button {
                    TelemetryManager.shared.trackTabSelected(tab: "create-trip")
                    showingNewTrip = true
                } label: {
                    Label("Add Trip", systemImage: "plus")
                        .foregroundStyle(theme.secondaryAccent)
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                ShoppingTripSettingsView()
            }
        } detail: {
            if let trip = selectedTrip {
                ShoppingTripDetailView(trip: trip)
            } else {
                Text("Select a Trip")
                    .foregroundStyle(theme.primaryText)
            }
        }
        .onAppear {
            TelemetryManager.shared.trackTabSelected(tab: "trips-list")
            
            // Select the first trip if none is selected
            if selectedTrip == nil, let firstTrip = trips.first {
                selectedTrip = firstTrip
            }
        }
    }
    
    func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let trip = trips[index]
            modelContext.delete(trip)
            
            TelemetryManager.shared.trackShoppingTripCompleted(
                store: trip.store.name,
                itemCount: trip.items.count,
                totalAmount: NSDecimalNumber(decimal: trip.total).doubleValue
            )
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ShoppingTrip.self, configurations: config)
    
    // Add sample data
    let store = Store(name: "Sample Store", address: "123 Main st.")
    let trip = ShoppingTrip(store: store)
    
    // Insert directly into container's mainContext
    container.mainContext.insert(store)
    container.mainContext.insert(trip)
    
    return ShoppingTripListView()
        .modelContainer(container)
}
