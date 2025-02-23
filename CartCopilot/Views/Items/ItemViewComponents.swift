// New file: ItemViewComponents.swift

import SwiftUI
import PhotosUI

struct ItemPhotoSection: View {
    let shoppingItem: ShoppingItem?
    let item: Item?
    @Binding var selectedPhoto: PhotosPickerItem?
    let isEnabled: Bool
    
    var body: some View {
        Section {
            if let imageData = shoppingItem?.item.photoData ?? item?.photoData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            }
            
            if isEnabled {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    Label("Select Photo", systemImage: "photo")
                }
            }
        }
    }
}

struct ItemBasicInfoSection: View {
    @Binding var name: String
    @Binding var currentPrice: Decimal
    let isEnabled: Bool
    
    var body: some View {
        Section {
            TextField("Item Name", text: $name)
                .disabled(!isEnabled)
            
            TextField("Price", value: $currentPrice, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .disabled(!isEnabled)
        }
    }
}

struct ItemDetailsSection: View {
    @Binding var selectedCategory: Category?
    @Binding var preferredStore: Store?
    let categories: [Category]
    let stores: [Store]
    let isShoppingTripItem: Bool
    let isEnabled: Bool
    
    var body: some View {
        Section {
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories) { category in
                    Text(category.name).tag(category as Category?)
                }
            }
            .disabled(!isEnabled)
            
            if !isShoppingTripItem {
                Picker("Preferred Store", selection: $preferredStore) {
                    ForEach(stores) { store in
                        Text(store.name).tag(store as Store?)
                    }
                }
                .disabled(!isEnabled)
            }
        }
    }
}

// End of file
