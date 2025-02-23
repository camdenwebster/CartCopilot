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
    @State private var showingItemSelector = false

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

    private struct ItemSelectorView: View {
        @Environment(\.modelContext) private var modelContext
        @Environment(\.dismiss) private var dismiss
        @Bindable var trip: ShoppingTrip
        @State private var selectedItems = Set<Item>()
        @Query(sort: [SortDescriptor(\Item.name)]) private var items: [Item]
        
        private var groupedItems: [String: [Item]] {
            Dictionary(grouping: items.filter { item in
                // Filter items that either have no preferred store or match the trip's store
                item.preferredStore == nil || item.preferredStore?.id == trip.store.id
            }) { $0.category.name }
        }
        
        private var sortedCategories: [String] {
            groupedItems.keys.sorted()
        }
        
        var body: some View {
            NavigationStack {
                List {
                    ForEach(sortedCategories, id: \.self) { categoryName in
                        Section(categoryName) {
                            if let itemsInCategory = groupedItems[categoryName] {
                                ForEach(itemsInCategory.sorted(by: { $0.name < $1.name })) { item in
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        if selectedItems.contains(item) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedItems.contains(item) {
                                            selectedItems.remove(item)
                                        } else {
                                            selectedItems.insert(item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Items")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Add Items") {
                            addSelectedItems()
                            dismiss()
                        }
                        .bold()
                    }
                }
            }
        }
        
        private func addSelectedItems() {
            for item in selectedItems {
                do {
                    // If the item has no preferred store, set it to the trip's store
                    if item.preferredStore == nil {
                        item.preferredStore = trip.store
                    }
                    
                    let shoppingItem = try ShoppingItem(
                        item: item,
                        quantity: 1,
                        store: trip.store
                    )
                    modelContext.insert(shoppingItem)
                    trip.items.append(shoppingItem)
                } catch {
                    print("Error adding item: \(error)")
                }
            }
        }
    }
    // MARK: - Body
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
                    if trip.items.isEmpty {
                        ContentUnavailableView(
                            "No Items",
                            systemImage: "carrot",
                            description: Text("Add a new item or select an existing item to get started")
                        )
                    } else {
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
            }
            .onAppear(perform: printItems)
            .navigationTitle("\(trip.store.name) total: \(formattedTotal)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingNewItem = true
                        } label: {
                            Label("New Item", systemImage: "plus")
                        }
                        
                        Button {
                            showingItemSelector = true
                        } label: {
                            Label("Add Existing Items", systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewItem) {
                ItemDetailView(trip: trip, isShoppingTripItem: true,
                              isPresentedAsSheet: true
                )
            }
            .sheet(isPresented: $showingItemSelector) {
                ItemSelectorView(trip: trip)
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
