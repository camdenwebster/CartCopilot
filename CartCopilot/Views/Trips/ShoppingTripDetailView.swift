//
//  ShoppingTripDetailView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import Foundation
import SwiftData
import SwiftUI

struct ShoppingTripDetailView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.locale) var locale
    @Bindable var trip: ShoppingTrip
    @State private var showingNewItem = false
    
    var shoppingItems: [ShoppingItem] {
        trip.items
    }
    
    init(trip: ShoppingTrip) {
        self.trip = trip
    }
    
    private var currencyCode: String {
        locale.currency?.identifier ?? "USD"
    }
    
    private var formattedSubtotal: String {
        trip.subtotal.formatted(.currency(code: currencyCode))
    }
    
    private var formattedTax: String {
        trip.totalTax.formatted(.currency(code: currencyCode))
    }
    
    private var formattedTotal: String {
        trip.total.formatted(.currency(code: currencyCode))
    }
    
    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                HStack {
//                    Text("Subtotal:")
//                    Spacer()
//                    Text(formattedSubtotal)
//                }
//            }
//            .frame(maxHeight: 50)
//        }
        List {
            ForEach(trip.items) { shoppingItem in
                NavigationLink(value: shoppingItem) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(shoppingItem.item.name)
                            Text(shoppingItem.item.category.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(shoppingItem.currentPrice as Decimal, format: .currency(code: currencyCode))
                            Text("Qty: \(shoppingItem.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: removeItems)
        }
        .navigationTitle(formattedTotal)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }        .sheet(isPresented: $showingNewItem) {
            ItemDetailView(trip: trip, isShoppingTripItem: true)
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        for offset in offsets {
            let item = shoppingItems[offset]
            modelContext.delete(item)
        }
    }
}

extension ShoppingTrip {
    var subtotal: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.item.currentPrice }
    }
    
    var totalTax: Decimal {
        items.reduce(Decimal(0)) { $0 + ($1.item.currentPrice * Decimal($1.item.category.taxRate)) }
    }
    
    var total: Decimal {
        subtotal + totalTax
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: ShoppingTrip.self, configurations: config)
        
        // Add sample data
        let store = Store(name: "Sample Store", address: "123 Main st.")
        let category = Category(name: "Groceries", taxRate: 0.08, isDefault: false)
        let item1 = try ShoppingItem(item: Item(name: "Apple", currentPrice: 2.5, category: category), quantity: 1, store: store)
        let trip = ShoppingTrip(store: store, items: [item1])

        // Insert directly into container's mainContext
        container.mainContext.insert(store)
        container.mainContext.insert(trip)
        
        return ShoppingTripDetailView(trip: trip)
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
