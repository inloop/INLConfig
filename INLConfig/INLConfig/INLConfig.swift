//
//  INLConfig.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 26/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import Foundation

extension INLConfig {

	public func updateConfig(_ completion: (()->())?) {
		guard let meta = config["INLMeta"] as? NSDictionary,
			  let versionURLStr = meta["version"],
			  let versionURL = URL(string: versionURLStr as! String)
		else {
			downloadConfig(completion)
			return
		}

		let localVersion = UserDefaults.standard.string(forKey: "inlconfig.\(configName).version")
		INLConfigDownloader().get(versionURL) { version in
			if let version = version, version != localVersion {
				self.downloadConfig(completion)
				UserDefaults.standard.set(version, forKey: "inlconfig.\(self.configName).version")
			}
		}
	}

	func downloadConfig(_ completion: (()->())?) {
		guard let meta = config["INLMeta"] as? NSDictionary,
			  let configURLStr = meta["config"],
			  let configURL = URL(string: configURLStr as! String)
		else {
			return
		}

		INLConfigDownloader().get(configURL) { configuration in
			if let configuration = configuration {
				FileManager.default.createFile(atPath: self.path(forConfig: self.configName), contents: configuration.data(using: String.Encoding.utf8), attributes: nil)
				self.loadConfiguration(withPlist: self.configName)
				if let completion = completion {
					DispatchQueue.main.async {
						completion()
					}
				}
			}
		}
	}
}
