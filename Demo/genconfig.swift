#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

enum Lang {
	case objC, swift
}

func genObjCHeaderForConfig(config: NSDictionary, configName: String) -> String {
	var hFile = "\n#import \"INLConfig.h\"\n\n"
	hFile += "//! Automatically generated file. Do not modify! \n\n"
	hFile += "@interface INLConfig (\(configName))\n\n"
	hFile += "+(INLConfig *)\(configName.decapitalizedString);\n\n"

	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		hFile += "-(\(type) *)\(name);\n"
	}

	hFile += "\n// Convenience\n"
	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		hFile += "+(\(type) *)\(name);\n"
	}

	hFile += "\n@end"
	return hFile
}

func genObjCImplementationForConfig(config: NSDictionary, configName: String) -> String {
	var mFile = "\n#import \"\(configName).h\"\n\n"
	mFile += "//! Automatically generated file. Do not modify!\n\n"
	mFile += "@implementation INLConfig (\(configName))\n\n"
	mFile += "+(INLConfig *)\(configName.decapitalizedString) {\n\tinl_loadConfig(@\"\(configName)\")\n}\n\n"

	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		mFile += "-(\(type) *)\(name) {\n"
		mFile += "\treturn [self \(getterForValue(value)):@\"\(String(key))\"];\n"
		mFile += "}\n\n"
	}

	mFile += "// Convenience\n"
	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		mFile += "+(\(type) *)\(name) {\n"
		mFile += "\treturn [[self \(configName.decapitalizedString)]\(name)];\n"
		mFile += "}\n\n"
	}

	mFile += "@end"
	return mFile
}

func genSwiftForConfig(config: NSDictionary, configName: String) -> String {
	var swiftFile = "\n//! Automatically generated file. Do not modify!\n\n"
	swiftFile += "extension INLConfig {\n\n"
	swiftFile += "\tstatic var \(configName.decapitalizedString): INLConfig {\n"
	swiftFile += "\t\tstruct Static {\n"
	swiftFile += "\t\t\tstatic let config: INLConfig = INLConfig(plist: \"\(configName)\")\n"
	swiftFile += "\t\t}\n\t\treturn Static.config\n"
	swiftFile += "\t}\n"

	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		swiftFile += "\n\tvar \(name): \(type)? {\n"
		swiftFile += "\t\treturn \(getterForValue(value))(\"\(String(key))\")\n"
		swiftFile += "\t}\n"
	}

	swiftFile += "\n\t// Convenience"
	for (key, value) in config {
		let type = typeForValue(value)
		let name = String(key).decapitalizedString

		swiftFile += "\n\tstatic var \(name): \(type)? {\n"
		swiftFile += "\t\treturn \(configName.decapitalizedString).\(name)\n"
		swiftFile += "\t}\n"
	}
	swiftFile += "}"
	return swiftFile
}

func pathForFile(file: String, root: String) -> String? {
	print(root)
	let fileManager = NSFileManager.defaultManager()

	if fileManager.fileExistsAtPath("\(root)/\(file)") {
		return root
	}
	if let enumerator = fileManager.enumeratorAtPath(root) {
		for subDir in enumerator {
			if subDir.hasSuffix(file) {
				return (root as NSString).stringByAppendingPathComponent(subDir.stringByDeletingLastPathComponent)
			}
		}
	}
	return nil
}

extension String {
	var decapitalizedString: String {
		return String(characters.prefix(1)).lowercaseString + String(characters.dropFirst())
	}
	func trim() -> String {
		return stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
	}
}

func typeForValue(value: AnyObject) -> String {
	if value is String { return "NSString" }
	if value is NSNumber { return "NSNumber" }
	if value is NSArray { return "NSArray" }
	if value is NSDictionary { return "NSDictionary" }
	if value is NSData { return "NSData" }
	assert(false, "Invalid type \(value)")
}

func getterForValue(value: AnyObject) -> String {
	if value is String { return "stringForKey" }
	if value is NSNumber { return "numberForKey" }
	if value is NSArray { return "arrayForKey" }
	if value is NSDictionary { return "dictionaryForKey" }
	if value is NSData { return "dataForKey" }
	assert(false, "Invalid type \(value)")
}

func generateConfig() {

	// Get args
	var configName = "Config"
	var lang: Lang = .objC
	if 1 < Process.arguments.count {
		configName = Process.arguments[1]
	}
	if 2 < Process.arguments.count {
		if	Process.arguments[2] == "--swift" {
			lang = .swift
		}
		else if Process.arguments[2] == "--objC" {
			lang = .objC
		}
	}


	// Get path
	let task = NSTask();
	let pipe = NSPipe()
	task.standardOutput = pipe
	task.launchPath = "/bin/pwd"
	task.launch()


	// Generate files
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	if 	let rootPath = String(data: data, encoding: NSUTF8StringEncoding)?.trim(),
		let path = pathForFile("\(configName).plist", root: rootPath),
		let config = NSDictionary(contentsOfFile: "\(path)/\(configName).plist")
	{
		var fileExist = false
		let fileManager = NSFileManager.defaultManager()

		let generateFileWithContents = { (contents: String, fileExtension: String) in

			let data = (contents as NSString).dataUsingEncoding(NSUTF8StringEncoding)
			var filePath = pathForFile("\(configName).\(fileExtension)", root: rootPath) ?? path
			filePath += "/\(configName).\(fileExtension)"

			fileExist = fileExist || fileManager.fileExistsAtPath(filePath)

			fileManager.createFileAtPath(filePath, contents: data, attributes: nil)
		}

		switch lang {
		case .objC:
			let hFile = genObjCHeaderForConfig(config, configName: configName)
			generateFileWithContents(hFile, "h")

			let mFile = genObjCImplementationForConfig(config, configName: configName)
			generateFileWithContents(mFile, "m")

		case .swift:
			let swiftFile = genSwiftForConfig(config, configName:configName)
			generateFileWithContents(swiftFile, "swift")
		}


		// Open finder if a new file was added so you can drag it to Xcode
		if !fileExist {
			let task = NSTask();
			task.launchPath = "/usr/bin/open"
			task.arguments = [path]
			task.launch()
		}
	}
}

generateConfig()


