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
    // Environment and Query properties remain the same
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @Query(sort: [SortDescriptor(\Store.name)]) private var stores: [Store]
    
    // State properties remain the same
    var shoppingItem: ShoppingItem?
    var item: Item?
    var trip: ShoppingTrip?
    @State private var name = ""
    @State private var quantity = 1
    @State private var currentPrice: Decimal?
    @State private var selectedCategory: Category?
    @State private var preferredStore: Store?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isEditMode = false
    @State private var hasUnsavedChanges = false
    @State private var showingUnsavedChangesAlert = false
    @FocusState private var isPriceFieldFocused: Bool
    
    let isShoppingTripItem: Bool
    let isPresentedAsSheet: Bool
    
    // OriginalValues struct remains the same
    private struct OriginalValues {
        let name: String
        let price: Decimal
        let category: Category?
        let store: Store?
    }
    
    @State private var originalValues: OriginalValues?
    
    // Computed properties
    private var isEditing: Bool {
        shoppingItem != nil || item != nil
    }
    
    private var isFieldsEnabled: Bool {
        isPresentedAsSheet || isEditMode
    }
    
    // Initialize with default values
    init(
        shoppingItem: ShoppingItem? = nil,
        item: Item? = nil,
        trip: ShoppingTrip? = nil,
        isShoppingTripItem: Bool = false,
        isPresentedAsSheet: Bool = true
    ) {
        self.shoppingItem = shoppingItem
        self.item = item
        self.trip = trip
        self.isShoppingTripItem = isShoppingTripItem
        self.isPresentedAsSheet = isPresentedAsSheet
        
        // Handle store initialization separately
        if let tripStore = trip?.store {
            _preferredStore = State(initialValue: tripStore)
        }
    }
    
    // Move form content to computed property
    private var formContent: some View {
        Form {
            ItemPhotoSection(
                shoppingItem: shoppingItem,
                item: item,
                selectedPhoto: $selectedPhoto,
                isEnabled: isFieldsEnabled
            )
            
            ItemBasicInfoSection(
                name: $name,
                currentPrice: $currentPrice,
                isEnabled: isFieldsEnabled
            )
            
            if isShoppingTripItem {
                Section("Current Trip") {
                    HStack {
                        Text("Quantity")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(quantity)")
                    }
                    Stepper("", value: $quantity, in: 1...100)
                        .disabled(!isFieldsEnabled)
                }
            }
            
            ItemDetailsSection(
                selectedCategory: $selectedCategory,
                preferredStore: $preferredStore,
                categories: categories,
                stores: stores,
                isShoppingTripItem: isShoppingTripItem,
                isEnabled: isFieldsEnabled
            )
        }
    }
    
    private struct ItemBasicInfoSection: View {
        @Binding var name: String
        @Binding var currentPrice: Decimal?
        let isEnabled: Bool
        @FocusState private var isPriceFieldFocused: Bool
        @State private var priceString = "" // Add this for string-based price input
        
        private var currencySymbol: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = .current
            return formatter.currencySymbol
        }
        
        var body: some View {
            Section {
                TextField("Item Name", text: $name)
                    .disabled(!isEnabled)
                
                HStack(spacing: 2) {
                    Text(currencySymbol)
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .leading) {
                        // Replace Decimal TextField with string-based TextField
                        TextField("", text: $priceString)
                            .keyboardType(.decimalPad)
                            .focused($isPriceFieldFocused)
                            .disabled(!isEnabled)
                            .foregroundColor(.primary)
                            .onChange(of: priceString) {
                                // Convert string to Decimal when the user types
                                if let decimal = Decimal(string: priceString) {
                                    currentPrice = decimal
                                } else if priceString.isEmpty {
                                    currentPrice = nil
                                }
                            }
                            .onAppear {
                                // Initialize priceString from currentPrice if it exists
                                if let price = currentPrice {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.minimumFractionDigits = 2
                                    formatter.maximumFractionDigits = 2
                                    if let str = formatter.string(from: NSDecimalNumber(decimal: price)) {
                                        priceString = str
                                    }
                                }
                            }
                        
                        if priceString.isEmpty && !isPriceFieldFocused {
                            Text("0.00")
                                .foregroundColor(.gray)
                                .allowsHitTesting(false)
                        }
                    }
                }
            } header: {
                Text("Basic Info")
            }
        }
    }

    private struct ItemDetailsSection: View {
        @Binding var selectedCategory: Category?
        @Binding var preferredStore: Store?
        let categories: [Category]
        let stores: [Store]
        let isShoppingTripItem: Bool
        let isEnabled: Bool
        
        var body: some View {
            Section {
                if isEnabled {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category))
                        }
                    }
                    
                    if !isShoppingTripItem {
                        Picker("Preferred Store", selection: $preferredStore) {
                            ForEach(stores) { store in
                                Text(store.name).tag(Optional(store))
                            }
                        }
                    }
                } else {
                    HStack {
                        Text("Category")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(selectedCategory?.name ?? "None")
                    }
                    
                    if !isShoppingTripItem {
                        HStack {
                            Text("Preferred Store")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(preferredStore?.name ?? "None")
                        }
                    }
                }
            } header: {
                Text("Details")
            }
        }
    }

    // Move toolbar content to computed property
    private var toolbarContent: some ToolbarContent {
        Group {
            if isPresentedAsSheet {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: handleDismiss)
                }
            } else if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", action: handleDismiss)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if isPresentedAsSheet {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .bold()
                } else {
                    if isEditMode {
                        Button("Save") {
                            saveItem()
                            isEditMode = false
                            hasUnsavedChanges = false
                        }
                        .bold()
                    } else {
                        Button("Edit") {
                            isEditMode = true
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(isEditing ? "Edit Item" : "New Item")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(!isPresentedAsSheet)
                .onChange(of: selectedPhoto) { loadPhoto() }
                .onChange(of: name) { _ in checkForChanges() }
                .onChange(of: currentPrice) { _ in checkForChanges() }
                .onChange(of: selectedCategory) { _ in checkForChanges() }
                .onChange(of: preferredStore) { _ in checkForChanges() }
                .onAppear(perform: setupInitialValues)
                .toolbar { toolbarContent }
                .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
                    Button("Discard Changes", role: .destructive) {
                        if !isPresentedAsSheet {
                            isEditMode = false
                        }
                        hasUnsavedChanges = false
                        dismiss()
                    }
                    Button("Save") {
                        saveItem()
                        if !isPresentedAsSheet {
                            isEditMode = false
                        }
                        hasUnsavedChanges = false
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Do you want to save your changes before leaving?")
                }
                .interactiveDismissDisabled(hasUnsavedChanges)
        }
    }
    
    // Move setup logic to separate function
    private func setupInitialValues() {
        if let existingShoppingItem = shoppingItem {
            name = existingShoppingItem.item.name
            quantity = existingShoppingItem.quantity
            currentPrice = existingShoppingItem.item.currentPrice
            selectedCategory = existingShoppingItem.item.category
            preferredStore = existingShoppingItem.store
            originalValues = OriginalValues(
                name: name,
                price: currentPrice ?? Decimal(),
                category: selectedCategory,
                store: preferredStore
            )
        } else if let existingItem = item {
            name = existingItem.name
            currentPrice = existingItem.currentPrice
            selectedCategory = existingItem.category
            preferredStore = existingItem.preferredStore
            originalValues = OriginalValues(
                name: name,
                price: currentPrice ?? Decimal(),
                category: selectedCategory,
                store: preferredStore
            )
        } else {
            currentPrice = nil
            if selectedCategory == nil, let firstCategory = categories.first {
                selectedCategory = firstCategory
            }
            if preferredStore == nil {
                preferredStore = trip?.store ?? stores.first
            }
        }
    }
    
    // Your existing functions remain the same
    private func handleDismiss() {
        if hasUnsavedChanges {
            showingUnsavedChangesAlert = true
        } else {
            if !isPresentedAsSheet {
                isEditMode = false
            }
            dismiss()
        }
    }
    
    private func loadPhoto() {
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
    
    private func checkForChanges() {
        guard let original = originalValues else { return }
        hasUnsavedChanges = name != original.name ||
        (currentPrice ?? Decimal()) != original.price ||
        selectedCategory != original.category ||
        preferredStore != original.store
    }
    
    // Your saveItem function remains the same
    func saveItem() {
        guard let category = selectedCategory else { return }
        guard let store = preferredStore else { return }
        
        let price = currentPrice ?? Decimal()
        
        do {
            if let existingShoppingItem = shoppingItem {
                existingShoppingItem.item.name = name
                existingShoppingItem.quantity = quantity
                existingShoppingItem.item.currentPrice = price
                existingShoppingItem.item.category = category
                existingShoppingItem.store = store
            } else if let existingItem = item {
                existingItem.name = name
                existingItem.currentPrice = price
                existingItem.category = category
                existingItem.preferredStore = store
            } else {
                let newItem = Item(
                    name: name,
                    currentPrice: price,
                    category: category,
                    preferredStore: store
                )
                
                if isShoppingTripItem {
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
                    modelContext.insert(newItem)
                }
            }
            
            try modelContext.save()
            print("Successfully saved new ShoppingItem")
            
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
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Item.self, ShoppingItem.self, Category.self, Store.self, configurations: config)
        
        let context = container.mainContext
        
        let category = Category(name: "Test Category", taxRate: 0.08)
        let store = Store(name: "Test Store", address: "123 Test St")
        context.insert(category)
        context.insert(store)
        try context.save()
        
        return ItemDetailView(
            isShoppingTripItem: true,
            isPresentedAsSheet: true
        )
        .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}
