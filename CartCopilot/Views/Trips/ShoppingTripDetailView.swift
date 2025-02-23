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
    @State private var selectedShoppingItem: ShoppingItem?

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

    struct CategoryTotal: Identifiable {
        let id = UUID()
        let category: Category
        let subtotal: Decimal
        let tax: Decimal
        
        var total: Decimal {
            subtotal + tax
        }
    }

    private var categoryTotals: [CategoryTotal] {
        let categories = Set(trip.items.map { $0.item.category })
        return categories.map { category in
            let items = trip.items.filter { $0.item.category.id == category.id }
            let subtotal = items.reduce(Decimal(0)) { total, item in
                total + (item.item.currentPrice * Decimal(item.quantity))
            }
            let tax = items.reduce(Decimal(0)) { total, item in
                total + (item.item.currentPrice * Decimal(item.quantity) * Decimal(item.item.category.taxRate))
            }
            return CategoryTotal(category: category, subtotal: subtotal, tax: tax)
        }.sorted { $0.category.name < $1.category.name }
    }
    
    init(trip: ShoppingTrip) {
        self.trip = trip
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category totals section
                if !categoryTotals.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(categoryTotals) { categoryTotal in
                                VStack(alignment: .leading) {
                                    Text(categoryTotal.category.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(categoryTotal.total.formatted(.currency(code: currencyCode)))
                                        .font(.headline)
                                }
                                .frame(minWidth: 100)
                            }
                        }
                        .padding()
                    }
                    .background(.regularMaterial)
                }
                
                // Your existing List
                List {
                    ForEach(trip.items.sorted { $0.dateAdded > $1.dateAdded }) { shoppingItem in
                        NavigationLink {
                            ItemDetailView(shoppingItem: shoppingItem,
                                         trip: trip,
                                         isShoppingTripItem: true,
                                         isPresentedAsSheet: false
                            )
                        } label: {
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
            }
            .onAppear(perform: printItems)
            .navigationTitle("\(trip.store.name) total: \(formattedTotal)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewItem = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewItem) {
                ItemDetailView(trip: trip, isShoppingTripItem: true,
                              isPresentedAsSheet: true
                )
            }
        }
    }

    func removeItems(at offsets: IndexSet) {
        let sortedItems = trip.items.sorted { $0.dateAdded > $1.dateAdded }
        for offset in offsets {
            let item = sortedItems[offset]
            modelContext.delete(item)
        }
    }
    
    func printItems() {
        print("Found items for trip at \(trip.store.name):")
        for item in trip.items {
            print("- \(item.item.name) (Qty: \(item.quantity))")
        }
    }
}

extension ShoppingTrip {
    var subtotal: Decimal {
        items.reduce(Decimal(0)) { total, item in
            total + (item.item.currentPrice * Decimal(item.quantity))
        }
    }

    var totalTax: Decimal {
        items.reduce(Decimal(0)) { total, item in
            total + (item.item.currentPrice * Decimal(item.quantity) * Decimal(item.item.category.taxRate))
        }
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
