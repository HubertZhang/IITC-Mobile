//
//  InAppPurchaseManager.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/7/23.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import StoreKit

class InAppPurchaseManager: NSObject {
    static let `default` = InAppPurchaseManager()
    
    var uiDelegate: ConsolePurchaseViewController?
    
    override init() {
        super.init()
        #if DEBUG
            let request = SKReceiptRefreshRequest(receiptProperties: nil)
            request.delegate = self
            request.start()
        #else
            if arc4random_uniform(10) == 0 {
                let request = SKReceiptRefreshRequest(receiptProperties: nil)
                request.delegate = self
                request.start()
            }
        #endif
    }
    
    func verifyReciept() {
        let url = Bundle.main.appStoreReceiptURL
        if url != nil && FileManager.default.fileExists(atPath: url!.path) {
            if let receipt = NSData(contentsOf: url!) {
                UserDefaults.standard.set(true, forKey: "Verified")
            }
        } else {
            UserDefaults.standard.set(false, forKey: "Verified")
        }
    }
}

extension InAppPurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        self.uiDelegate?.paymentQueue(queue, updatedTransactions: transactions)
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                print("Purchasing...")
                break
            case .deferred:
                print("Deferred...")
                break
            case .failed:
                print("Failed!")
                break
            case .purchased:
                print("Purchased")
                if transaction.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    UserDefaults.standard.set(true, forKey: "Purchased")
                    UserDefaults.standard.set(transaction.transactionIdentifier, forKey: "TransactionID")
                    self.verifyReciept()
                }
                queue.finishTransaction(transaction)
                break
            case .restored:
                print("Restored")
                if transaction.original?.payment.productIdentifier == "com.hubertzhang.iitcmobile.console" {
                    UserDefaults.standard.set(true, forKey: "Purchased")
                    UserDefaults.standard.set(transaction.original?.transactionIdentifier, forKey: "TransactionID")
                    self.verifyReciept()
                }
                queue.finishTransaction(transaction)
                break
            }
        }
    }
}

extension InAppPurchaseManager: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(request, error)
    }
}

