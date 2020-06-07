//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import Foundation
import PerfectHTTP
import PerfectHTTPServer

struct BodyError: Encodable {
    let code: String
    let message: String
}

struct BodyErrors: Encodable {
    let errors: [BodyError]
}

struct Product: Codable {
    let id: String = UUID().uuidString
    let name: String
    let price: String
}

func validateProduct(_ product: Product) -> BodyError? {
    if Float(product.price) != nil {
        return nil
    }
    return BodyError(code: "001", message: "Invalid price")
}

var products = [Product]()

func createProduct(request: HTTPRequest, response: HTTPResponse) {
    let decoder = JSONDecoder()
    
    guard let body = request.postBodyString,
        !body.isEmpty,
        let bodyData = body.data(using: .utf8),
        let product = try? decoder.decode(Product.self, from: bodyData) else {
            
        response.status = .badRequest
        response.completed()
        return
    }
    
    let validationError = validateProduct(product)
    guard validationError == nil else {
        response.status = .custom(code: 422, message: "Unprocessable entity")
        let errors = BodyErrors(errors: [validationError!])
        try! response.setBody(json: errors)
        response.completed()
        return
    }
    
    response.setHeader(.contentType, value: "application/json")
    response.status = .created
    try! response.setBody(json: product)
    sleep(2)
    print("created product \(product)")
    response.completed()
}

// An example request handler.
// This 'handler' function can be referenced directly in the configuration below.
func handler(request: HTTPRequest, response: HTTPResponse) {
    // Respond with a simple message.
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
    // Ensure that response.completed() is called when your processing is done.
    response.completed()
}

// Configure one server which:
//	* Serves the hello world message at <host>:<port>/
//	* Serves static files out of the "./webroot"
//		directory (which must be located in the current working directory).
//	* Performs content compression on outgoing data when appropriate.
var routes = Routes()
routes.add(method: .post, uri: "/product", handler: createProduct)
routes.add(method: .get, uri: "/**",
		   handler: StaticFileHandler(documentRoot: "./webroot", allowResponseFilters: true).handleRequest)
try HTTPServer.launch(name: "localhost",
					  port: 8181,
					  routes: routes,
					  responseFilters: [
						(PerfectHTTPServer.HTTPFilter.contentCompression(data: [:]), HTTPFilterPriority.high)])

