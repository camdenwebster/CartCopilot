//
//  ShoppingTripUITests.swift
//  CartCopilotUITests
//
//  Created by Camden Webster on 2/25/25.
//

import XCTest

// Page Object for Shopping Trip List
class ShoppingTripListPage {
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // UI Elements
    var navigationTitle: XCUIElement { app.navigationBars["Shopping Trips"] }
    var addTripButton: XCUIElement { app.buttons["Add Trip"] }
    var emptyStateView: XCUIElement { app.staticTexts["No Shopping Trips"] }
    var emptyStateDescription: XCUIElement { app.staticTexts["Add a new shopping trip to get started"] }
    var tripsList: XCUIElement { app.collectionViews.firstMatch }
    var storeList: XCUIElement { app.collectionViews.firstMatch }
    var selectStoreButton: XCUIElement { app.collectionViews.buttons["Select a Store"] }
    var storeCell: (String) -> XCUIElement { { storeName in
        self.app.collectionViews.buttons[storeName]
    }}
    var tripCell: (String) -> XCUIElement { { storeName in
        self.app.cells.containing(.staticText, identifier: storeName).firstMatch
    }}
    
    // Text
    var selectAStoreStaticText: XCUIElement { app.navigationBars["Select a Store"].staticTexts.firstMatch }
    
    // Actions
    func tapAddTripButton() {
        addTripButton.tap()
    }
    
    func isDisplayingEmptyState() -> Bool {
        emptyStateView.exists && emptyStateDescription.exists
    }
    
    func isDisplayingTripsList() -> Bool {
        tripsList.exists
    }
    
    func selectStore(_ name: String) {
        selectStoreButton.tap()
        storeCell(name).tap()
    }

    func isTripDisplayed(forStore storeName: String) -> Bool {
        tripCell(storeName).waitForExistence(timeout: 2)
    }

}

class ShoppingTripUITests: XCTestCase {
    var app: XCUIApplication!
    var page: ShoppingTripListPage!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        page = ShoppingTripListPage(app: app)
        app.launch()
    }
    
    func testInitialEmptyState() throws {
        // When the app launches with no shopping trips
        // Then it should display the empty state
        XCTAssertTrue(page.navigationTitle.exists)
        XCTAssertTrue(page.isDisplayingEmptyState())
        XCTAssertTrue(page.addTripButton.exists)
    }
    
    func testAddTripButtonOpensSheet() throws {
        // When tapping the add trip button
        page.tapAddTripButton()
        
        // Then the new trip sheet should appear
        XCTAssertEqual(page.selectAStoreStaticText.label, "Select a Store")
    }

    func testCreateNewShoppingTrip() throws {
        // Given the app launches with no shopping trips
        XCTAssertTrue(page.isDisplayingEmptyState())

        // When creating a new trip
        page.tapAddTripButton()
        
//        let collectionViewsQuery = XCUIApplication().collectionViews
//        let selectAStoreAmazonButton = collectionViewsQuery/*@START_MENU_TOKEN@*/.buttons["Select a Store, Amazon"]/*[[".cells.buttons[\"Select a Store, Amazon\"]",".buttons[\"Select a Store, Amazon\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        selectAStoreAmazonButton.tap()
//        selectAStoreAmazonButton.tap()
//        collectionViewsQuery.buttons["Instacart"].tap()
                
        // And selecting Aldi as the store
        page.selectStore("Aldi")

        // Then the trips list should show the new trip
        XCTAssertTrue(page.isDisplayingTripsList())
        XCTAssertTrue(page.isTripDisplayed(forStore: "Aldi"))
    }

}

// End of class implementation
// End of file. No additional code.
