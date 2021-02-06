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

import TPInAppReceipt

protocol InAppPurchaseUIDelegate: class {
    func purchasing()
    func deferred()
    func failed(with error: Error?)
    func purchased()
    func restored()
}

let ConsoleStateKey = "iap_console_enabled"

// enum ConsoleState: Int64 {
//    case disabled = 0
//    case enabled = 2
// }
//
// enum PurchaseState: Int64 {
//    case notPurchased
//    case purchased
// }

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
    let defaults = sharedUserDefaults

    var consolePurchased: Bool = false
    var receiptType: ReceiptType = .notExist

    override init() {
        super.init()
        verifyReceipt()
        if defaults.bool(forKey: "pref_console") {
            if !self.consolePurchased {
                defaults.set(false, forKey: "pref_console")
                defaults.synchronize()
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
        do {
            let receipt = try InAppReceipt.localReceipt()
            try receipt.verify()
            if receipt.containsPurchase(ofProductIdentifier: "com.hubertzhang.iitcmobile.console") {
                consolePurchased = true
            }
        } catch {
            receiptType = .notExist
            consolePurchased = false
        }
    }
}

extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        var needVerifyReceipt: Bool = false
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                self.uiDelegate?.purchasing()
            case .deferred:
                self.uiDelegate?.deferred()
            case .failed:
                self.uiDelegate?.failed(with: transaction.error)
                queue.finishTransaction(transaction)
            case .purchased:
                if transaction.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    needVerifyReceipt = true
                }
                self.uiDelegate?.purchased()
                queue.finishTransaction(transaction)
            case .restored:
                if transaction.original?.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    needVerifyReceipt = true
                }
                self.uiDelegate?.restored()
                queue.finishTransaction(transaction)
            @unknown default:
                fatalError()
            }
        }
        if needVerifyReceipt {
            verifyReceipt()
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
