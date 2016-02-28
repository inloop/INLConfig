#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

enum Lang {
	case objC, swift
}

extension NSDictionary {

	func varGenReduce(reduceBlock:(key: String, value: AnyObject, type: String, name: String) -> String) -> String {
		var code = ""
		for (key, value) in self {
			if String(key) == "INLMeta" {
				continue
			}
			let type = typeForValue(value)
			let name = String(key).decapitalizedString

			code += reduceBlock(key: String(key), value: value, type: type, name: name)
		}
		return code
	}
}

func genObjCHeaderForConfig(config: NSDictionary, configName: String) -> String {
	return "\n#import \"INLConfig.h\"\n\n"
		+ "//! Automatically generated file. Do not modify! \n\n"
		+ "@interface INLConfig (\(configName))\n\n"
		+ "+(INLConfig *)\(configName.decapitalizedString);\n"
		+ config.varGenReduce { key, value, type, name in
			"-(\(type) *)\(name);\n"
		}
		+ "\n// Convenience\n"
		+ config.varGenReduce { key, value, type, name in
			"+(\(type) *)\(name);\n"
		}
		+ "\n@end"
}

func genObjCImplementationForConfig(config: NSDictionary, configName: String) -> String {
	return "\n#import \"\(configName).h\"\n\n"
		+ "//! Automatically generated file. Do not modify!\n\n"
		+ "@implementation INLConfig (\(configName))\n\n"
		+ "+(INLConfig *)\(configName.decapitalizedString) {\n\tinl_loadConfig(@\"\(configName)\")\n}\n\n"
		+ config.varGenReduce { key, value, type, name in
			"-(\(type) *)\(name) {\n"
				+ "\treturn [self \(getterForValue(value)):@\"\(String(key))\"];\n"
				+ "}\n\n"
		}
		+ "// Convenience\n"
		+ config.varGenReduce { key, value, type, name in
			"+(\(type) *)\(name) {\n"
				+ "\treturn [[self \(configName.decapitalizedString)] \(name)];\n"
				+ "}\n\n"
		}
		+ "@end"
}

func genSwiftForConfig(config: NSDictionary, configName: String) -> String {
	return "\n//! Automatically generated file. Do not modify!\n\n"
		+ "extension INLConfig {\n\n"
		+ "\tstatic var \(configName.decapitalizedString): INLConfig {\n"
		+ "\t\tstruct Static {\n"
		+ "\t\t\tstatic let config: INLConfig = INLConfig(plist: \"\(configName)\")\n"
		+ "\t\t}\n\t\treturn Static.config\n"
		+ "\t}\n"
		+ config.varGenReduce { key, value, type, name in
			"\n\tvar \(name): \(type) {\n"
				+ "\t\treturn \(getterForValue(value))(\"\(String(key))\")!\n"
				+ "\t}\n"
		}
		+ "\n\t// Convenience"
		+ config.varGenReduce { key, value, type, name in
			"\n\tstatic var \(name): \(type) {\n"
				+ "\t\treturn \(configName.decapitalizedString).\(name)\n"
				+ "\t}\n"
		}
		+ "}"
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
	var lang: Lang = .swift
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
	let task = NSTask()
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
			let task = NSTask()
			task.launchPath = "/usr/bin/open"
			task.arguments = [path]
			task.launch()
		}
	}
}

generateConfig()

