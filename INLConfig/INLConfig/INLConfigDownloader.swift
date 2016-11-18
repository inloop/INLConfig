//
//  INLConfigDownloader.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 26/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import Foundation

class INLConfigDownloader {
	let session: URLSession

	init() {
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.timeoutIntervalForResource = 20
		sessionConfiguration.httpMaximumConnectionsPerHost = 3
		sessionConfiguration.requestCachePolicy = .useProtocolCachePolicy;

		session = URLSession(configuration: sessionConfiguration)
	}

	func get(_ url: URL, completion:((String?)->())?) {
		let task = session.dataTask(with: url, completionHandler: { data, response, error in
			guard error == nil, let data = data else {
				completion?(nil)
				return
			}
			completion?(String(data: data, encoding: String.Encoding.utf8))

		}) 
		task.resume()
	}
}
