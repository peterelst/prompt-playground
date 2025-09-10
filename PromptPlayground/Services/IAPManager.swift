import Foundation
import StoreKit
import SwiftUI

@MainActor
class IAPManager: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var error: String?

    private let productIDs = ["support_developer_tip"]

    override init() {
        super.init()
        startListening()
    }

    deinit {
        stopListening()
    }

    func loadProducts() {
        Task {
            await fetchProducts()
        }
    }

    private func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: productIDs)
            self.products = products
        } catch {
            self.error = "Failed to load products: \(error.localizedDescription)"
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Successful purchase
                    await transaction.finish()
                    await updatePurchasedProducts()

                    // Show thank you message
                    showThankYouAlert()

                case .unverified:
                    self.error = "Purchase could not be verified"
                }

            case .pending:
                // Purchase is pending (e.g., parental approval required)
                break

            case .userCancelled:
                // User cancelled the purchase
                break

            @unknown default:
                break
            }
        } catch {
            self.error = "Purchase failed: \(error.localizedDescription)"
        }
    }

    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchasedProducts.insert(transaction.productID)
            case .unverified:
                break
            }
        }

        self.purchasedProducts = purchasedProducts
    }

    private func startListening() {
        Task {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                case .unverified:
                    break
                }
            }
        }
    }

    private func stopListening() {
        // StoreKit 2 handles this automatically
    }

    private func showThankYouAlert() {
        // This would trigger a thank you UI element
        // For now, we'll just clear any error
        error = nil
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    var supportProduct: Product? {
        products.first { $0.id == "support_developer_tip" }
    }

    var hasPurchasedSupport: Bool {
        purchasedProducts.contains("support_developer_tip")
    }
}
