//
//  InAppPurchaseManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/7/23.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import StoreKit
import BaseFramework

protocol InAppPurchaseUIDelegate: class {
    func purchasing()
    func deferred()
    func failed(with error: Error?)
    func purchased()
    func restored()
}

let ConsoleStateKey = "iap_console_enabled"

//enum ConsoleState: Int64 {
//    case disabled = 0
//    case enabled = 2
//}
//
//enum PurchaseState: Int64 {
//    case notPurchased
//    case purchased
//}

enum ReceiptType: Int64 {
    case notExist = 0
    case normal = 1
    case sandbox = 2
    case simulator = 3
}

class InAppPurchaseManager: NSObject {
    static let `default` = InAppPurchaseManager()

    var receiptRequestTime = 0
    weak var uiDelegate: InAppPurchaseUIDelegate?
    let iCloudStorage = NSUbiquitousKeyValueStore.default
    let defaults = UserDefaults(suiteName: ContainerIdentifier)

    var consolePurchased: Bool = false
    var receiptType: ReceiptType = .notExist

    override init() {
        super.init()
        verifyReceipt()
        if defaults?.bool(forKey: "pref_console") ?? false {
            if !self.consolePurchased {
                defaults?.set(false, forKey: "pref_console")
                defaults?.synchronize()
            }
        }
    }

    func getReceiptType() -> ReceiptType {
        guard let receiptPath = Bundle.main.appStoreReceiptURL?.path else {
            return .notExist
        }
        if !FileManager.default.fileExists(atPath: receiptPath) {
            return .notExist
        }
        if receiptPath.contains("sandboxReceipt") {
            return .sandbox
        }
        if receiptPath.contains("CoreSimulator") {
            return .simulator
        }
        return .normal
    }

    func requestReceipt() {
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }

    func verifyReceipt() {
        self.receiptType = getReceiptType()
        guard let receipt = RMAppReceipt.bundle() else {
            receiptType = .notExist
            consolePurchased = false
            return
        }
        if !receipt.verifyReceiptHash() {
            receiptType = .notExist
            consolePurchased = false
        }
        if receipt.contains(inAppPurchaseOfProductIdentifier: "com.hubertzhang.iitcmobile.console") {
            consolePurchased = true
        }
    }
}

extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                self.uiDelegate?.purchasing()
                break
            case .deferred:
                self.uiDelegate?.deferred()
                break
            case .failed:
                self.uiDelegate?.failed(with: transaction.error)
                queue.finishTransaction(transaction)
                break
            case .purchased:
                if transaction.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    defer {
                        self.verifyReceipt()
                    }
                }
                self.uiDelegate?.purchased()
                queue.finishTransaction(transaction)
                break
            case .restored:
                if transaction.original!.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    defer {
                        self.verifyReceipt()
                    }
                }
                self.uiDelegate?.restored()
                queue.finishTransaction(transaction)
                break
            }
        }
    }
}

extension InAppPurchaseManager: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        self.verifyReceipt()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(request, error)
    }
}
