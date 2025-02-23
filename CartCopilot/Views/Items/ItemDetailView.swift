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
    
    // Update properties to handle both Item and ShoppingItem scenarios
    var shoppingItem: ShoppingItem?
    var item: Item?
    var trip: ShoppingTrip?
    @State private var name = ""
    @State private var quantity = 1
    @State private var currentPrice = Decimal()
    @State private var selectedCategory: Category?
    @State private var preferredStore: Store?
    @State private var selectedPhoto: PhotosPickerItem?
    @FocusState private var isPriceFieldFocused: Bool
    
    var isShoppingTripItem: Bool
    var isPresentedAsSheet: Bool
    
    private var isEditing: Bool {
        shoppingItem != nil || item != nil
    }
    
    // Fix: Simplified initializer
    init(shoppingItem: ShoppingItem? = nil, item: Item? = nil, trip: ShoppingTrip? = nil, isShoppingTripItem: Bool = false, isPresentedAsSheet: Bool = true) {
        self.shoppingItem = shoppingItem
        self.item = item
        self.trip = trip
        self.isShoppingTripItem = isShoppingTripItem
        self.isPresentedAsSheet = isPresentedAsSheet
        
        // Initialize store from trip if available
        if let tripStore = trip?.store {
            _preferredStore = State(initialValue: tripStore)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let uiImage = shoppingItem?.item.photo {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else if let uiImage = item?.photo {
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
                    
                    if !isShoppingTripItem {
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
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhoto, loadPhoto)
            .toolbar {
                // Only show Cancel button when presented as sheet
                if isPresentedAsSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
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
                } else if let existingItem = item {
                    // Load item details without shopping item specifics
                    name = existingItem.name
                    currentPrice = existingItem.currentPrice
                    selectedCategory = existingItem.category
                    preferredStore = existingItem.preferredStore
                } else {
                    // Set defaults for new items
                    if selectedCategory == nil, let firstCategory = categories.first {
                        selectedCategory = firstCategory
                    }
                    if preferredStore == nil {
                        if let tripStore = trip?.store {
                            preferredStore = tripStore
                        } else if let firstStore = stores.first {
                            preferredStore = firstStore
                        }
                    }
                }
            }
        }
    }
    
    func loadPhoto() {
        Task { @MainActor in
            if let data = try await selectedPhoto?.loadTransferable(type: Data.self) {
                if let shoppingItem = shoppingItem {
                    shoppingItem.item.updatePhotoData(data)
                } else if let item = item {
                    item.updatePhotoData(data)
                }
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
            } else if let existingItem = item {
                // Update existing item
                existingItem.name = name
                existingItem.currentPrice = currentPrice
                existingItem.category = category
                existingItem.preferredStore = store
            } else {
                // Create new item
                let newItem = Item(
                    name: name,
                    currentPrice: currentPrice,
                    category: category,
                    preferredStore: store
                )
                
                if isShoppingTripItem {
                    // Create shopping item only if we're in a shopping trip context
                    modelContext.insert(newItem)
                    print("Successfully saved new Item")

                    let newShoppingItem = try ShoppingItem(
                        item: newItem,
                        quantity: quantity,
                        store: store
                    )
                    
                    modelContext.insert(newShoppingItem)
                    
                    if let trip = trip {
                        newShoppingItem.trip = trip
                        trip.items.append(newShoppingItem)
                    }
                } else {
                    // Just save the item without creating a shopping item
                    modelContext.insert(newItem)
                }
            }
            
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

    return ItemDetailView(
        shoppingItem: mockShoppingItem ?? nil,
        item: nil,
        trip: nil,
        isShoppingTripItem: true,
        isPresentedAsSheet: true
    )
    .modelContainer(for: [Item.self, ShoppingItem.self, Category.self, Store.self])
}
