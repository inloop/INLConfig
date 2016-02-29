//
//  INLConfig.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 26/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import Foundation

extension INLConfig {

	func updateConfig(completion: (()->())?) {
		guard let meta = config["INLMeta"],
			  let versionURLStr = meta["version"] as? String,
			  let versionURL = NSURL(string: versionURLStr)
		else {
			downloadConfig(completion)
			return
		}

		let localVersion = NSUserDefaults.standardUserDefaults().stringForKey("inlconfig.\(configName).version")
		INLConfigDownloader().get(versionURL) { version in
			if let version = version where version != localVersion {
				self.downloadConfig(completion)
				NSUserDefaults.standardUserDefaults().setObject(version, forKey: "inlconfig.\(self.configName).version")
			}
		}
	}

	func downloadConfig(completion: (()->())?) {
		guard let meta = config["INLMeta"],
			  let configURLStr = meta["config"] as? String,
			  let configURL = NSURL(string: configURLStr)
		else {
			return
		}

		INLConfigDownloader().get(configURL) { configuration in
			if let configuration = configuration {
				NSFileManager.defaultManager().createFileAtPath(self.pathForConfig(self.configName), contents: configuration.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
				self.loadConfigurationWithPlist(self.configName)
				if let completion = completion {
					dispatch_async(dispatch_get_main_queue()) {
						completion()
					}
				}
			}
		}
	}
}
