//
//  ConsolePurchaseViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2017/7/22.
//  Copyright © 2017年 IITC. All rights reserved.
//

import UIKit
import StoreKit
import MBProgressHUD

class ConsolePurchaseViewController: UIViewController {

    let productIds: [String] = ["com.hubertzhang.iitcmobile.console"]
    var products: [SKProduct] = [SKProduct]()
    var hud: MBProgressHUD?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        InAppPurchaseManager.default.uiDelegate = self
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set<String>(productIds))
            request.delegate = self
            request.start()
        }
        else {
            print("Cannot perform In App Purchases.")
        }
    }
    
    deinit {
        InAppPurchaseManager.default.uiDelegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func purchaseButtonClicked(_ sender: Any) {
        if SKPaymentQueue.canMakePayments() {
            if products.count > 0  {
                
                let payment = SKPayment(product: products[0])
                SKPaymentQueue.default().add(payment)
            }
            
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ConsolePurchaseViewController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                print("product: \(product)")
                self.label.text = String.init(format: "ID:%@\nTitle:%@\nDescription:%@\nPrice:%@\n", product.productIdentifier, product.localizedTitle, product.localizedDescription, product.price.description(withLocale: product.priceLocale))
                self.purchaseButton.isEnabled = true
                self.products.append(product)
            }
            
        } else {
            print(response.invalidProductIdentifiers)
            print("No product.")
        }
    }
}

extension ConsolePurchaseViewController: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            // Call the appropriate custom method for the transaction state.
            case .purchasing:
                if hud == nil {
                    hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                    hud?.label.text = "Purchasing"
                } else {
                    hud?.show(animated: true)
                }
                break;
            case .deferred:
                if hud == nil {
                    
                } else {
                    hud?.label.text = "Deferred"
                    hud?.hide(animated: true, afterDelay: 5)
                }
                //                [self showTransactionAsInProgress:transaction deferred:YES];
                break;
            case .failed:
                if hud == nil {
                    
                } else {
                    hud?.label.text = "Failed"
                    hud?.hide(animated: true, afterDelay: 5)
                }
                let alert = UIAlertController(title: "Purchase Failed", message: transaction.error?.localizedDescription ?? "Unknown Error", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                print("Failed!")
                //                [self failedTransaction:transaction];
                break;
            case .purchased:
                if hud == nil {
                    
                } else {
                    hud?.label.text = "Purchased"
                    hud?.hide(animated: true, afterDelay: 5)
                }
                break;
            case .restored:
                if hud == nil {
                    
                } else {
                    hud?.label.text = "Restored"
                    hud?.hide(animated: true, afterDelay: 5)
                }
                break;
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print(#function)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print(#function)
    }
}
