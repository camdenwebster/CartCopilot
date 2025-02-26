//
//  ItemDetailView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
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
    @State private var brand: String? = nil
    @State private var quantity = 1
    @State private var currentPrice: Decimal?
    @State private var selectedCategory: Category?
    @State private var preferredStore: Store? = nil
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
        
        // Only set preferredStore if we're in a trip
        if isShoppingTripItem, let tripStore = trip?.store {
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
                brand: $brand,
                currentPrice: $currentPrice,
                isEnabled: isFieldsEnabled,
                item: item
            )
            
            ItemCategoryStoreSection(
                selectedCategory: $selectedCategory,
                preferredStore: $preferredStore,
                categories: categories,
                stores: stores,
                isShoppingTripItem: isShoppingTripItem,
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
        }
    }
    
    private struct ItemBasicInfoSection: View {
        @Binding var name: String
        @Binding var brand: String?
        @Binding var currentPrice: Decimal?
        @State private var showingBarcodeScanner = false
        @State private var upcString = ""
        let isEnabled: Bool
        @FocusState private var isPriceFieldFocused: Bool
        @State private var priceString = ""
        var item: Item?
        
        private var currencySymbol: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = .current
            return formatter.currencySymbol
        }
        
        // Added helper method to format price string with implicit decimal point
        private func formattedPriceString(_ input: String) -> String {
            // Filter out non-numeric characters
            let numericString = input.filter { $0.isNumber }
            
            if numericString.isEmpty {
                return ""
            }
            
            // Convert to a Decimal amount (divide by 100 to place decimal point)
            let amountValue = Decimal(string: numericString) ?? 0
            let amount = amountValue / 100
            
            // Format with 2 decimal places
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            
            return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? ""
        }
        
        var body: some View {
            Section(header: Text("Item Details")) {
                // Item field
                HStack(spacing: 0) {
                    Text("Item")
                    Spacer()
                    TextField("Item Name", text: $name)
                        .disabled(!isEnabled)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .frame(maxWidth: 200, alignment: .trailing)
                }
                
                // Brand field
                HStack(spacing: 0) {
                    Text("Brand")
                    Spacer()
                    TextField("Brand Name", text: Binding(
                        get: { brand ?? "" },
                        set: { brand = $0.isEmpty ? nil : $0 }
                    ))
                        .disabled(!isEnabled)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .frame(maxWidth: 200, alignment: .trailing)
                }
                
                // Price field
                HStack {
                    Text("Price")
                    Spacer()
                    HStack(spacing: 0) {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("", text: $priceString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .focused($isPriceFieldFocused)
                            .frame(minWidth: 60, maxWidth: 75, alignment: .trailing)
                            .disabled(!isEnabled)
                            .foregroundColor(isEnabled ? .primary : .secondary)
                            .onChange(of: priceString) { oldValue, newValue in
                                // Filter and allow only numbers
                                let filteredValue = newValue.filter { $0.isNumber }
                                
                                // If the user changed the string and it doesn't match our filtered value
                                if newValue != filteredValue {
                                    priceString = filteredValue
                                }
                                
                                // Format for display with decimal point
                                let formattedValue = formattedPriceString(filteredValue)
                                
                                // Only update the UI if we have a valid format and it's different
                                if !formattedValue.isEmpty && formattedValue != priceString {
                                    priceString = formattedValue
                                }
                                
                                // Update the actual Decimal value for storage
                                if !filteredValue.isEmpty {
                                    let numericString = filteredValue
                                    if let decimalValue = Decimal(string: numericString) {
                                        currentPrice = decimalValue / 100
                                    }
                                } else {
                                    currentPrice = nil
                                }
                            }
                            .overlay(
                                Group {
                                    if priceString.isEmpty && !isPriceFieldFocused {
                                        Text("0.00")
                                            .foregroundColor(.gray)
                                            .allowsHitTesting(false)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                            )
                    }
                    .frame(maxWidth: 120, alignment: .trailing)
                }
                .onAppear {
                    if let price = currentPrice {
                        // Convert to integer by multiplying by 100 and rounding properly
                        let scaledValue = price * Decimal(100)
                        let intValue = Int(NSDecimalNumber(decimal: scaledValue).rounding(accordingToBehavior: nil).intValue)
                        priceString = formattedPriceString(String(intValue))
                    }
                }
                
                // UPC field
                HStack {
                    TextField("UPC", text: $upcString)
                        .disabled(!isEnabled)
                        .onChange(of: upcString) { oldValue, newValue in
                            item?.upc = newValue.isEmpty ? nil : newValue
                        }
                        .onAppear {
                            if let existingUPC = item?.upc {
                                upcString = existingUPC
                            }
                        }
                    
                    if isEnabled {
                        Button(action: {
                            showingBarcodeScanner = true
                            TelemetryManager.shared.trackBarcodeScannerUsed()
                        }) {
                            Image(systemName: "barcode.viewfinder")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .sheet(isPresented: $showingBarcodeScanner) {
                    BarcodeScannerView { scannedCode in
                        upcString = scannedCode
                        item?.upc = scannedCode
                        showingBarcodeScanner = false
                    }
                }
            }
        }
    }

    private struct ItemCategoryStoreSection: View {
        @Binding var selectedCategory: Category?
        @Binding var preferredStore: Store?
        let categories: [Category]
        let stores: [Store]
        let isShoppingTripItem: Bool
        let isEnabled: Bool
        
        var body: some View {
            if isEnabled {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories) { category in
                        Text(category.name).tag(Optional(category))
                    }
                }
                
                if !isShoppingTripItem {
                    Picker("Preferred Store", selection: $preferredStore) {
                        Text("None").tag(Optional<Store>(nil))
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
                .onChange(of: selectedPhoto) { oldValue, newValue in loadPhoto() }
                .onChange(of: name) { oldValue, newValue in checkForChanges() }
                .onChange(of: currentPrice) { oldValue, newValue in checkForChanges() }
                .onChange(of: selectedCategory) { oldValue, newValue in checkForChanges() }
                .onChange(of: preferredStore) { oldValue, newValue in checkForChanges() }
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
            if selectedCategory == nil {
                selectedCategory = categories.first(where: { $0.name == "Other" }) ?? categories.first
            }
            // Only set preferredStore if we're in a shopping trip
            if isShoppingTripItem {
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
    
    // Update saveItem function
    func saveItem() {
        guard let category = selectedCategory else { return }
        
        // Set name to "Untitled" if empty
        let itemName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : name
        let price = currentPrice ?? Decimal()
        
        do {
            if let existingShoppingItem = shoppingItem {
                existingShoppingItem.item.name = itemName
                existingShoppingItem.item.brand = brand
                existingShoppingItem.quantity = quantity
                existingShoppingItem.item.currentPrice = price
                existingShoppingItem.item.category = category
                // Make sure we have a non-optional store value
                if let store = preferredStore ?? trip?.store {
                    existingShoppingItem.store = store
                }
                
                // Track shopping item edit
                TelemetryManager.shared.trackShoppingItemEdited(name: itemName)
            } else if let existingItem = item {
                existingItem.name = itemName
                existingItem.brand = brand
                existingItem.currentPrice = price
                existingItem.category = category
                existingItem.preferredStore = preferredStore
                
                // Track item edit
                TelemetryManager.shared.trackItemEdited(name: itemName)
            } else {
                let newItem = Item(
                    name: itemName,
                    currentPrice: price,
                    category: category,
                    preferredStore: preferredStore
                )
                
                // Set brand if provided
                newItem.brand = brand
                
                if isShoppingTripItem {
                    modelContext.insert(newItem)
                    print("Successfully saved new Item")
                    
                    // Track item creation
                    TelemetryManager.shared.trackItemCreated(
                        name: itemName,
                        price: NSDecimalNumber(decimal: price).doubleValue,
                        category: category.name
                    )
                    
                    // Make sure we have a non-optional store value
                    if let store = preferredStore ?? trip?.store {
                        let newShoppingItem = try ShoppingItem(
                            item: newItem,
                            quantity: quantity,
                            store: store
                        )
                        
                        modelContext.insert(newShoppingItem)
                        
                        // Track shopping item added
                        TelemetryManager.shared.trackShoppingItemAdded(
                            name: itemName,
                            price: NSDecimalNumber(decimal: price).doubleValue,
                            fromExisting: false
                        )
                        
                        if let trip = trip {
                            newShoppingItem.trip = trip
                            trip.items.append(newShoppingItem)
                        }
                    }
                } else {
                    modelContext.insert(newItem)
                    
                    // Track item creation
                    TelemetryManager.shared.trackItemCreated(
                        name: itemName,
                        price: NSDecimalNumber(decimal: price).doubleValue,
                        category: category.name
                    )
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
