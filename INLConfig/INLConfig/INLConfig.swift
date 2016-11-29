//
//  INLConfig.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 26/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import Foundation

extension INLConfig {
    
    public convenience init(JSON: String) {
        self.init()
        loadConfiguration(withJSON: JSON)
    }

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
                if (configURLStr as! String).hasSuffix("json") {
                    self.loadConfiguration(withJSON: self.configName)
                } else {
                    self.loadConfiguration(withPlist: self.configName)
                }
                
				if let completion = completion {
					DispatchQueue.main.async {
						completion()
					}
				}
			}
		}
	}
    
    func convertJSON(_ json:Any) -> NSDictionary {
        let result = NSMutableDictionary()
        for (key, value) in json as! [String: Any] {
            if let dict = value as? [String: Any] {
                result.setValue(dict, forKey: key)
            } else if let array = value as? [String] {
                result.setValue(array, forKey: key)
            } else {
                result.setValue(value, forKey: key)
            }
        }
        
        return result
    }
    
    func loadConfiguration(withJSON: String) {
        do {
            let path = Bundle.main.path(forResource: withJSON, ofType: "json")
            print("\(path)")
            let data = try Data(contentsOf: URL(fileURLWithPath: path!), options: .alwaysMapped)
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if (json != nil) {
                self.configName = withJSON
                self.config = convertJSON(json!) as! [AnyHashable : Any]
            }
        } catch {
            // noop
            print("Error info: \(error)")
        }
    }
}
