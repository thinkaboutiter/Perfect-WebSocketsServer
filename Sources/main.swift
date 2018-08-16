//
//  UploadHandler.swift
//  Upload Enumerator
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

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

// Create HTTP server
let server = HTTPServer()

// Set the server's webroot
server.documentRoot = "./webroot"
server.serverAddress = "127.0.0.1"

// Add our routes and such
let routes = makeRoutes()
server.addRoutes(routes)

// Listen on port 8181
server.serverPort = 8181

do {
    // Launch the HTTP server on port 8181
    server.setResponseFilters([(try HTTPFilter.contentCompression(data: [:]), .high)])
    try server.start()
}
catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
