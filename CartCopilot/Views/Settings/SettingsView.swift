//
//  SettingsView.swift
//  CartCopilot
//
//  Created by Camden Webster on 2/22/25.
//

import SwiftUI
import SwiftData
import SafariServices

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSection: SettingsSection? = .categories // Default selection
    @State private var showingSafariView = false
    @State private var selectedURL: URL?

    // Add external links
    private let externalLinks: [String: ExternalLink] = [
        "knowledgeBase": ExternalLink(
            title: "Knowledge Base",
            icon: "questionmark.circle.fill",
            url: URL(string: "https://www.apple.com")!
        ),
        "support": ExternalLink(
            title: "Support",
            icon: "envelope.fill",
            url: URL(string: "https://developer.apple.com")!
        ),
        "roadmap": ExternalLink(
            title: "Roadmap",
            icon: "map.fill",
            url: URL(string: "https://mothersound.dev")!
        ),
        "rateUs": ExternalLink(
            title: "Rate Us",
            icon: "star.fill",
            url: URL(string: "https://mothersound.dev")!
        ),
        "privacyPolicy": ExternalLink(
            title: "Privacy Policy",
            icon: "lock.fill",
            url: URL(string: "https://mothersound.dev")!
        ),
        "termsOfService": ExternalLink(
            title: "Terms of Service",
            icon: "doc.text.fill",
            url: URL(string: "https://mothersound.dev")!
        )
    ]

    // Add theme property
    private let theme: Theme = DefaultTheme()

    var body: some View {
        NavigationSplitView {
            Form {
                Section("General") {
                    Label("Appearance", systemImage: "paintbrush.fill")
                        .foregroundStyle( theme.primaryText)
                    Label("Notifications", systemImage: "bell.fill")
                        .foregroundStyle(theme.primaryText)
                    Label("Location Services", systemImage: "location.fill")
                        .foregroundStyle(theme.primaryText)
                }
                Section("Management") {
                    NavigationLink(value: SettingsSection.categories) {
                        Label("Categories", systemImage: "tag.fill")
                            .foregroundStyle(theme.primaryText)
                    }
                    
                    NavigationLink(value: SettingsSection.stores) {
                        Label("Stores", systemImage: "storefront.fill")
                            .foregroundStyle(theme.primaryText, theme.accent)
                    }
                }
                
                Section("Community & Support") {
                    externalLinkButton(for: externalLinks["knowledgeBase"]!)
                    externalLinkButton(for: externalLinks["support"]!)
                    externalLinkButton(for: externalLinks["rateUs"]!)
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                            .foregroundStyle(theme.primaryText)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    externalLinkButton(for: externalLinks["roadmap"]!)
                    externalLinkButton(for: externalLinks["privacyPolicy"]!)
                    externalLinkButton(for: externalLinks["termsOfService"]!)
                }

            }
            .navigationTitle("Settings")
            .tint(theme.accent)
            .foregroundStyle(theme.primaryText)
            .scrollContentBackground(.hidden)
            .background(theme.primaryBackground)
            .navigationDestination(for: SettingsSection.self) { section in
                switch section {
                case .categories:
                    CategoriesView()
                case .stores:
                    StoresView()
                case .legal:
                    Text("Terms of Service")
                    Text("Privacy Policy")
                }
            }
            .sheet(isPresented: $showingSafariView) {
                if let url = selectedURL {
                    SafariView(url: url)
                }
            }
        } detail: {
            if let selectedSection = selectedSection {
                switch selectedSection {
                case .categories:
                    CategoriesView()
                case .stores:
                    StoresView()
                case .legal:
                    Text("Terms of Service")
                    Text("Privacy Policy")
                }
            } else {
                Text("Select a Section")
            }
        }
        .onChange(of: selectedSection) { oldValue, newValue in
            if let section = newValue {
                // Track when user navigates to a settings section
                TelemetryManager.shared.trackTabSelected(tab: "settings-\(section)")
            }
        }
    }
    
    // Helper function to create external link buttons
    private func externalLinkButton(for link: ExternalLink) -> some View {
        Button {
            // Add print statement for debugging
            print("Button tapped for: \(link.title) with URL: \(link.url.absoluteString)")
            selectedURL = link.url
            showingSafariView = true
        } label: {
            HStack {
                Label(link.title, systemImage: link.icon)
                    .foregroundStyle(theme.primaryText)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(theme.accent)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ExternalLink {
    let title: String
    let icon: String
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        safariViewController.delegate = context.coordinator
        safariViewController.preferredControlTintColor = .systemBlue
        
        // Print the URL to help with debugging
        print("Opening URL: \(url.absoluteString)")
        
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(_ parent: SafariView) {
            self.parent = parent
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            print("Safari view did complete initial load: \(didLoadSuccessfully)")
            if !didLoadSuccessfully {
                print("Failed to load URL: \(parent.url.absoluteString)")
            }
        }
    }
}

enum SettingsSection: Hashable {
    case categories
    case stores
    case legal
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\Category.name)
    ]) private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    
    var body: some View {
        List(selection: $selectedCategory) {
            ForEach(categories) { category in
                HStack {
                    Text(category.emoji ?? "⚪\u{fe0f}")
                    Text(category.name)
                    Spacer()
                    Text(category.taxRate, format: .percent)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .tag(category)
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .toolbar {
            Button {
                showingAddCategory = true
                // Track when user initiates adding a new category
                TelemetryManager.shared.trackTabSelected(tab: "add-category")
            } label: {
                Label("Add Category", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            NavigationStack {
                CategoryFormView(showSheet: $showingAddCategory)
            }
        }
        .sheet(item: $selectedCategory) { category in
            NavigationStack {
                CategoryFormView(category: category, showSheet: .constant(false))
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if !category.isDefault {
                modelContext.delete(category)
                // Track category deletion
                TelemetryManager.shared.trackCategoryDeleted()
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
    @State private var selectedStore: Store?
    
    var body: some View {
        List(selection: $selectedStore) {
            ForEach(stores) { store in
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        Text(store.name)
                        if !store.address.isEmpty {
                            Text(store.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tag(store)
            }
            .onDelete(perform: deleteStores)
        }
        .navigationTitle("Stores")
        .toolbar {
            Button {
                showingAddStore = true
                // Track when user initiates adding a new store
                TelemetryManager.shared.trackTabSelected(tab: "add-store")
            } label: {
                Label("Add Store", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddStore) {
            NavigationStack {
                StoreFormView(showSheet: $showingAddStore)
            }
        }
        .sheet(item: $selectedStore) { store in
            NavigationStack {
                StoreFormView(store: store, showSheet: .constant(false))
            }
        }
    }
    
    private func deleteStores(at offsets: IndexSet) {
        for index in offsets {
            let store = stores[index]
            modelContext.delete(store)
            // Track store deletion
            TelemetryManager.shared.trackStoreDeleted()
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
    @State private var selectedEmoji: String?
    @State private var showingEmojiPicker = false
    
    init(category: Category? = nil, showSheet: Binding<Bool>) {
        self.category = category
        self._showSheet = showSheet
        self._name = State(initialValue: category?.name ?? "")
        self._taxRate = State(initialValue: category?.taxRate ?? 0.0825)
        self._selectedEmoji = State(initialValue: category?.emoji)
    }
    
    private let emojis = ["🥕", "🥦", "🥬", "🥒", "🧄", "🧅", "🥔", "🍠", "🥐", "🥖", "🥨", "🥯", "🥞", "🧇", "🧀", "🥚", "🥓", "🥩", "🍗", "🍖", "🌭", "🍔", "🍟", "🥪", "🥙", "🧆", "🌮", "🌯", "🥗", "🥘", "🥫", "🍝", "🍜", "🍲", "🍛", "🍣", "🍱", "🥟", "🦪", "🍤", "🍙", "🍚", "🍘", "🍥", "🥠", "🥮", "🍢", "🍡", "🍧", "🍨", "🍦", "🥧", "🧁", "🍰", "🎂", "🍮", "🍭", "🍬", "🍫", "🍿", "🍩", "🍪", "🌰", "🥜", "🍯", "🥛", "🍼", "☕\u{fef}", "🫖", "🍵", "🧃", "🥤", "🧋", "🍶", "🍺", "🍻", "🥂", "🍷", "🥃", "🍸", "🍹", "🧊", "🥄", "🍴", "🍽", "🥢", "🧂"]
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    // Emoji Button (25% width)
                    Button(action: {
                        withAnimation {
                            showingEmojiPicker.toggle()
                        }
                    }) {
                        Text(selectedEmoji ?? "⚪\u{fe0f}")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.2)
                    
                    // Name Field (75% width)
                    TextField("Category Name", text: $name)
                        .frame(maxWidth: .infinity)
                }
                
                if showingEmojiPicker {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(rows: [GridItem(.flexible())], spacing: 12) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    showingEmojiPicker = false
                                }) {
                                    Text(emoji)
                                        .font(.title2)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            Section {
                HStack {
                    Text("Tax Rate")
                    Spacer()
                    Text(taxRate, format: .percent)
                }
                Stepper("", value: $taxRate, in: 0...1, step: 0.0025)
            }
        }
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
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
            existingCategory.emoji = selectedEmoji
            // Track category edit
            TelemetryManager.shared.trackCategoryEdited(name: name)
        } else {
            let newCategory = Category(name: name, taxRate: taxRate, emoji: selectedEmoji)
            modelContext.insert(newCategory)
            // Track category creation
            TelemetryManager.shared.trackCategoryCreated(name: name)
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
            // Track store edit
            TelemetryManager.shared.trackStoreEdited(name: name)
        } else {
            let newStore = Store(name: name, address: address)
            modelContext.insert(newStore)
            // Track store creation
            TelemetryManager.shared.trackStoreCreated(name: name)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Category.self, Store.self])
}
