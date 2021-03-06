//
//  ViewController.swift
//  ConfigDemo
//
//  Created by Tomas Hakel on 31/01/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

import UIKit

/**
 * 1. Add something to Resources/ConfigurationSampleConfig.plist
 * 2. cmd+B -> A script will generate the configuration source code and open it in finder
 * 3. Drag the files to Xcode
 * 4. You can now use `INLConfig.sampleConfig().yourSetting()`
 */

class ViewController: UIViewController {

	@IBOutlet weak var titleLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()

		//! Download the latest version
//		INLConfig.anotherConfig.updateConfig {
//			self.test()
//		}
		test()
	}

	func test() {
		//! Test - Uncoment the SampleConfig.h import in the ConfigDemo-Bridging-Header.h
//		titleLabel.text = INLConfig.sampleConfig().sampleURL()
//		titleLabel.text = INLConfig.anotherConfig.magicString as String
//		titleLabel.text = "\(INLConfig.anotherConfig.magicArray ?? 0)"
	}

}

