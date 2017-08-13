//
//  InAppPurchaseManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/7/23.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import StoreKit

protocol InAppPurchaseUIDelegate {
    func purchasing()
    func deferred()
    func failed(with error: Error?)
    func purchased()
    func restored()
}

let ReceiptVerifiedKey = "receipt_verified"
let ConsoleStateKey = "console_state"
let ConsoleTransactionKey = "console_transaction_identifier"

enum ConsoleState: Int64 {
    case disabled = 0
    case purchased = 1
    case enabled = 2
}

class InAppPurchaseManager: NSObject {
    static let `default` = InAppPurchaseManager()
    
    var receiptRequestTime = 0
    var uiDelegate: InAppPurchaseUIDelegate?
    let iCloudStorage = NSUbiquitousKeyValueStore.default()
    
    override init() {
        super.init()
        verifyReciept()
    }
    
    func verifyReciept() {
        guard let receipt = RMAppReceipt.bundle() else {
            if receiptRequestTime > 5 {
                iCloudStorage.set(false, forKey: ReceiptVerifiedKey)
                iCloudStorage.synchronize()
                return
            }
            receiptRequestTime += 1
            let request = SKReceiptRefreshRequest(receiptProperties: nil)
            request.delegate = self
            request.start()
            return
        }
        
        if receipt.contains(inAppPurchaseOfProductIdentifier: "com.hubertzhang.iitcmobile.console") {
            iCloudStorage.set(ConsoleState.enabled.rawValue, forKey: ConsoleStateKey)
            iCloudStorage.synchronize()
        } else {
            iCloudStorage.set(ConsoleState.disabled.rawValue, forKey: ConsoleStateKey)
            iCloudStorage.synchronize()
        }
    }
}

extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                print("Purchasing...")
                self.uiDelegate?.purchasing()
                break
            case .deferred:
                print("Deferred...")
                self.uiDelegate?.deferred()
                break
            case .failed:
                print("Failed!")
                self.uiDelegate?.failed(with:transaction.error)
                queue.finishTransaction(transaction)
                break
            case .purchased:
                print("Purchased")
                if transaction.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    iCloudStorage.set(transaction.transactionIdentifier, forKey: ConsoleTransactionKey)
                    iCloudStorage.set(ConsoleState.purchased.rawValue, forKey: ConsoleStateKey)
                    iCloudStorage.synchronize()
                    self.verifyReciept()
                }
                self.uiDelegate?.purchased()
                queue.finishTransaction(transaction)
                break
            case .restored:
                print("Restored")
                if transaction.original!.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    iCloudStorage.set(transaction.original!.transactionIdentifier, forKey: ConsoleTransactionKey)
                    iCloudStorage.set(ConsoleState.purchased.rawValue, forKey: ConsoleStateKey)
                    iCloudStorage.synchronize()
                    self.verifyReciept()
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
        self.verifyReciept()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(request, error)
    }
}

