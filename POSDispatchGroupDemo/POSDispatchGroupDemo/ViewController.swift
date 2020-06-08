//
//  ViewController.swift
//  POSDispatchGroupDemo
//
//  Created by Anurag Ajwani on 25/05/2020.
//  Copyright © 2020 Anurag Ajwani. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var isCreatingProducts: Bool = false {
        didSet {
            self.buttons.forEach({ $0.isHidden = self.isCreatingProducts })
            self.progressLabel.isHidden = !self.isCreatingProducts
        }
    }

    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBAction func createSingleProduct(_ sender: Any) {
        let alert = UIAlertController(title: "Create new product", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            // product name
            textField.placeholder = "name"
        })
        alert.addTextField(configurationHandler: { textField in
            // price
            textField.placeholder = "Prices"
            textField.keyboardType = .decimalPad
        })
        let alertAction = UIAlertAction(title: "Create", style: .default, handler: { _ in
            let productName = alert.textFields?[0].text
            let price = alert.textFields?[1].text
            
            if let productName = productName, !productName.isEmpty, let price = price, !price.isEmpty {
                let product = Product(name: productName, price: price)
                self.createProduct(product, onCompletion: { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.showNetworkError(error)
                        } else {
                            self.showProductsCreatedAlert()
                        }
                    }
                })
            } else {
                self.showProductInputErrorAlert()
            }
        })
        alert.addAction(alertAction)
        self.show(alert, sender: nil)
    }
    
    @IBAction func uploadProductsCSV(_ sender: Any) {
        let dispatchGroup = DispatchGroup()
        let products = self.getProductsFromCSV()
        products.forEach({ product in
            dispatchGroup.enter()
            self.createProduct(product, onCompletion: { _ in
                dispatchGroup.leave()
            })
        })
        dispatchGroup.notify(queue: .main, execute: { self.showProductsCreatedAlert() })
    }
    
    private func getProductsFromCSV() -> [Product] {
        let csvFileURL = Bundle.main.url(forResource: "products", withExtension: "csv")!
        let csvFileString = try! String(contentsOf: csvFileURL)
        let productsCSV = csvFileString.split(separator: "\n").map({ String($0) })
        return productsCSV.map { productCSV -> Product in
            let productElements = productCSV.split(separator: ",").map({ String($0) })
            let productName = productElements[0].trimmingCharacters(in: .whitespaces)
            let productPrice = productElements[1].trimmingCharacters(in: .whitespaces)
            return Product(name: productName, price: productPrice)
        }
    }
    
    private func createProduct(_ product: Product, onCompletion completionHandler: @escaping (Error?) -> ()) {
        var request = URLRequest(url: URL(string: "http://localhost:8181/product")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONEncoder().encode(product)
        let task = URLSession.shared.downloadTask(with: request, completionHandler: { (url, response, error) in
            completionHandler(error)
        })
        self.isCreatingProducts = true
        task.resume()
    }
    
    private func showProductInputErrorAlert() {
        let alert = UIAlertController(title: "Product creation error", message: "The product name or price is invalid. Please make sure all inputs are valid and not empty", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showNetworkError(_ error: Error) {
        let alert = UIAlertController(title: "Network error", message: "Check server is running", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showProductsCreatedAlert() {
        self.isCreatingProducts = false
        let alert = UIAlertController(title: "Success", message: "Product(s) were created successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

struct Product: Encodable {
    let name: String
    let price: String
}
