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
    
    var groupedItems: [String: [Item]] {
        Dictionary(grouping: filteredItems) { $0.category.name }
    }
    
    var sortedCategories: [String] {
        groupedItems.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCategories, id: \.self) { categoryName in
                    Section(categoryName) {
                        if let itemsInCategory = groupedItems[categoryName] {
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
                            .onDelete(perform: deleteItem)
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
    }
    
    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
    }
}

struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                
                if let store = item.preferredStore {
                    Text(store.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
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
    let category = Category(name: "Fruits", taxRate: 0.07)
    let item = Item(name: "Apple", currentPrice: 1.0, category: category, preferredStore: store)
    
    // First insert the category, then the item
    container.mainContext.insert(category)
    container.mainContext.insert(item)
    
    try? container.mainContext.save()
    
    return ItemListView()
        .modelContainer(container)
}
