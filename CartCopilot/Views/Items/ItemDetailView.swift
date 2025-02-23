//
//  ItemDetailView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

//
//  ItemDetailView.swift
//  Cart Copilot
//
//  Created by Camden Webster on 2/9/25.
//

import PhotosUI
import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Store.name)]) private var stores: [Store]
    
    // If item is nil, we're creating a new item
    var shoppingItem: ShoppingItem?
    var trip: ShoppingTrip?
    @State private var name = ""
    @State private var quantity = 1
    @State private var currentPrice = Decimal()
    @State private var selectedCategory: Category?
    @State private var preferredStore: Store?
    @State private var selectedPhoto: PhotosPickerItem?
    @FocusState private var isPriceFieldFocused: Bool
    
    var isShoppingTripItem: Bool
    
    private var isEditing: Bool {
        shoppingItem != nil
    }
    
    // Fix: Simplified initializer
    init(shoppingItem: ShoppingItem? = nil, trip: ShoppingTrip? = nil, isShoppingTripItem: Bool = false) {
        self.shoppingItem = shoppingItem
        self.trip = trip
        self.isShoppingTripItem = isShoppingTripItem
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let uiImage = shoppingItem?.item.photo {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    }
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Select Image", systemImage: "photo")
                    }
                }
                Section {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Price")
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 20)
                        Text("$")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("", value: $currentPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($isPriceFieldFocused)
                            .onChange(of: isPriceFieldFocused) { oldValue, newValue in
                                if newValue && currentPrice == 0 {
                                    currentPrice = Decimal()
                                }
                            }
                        
                    }
                }
                if isShoppingTripItem {
                    Section("Current Trip") {
                        HStack {
                            Text("Quantity")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(quantity)")
                        }
                        Stepper("", value: $quantity, in: 1...100)
                    }
                }
                Section("Details") {
                    HStack {
                        Text("Category")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $selectedCategory) {
                            ForEach(categories) { category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Preferred Store")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("", selection: $preferredStore) {
                            ForEach(stores) { store in
                                Text(store.name).tag(store as Store?)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhoto, loadPhoto)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                if let existingShoppingItem = shoppingItem {
                    name = existingShoppingItem.item.name
                    quantity = existingShoppingItem.quantity
                    currentPrice = existingShoppingItem.item.currentPrice
                    selectedCategory = existingShoppingItem.item.category
                    preferredStore = existingShoppingItem.store
                } else {
                    // Set the first store as the preferred store if it's nil
                    if preferredStore == nil, let firstStore = stores.first {
                        preferredStore = firstStore
                    }
                    if selectedCategory == nil, let firstCategory = categories.first {
                        selectedCategory = firstCategory
                    }
                }
            }
        }
    }
    
    func loadPhoto() {
        Task { @MainActor in
            if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                shoppingItem?.item.updatePhotoData(data)
            }
        }
    }
    
    func saveItem() {
        guard let category = selectedCategory else { return }
        guard let store = preferredStore else { return }
        
        do {
            if let existingShoppingItem = shoppingItem {
                // Update existing shopping item
                existingShoppingItem.item.name = name
                existingShoppingItem.quantity = quantity
                existingShoppingItem.item.currentPrice = currentPrice
                existingShoppingItem.item.category = category
                existingShoppingItem.store = store
            } else {
                print("Creating new item for trip: \(String(describing: trip))")
                
                // Create new item
                let newItem = Item(
                    name: name,
                    currentPrice: currentPrice,
                    category: category,
                    preferredStore: store
                )
                
                // Insert the new item first
                modelContext.insert(newItem)
                print("Successfully saved new Item")

                // Create shopping item
                let newShoppingItem = try ShoppingItem(
                    item: newItem,
                    quantity: quantity,
                    store: store
                )
                
                // Insert the shopping item
                modelContext.insert(newShoppingItem)
                
                // If we have a trip, associate the shopping item with it
                if let trip = trip {
                    print("Associating ShoppingItem with trip ID: \(trip.id)")
                    newShoppingItem.trip = trip
                    trip.items.append(newShoppingItem)  // Explicitly add to trip's items
                }
            }
            
            // Save the changes
            try modelContext.save()
            print("Successfully saved new ShoppingItem")
            
            // Verify the ShoppingItem was saved and associated with the trip
            if let trip = trip {
                print("Trip items after save: \(trip.items.count)")
                let tripItemNames = trip.items.map { $0.item.name }
                print("Items in trip: \(tripItemNames)")
            }
            
        } catch {
            print("Error saving item: \(error)")
        }
    }
}

#Preview {
    let mockCategory = Category(name: "Mock Category", taxRate: 0.0)
    let mockStore = Store(name: "Mock Store", address: "123 Main street")
    let mockItem = try? Item(name: "Mock Item", currentPrice: 10.0, category: mockCategory)
    let mockShoppingItem = try? mockItem.map { item in
        try ShoppingItem(item: item, store: mockStore)
    }

    return ItemDetailView(shoppingItem: mockShoppingItem ?? nil, trip: nil, isShoppingTripItem: true)
        .modelContainer(for: [Item.self, ShoppingItem.self, Category.self, Store.self])
}
