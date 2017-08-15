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
    
    @IBOutlet weak var purchaseButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
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
    
    @IBAction func doneButtonClicked(_ sender: Any) {
        InAppPurchaseManager.default.uiDelegate = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func restoreButtonClicked(_ sender: Any) {
        SKPaymentQueue.default().restoreCompletedTransactions()
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
                self.titleLabel.text = product.localizedTitle
                let priceFormatter = NumberFormatter()
                priceFormatter.numberStyle = .currency
                priceFormatter.locale = product.priceLocale
                self.priceLabel.text = priceFormatter.string(from: product.price)
                #if DEBUG
                    self.descriptionTextView.text = String.init(format: "ID:%@\nTitle:%@\nDescription:%@\nPrice:%@\n", product.productIdentifier, product.localizedTitle, product.localizedDescription, product.price.description(withLocale: product.priceLocale))
                #else
                    self.descriptionTextView.text = product.localizedDescription
                #endif
                self.purchaseButton.isEnabled = true
                self.products.append(product)
            }
            
        } else {
            print(response.invalidProductIdentifiers)
            print("No product.")
        }
    }
}

extension ConsolePurchaseViewController: InAppPurchaseUIDelegate {
    func purchasing() {
        if hud == nil {
            hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            hud?.removeFromSuperViewOnHide = false
            hud?.label.text = "Purchasing"
        } else {
            hud?.show(animated: true)
        }
    }
    
    func deferred() {
        if hud == nil {
            
        } else {
            hud?.label.text = "Deferred"
            hud?.hide(animated: true, afterDelay: 5)
        }
    }
    
    func failed(with error: Error?) {
        if hud == nil {
            
        } else {
            hud?.hide(animated: true)
        }
        let alert = UIAlertController(title: "Purchase Failed", message: error?.localizedDescription ?? "Unknown Error", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func purchased() {
        if hud == nil {
            
        } else {
            hud?.hide(animated: true)
            let alert = UIAlertController(title: "Console Purchased!", message: "Please restart IITC-iOS to enable Debug Console! Debug Console can be turned off in Settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func restored() {
        if hud == nil {
            
        } else {
            hud?.hide(animated: true)
            let alert = UIAlertController(title: "Purchase Restored", message: "Please restart IITC-iOS to enable Debug Console! Debug Console can be turned off in Settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
