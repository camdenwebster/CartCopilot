//
//  SettingsView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Management") {
                    NavigationLink("Categories") {
                        CategoriesView()
                    }
                    
                    NavigationLink("Stores") {
                        StoresView()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Category.name)
    ]) private var categories: [Category]
    @State private var showingAddCategory = false
    
    var body: some View {
        List {
            ForEach(categories) { category in
                NavigationLink {
                    CategoryFormView(category: category, showSheet: .constant(false))
                } label: {
                    HStack {
                        Text(category.name)
                        Spacer()
                        Text(category.taxRate, format: .percent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        }
        .navigationDestination(isPresented: $showingAddCategory) {
            CategoryFormView(showSheet: $showingAddCategory)
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
    }
}

struct StoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Store.name)
    ]) private var stores: [Store]
    @State private var showingAddStore = false
    
    var body: some View {
        List {
            ForEach(stores) { store in
                NavigationLink {
                    StoreFormView(store: store, showSheet: .constant(false))
                } label: {
                    VStack(alignment: .leading) {
                        Text(store.name)
                        Text(store.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteStores)
        }
        .navigationTitle("Stores")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddStore = true
            } label: {
                Label("Add Store", systemImage: "plus")
            }
        }
        .navigationDestination(isPresented: $showingAddStore) {
            StoreFormView(showSheet: $showingAddStore)
        }
    }
    
    private func deleteStores(at offsets: IndexSet) {
        for index in offsets {
            let store = stores[index]
            modelContext.delete(store)
        }
    }
}

struct CategoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var showSheet: Bool
    
    var category: Category?
    @State private var name: String
    @State private var taxRate: Double
    
    init(category: Category? = nil, showSheet: Binding<Bool>) {
        self.category = category
        self._showSheet = showSheet
        self._name = State(initialValue: category?.name ?? "")
        self._taxRate = State(initialValue: category?.taxRate ?? 0.0825)
    }
    
    var body: some View {
        Form {
            TextField("Category Name", text: $name)
            HStack {
                Text("Tax Rate")
                Spacer()
                Text(taxRate, format: .percent)
            }
            Stepper("", value: $taxRate, in: 0...1, step: 0.0025)
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showSheet = false
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCategory()
                    showSheet = false
                    dismiss()
                }
            }
        }
    }
    
    private func saveCategory() {
        if let existingCategory = category {
            existingCategory.name = name
            existingCategory.taxRate = taxRate
        } else {
            let newCategory = Category(name: name, taxRate: taxRate)
            modelContext.insert(newCategory)
        }
    }
}

struct StoreFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var showSheet: Bool
    
    var store: Store?
    @State private var name: String
    @State private var address: String
    
    init(store: Store? = nil, showSheet: Binding<Bool>) {
        self.store = store
        self._showSheet = showSheet
        self._name = State(initialValue: store?.name ?? "")
        self._address = State(initialValue: store?.address ?? "")
    }
    
    var body: some View {
        Form {
            TextField("Store Name", text: $name)
            TextField("Address", text: $address)
        }
        .navigationTitle(store == nil ? "New Store" : "Edit Store")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") {
//                    showSheet = false
//                    dismiss()
//                }
//            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveStore()
                    showSheet = false
                    dismiss()
                }
                .disabled(name.isEmpty)
            }
        }
    }
    
    private func saveStore() {
        if let existingStore = store {
            existingStore.name = name
            existingStore.address = address
        } else {
            let newStore = Store(name: name, address: address)
            modelContext.insert(newStore)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, Store.self])
}

