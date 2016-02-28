//
//  INLConfigDownloader.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 26/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import Foundation

class INLConfigDownloader {
	let session: NSURLSession

	init() {
		let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfiguration.timeoutIntervalForResource = 20
		sessionConfiguration.HTTPMaximumConnectionsPerHost = 3
		sessionConfiguration.requestCachePolicy = .UseProtocolCachePolicy;

		session = NSURLSession(configuration: sessionConfiguration)
	}

	func get(url: NSURL, completion:((String?)->())?) {
		let task = session.dataTaskWithURL(url) { data, response, error in
			guard error == nil, let data = data else {
				completion?(nil)
				return
			}
			completion?(String(data: data, encoding: NSUTF8StringEncoding))

		}
		task.resume()
	}
}
