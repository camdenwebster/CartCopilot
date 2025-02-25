//
//  ShoppingTripListView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI
import TelemetryDeck

struct ShoppingTripListView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.locale) var locale
    @Query(sort: [SortDescriptor(\ShoppingTrip.date, order: .reverse)]) private var trips: [ShoppingTrip]
    @State private var showingNewTrip = false
    @State private var selectedTrip: ShoppingTrip?

    private var currencyCode: String {
        locale.currency?.identifier ?? "USD"
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTrip) {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Shopping Trips",
                        systemImage: "cart",
                        description: Text("Add a new shopping trip to get started")
                    )
                } else {
                    ForEach(trips) { trip in
                        NavigationLink(value: trip) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(trip.store.name)
                                    Text(trip.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(trip.total.formatted(.currency(code: currencyCode)))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTrips)
                }
            }
            .navigationTitle("Shopping Trips")
            .toolbar {
                Button {
                    TelemetryDeck.signal("Trip.List.createNewTrip")
                    showingNewTrip = true
                } label: {
                    Label("Add Trip", systemImage: "plus")
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
            }
        }
        .onAppear {
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
