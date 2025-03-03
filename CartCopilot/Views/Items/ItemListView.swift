//
//  ItemListView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftData
import SwiftUI

struct ItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewItem = false
    @Query private var items: [Item]
    @State private var searchText = ""
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var groupedItems: [Category: [Item]] {
        let grouped = Dictionary(grouping: filteredItems) { $0.category }
        // Create a new dictionary with sorted arrays
        return grouped.mapValues { items in
            items.sorted { $0.name < $1.name }
        }
    }
    
    var sortedCategories: [Category] {
        groupedItems.keys.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "carrot",
                        description: Text("Add a new item to get started")
                    )
                } else {
                    ForEach(sortedCategories) { category in
                        Section("\(category.emoji ?? "⚪\u{fe0f}") \(category.name)") {
                            if let itemsInCategory = groupedItems[category] {
                                ForEach(itemsInCategory) { item in
                                    NavigationLink {
                                        ItemDetailView(
                                            item: item,
                                            isShoppingTripItem: false,
                                            isPresentedAsSheet: false
                                        )
                                    } label: {
                                        ItemRow(item: item)
                                    }
                                }
                                .onDelete(perform: { offsets in
                                    deleteItems(category: category, at: offsets)
                                })
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("All Items")
            .toolbar {
                EditButton()
                Button {
                    showingNewItem = true
                    // Track when user initiates adding a new item
                    TelemetryManager.shared.trackTabSelected(tab: "add-item")
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewItem) {
            ItemDetailView(
                isShoppingTripItem: false,
                isPresentedAsSheet: true
            )
        }
        .onAppear {
            // Track when user views the items list
            TelemetryManager.shared.trackTabSelected(tab: "items-list")
        }
    }
    
    func deleteItems(category: Category, at offsets: IndexSet) {
        if let itemsInCategory = groupedItems[category] {
            for offset in offsets {
                let item = itemsInCategory[offset]
                modelContext.delete(item)
                // Track item deletion
                TelemetryManager.shared.trackItemDeleted()
            }
        }
    }
    
    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
            // Track item deletion
            TelemetryManager.shared.trackItemDeleted()
        }
    }
}

struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name)
                    if let brand = item.brand {
                        Text("by \(brand)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            Spacer()
            if let store = item.preferredStore {
                Text(store.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(item.currentPrice, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Item.self, Store.self, Category.self, configurations: config)
    
    // Create and insert sample data
    let store = Store(name: "Costco", address: "123 Main St.")
    let category = Category(name: "Fruits", taxRate: 0.07, emoji: "🍎")
    let item = Item(name: "Apple", currentPrice: 1.0, category: category, preferredStore: store)
    
    // First insert the category, then the item
    container.mainContext.insert(category)
    container.mainContext.insert(item)
    
    try? container.mainContext.save()
    
    return ItemListView()
        .modelContainer(container)
}
