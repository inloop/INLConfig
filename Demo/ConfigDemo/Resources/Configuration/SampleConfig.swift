
//! Automatically generated file. Do not modify!

extension INLConfig {

	static var sampleConfig: INLConfig {
		struct Static {
			static let config: INLConfig = INLConfig(plist: "SampleConfig")
		}
		return Static.config
	}

	var aDict: NSDictionary {
		return dictionaryForKey("ADict")!
	}

	var sampleNumber: NSNumber {
		return numberForKey("SampleNumber")!
	}

	var anArray: NSArray {
		return arrayForKey("AnArray")!
	}

	var sampleURL: NSString {
		return stringForKey("SampleURL")!
	}

	// Convenience
	static var aDict: NSDictionary {
		return sampleConfig.aDict
	}

	static var sampleNumber: NSNumber {
		return sampleConfig.sampleNumber
	}

	static var anArray: NSArray {
		return sampleConfig.anArray
	}

	static var sampleURL: NSString {
		return sampleConfig.sampleURL
	}
}