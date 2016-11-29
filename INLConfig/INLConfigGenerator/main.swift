import Foundation

enum Lang {
    case objC, swift
}

extension NSDictionary {
    
    func varGenReduce(_ reduceBlock:(_ key: String, _ value: AnyObject, _ type: String, _ name: String) -> String) -> String {
        var code = ""
        for (key, value) in self {
            if String(describing: key) == "INLMeta" {
                continue
            }
            let type = typeForValue(value as AnyObject)
            let name = String(describing: key).decapitalizedString
            
            code += reduceBlock(String(describing: key), value as AnyObject, type, name)
        }
        return code
    }
    
    func varSwiftGenReduce(_ reduceBlock:(_ key: String, _ value: AnyObject, _ type: String, _ name: String) -> String) -> String {
        var code = ""
        for (key, value) in self {
            if String(describing: key) == "INLMeta" {
                continue
            }
            let type = swiftTypeForValue(value as AnyObject)
            let name = String(describing: key).decapitalizedString
            
            code += reduceBlock(String(describing: key), value as AnyObject, type, name)
        }
        return code
    }
}

func genObjCHeaderForConfig(_ config: NSDictionary, configName: String) -> String {
    return "\n#import <INLConfig/INLConfig.h>\n\n"
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

func genObjCImplementationForConfig(_ config: NSDictionary, configName: String) -> String {
    return "\n#import \"\(configName).h\"\n\n"
        + "//! Automatically generated file. Do not modify!\n\n"
        + "@implementation INLConfig (\(configName))\n\n"
        + "+(INLConfig *)\(configName.decapitalizedString) {\n\tinl_loadConfig(@\"\(configName)\")\n}\n\n"
        + config.varGenReduce { key, value, type, name in
            "-(\(type) *)\(name) {\n"
                + "\treturn [self \(getterForValue(value)):@\"\(key)\"];\n"
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

func genSwiftForConfig(_ config: NSDictionary, configName: String, isJson: Bool) -> String {
    var result = "\n//! Automatically generated file. Do not modify!\n\n"
        + "extension INLConfig {\n\n"
        + "\tstatic var \(configName.decapitalizedString): INLConfig {\n"
        + "\t\tstruct Static {\n"
    if isJson {
        result += "\t\t\tstatic let config: INLConfig = INLConfig(JSON: \"\(configName)\")\n"
    } else {
        result += "\t\t\tstatic let config: INLConfig = INLConfig(plist: \"\(configName)\")\n"
    }
    result += "\t\t}\n\t\treturn Static.config\n"
        + "\t}\n"
        + config.varSwiftGenReduce { key, value, type, name in
            "\n\tvar \(name): \(type) {\n"
                + "\t\treturn \(getterSwiftForValue(value))\"\(key)\")!\(getterSwiftSuffixForValue(value))\n"
                + "\t}\n"
        }
        + "\n\t// Convenience"
        + config.varSwiftGenReduce { key, value, type, name in
            "\n\tstatic var \(name): \(type) {\n"
                + "\t\treturn \(configName.decapitalizedString).\(name)\n"
                + "\t}\n"
        }
        + "}"
    return result
}

func pathForFile(_ file: String, root: String) -> String? {
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: "\(root)/\(file)") {
        return root
    }
    if let enumerator = fileManager.enumerator(atPath: root) {
        for subDir in enumerator {
            if (subDir as AnyObject).hasSuffix(file) {
                return (root as NSString).appendingPathComponent((subDir as AnyObject).deletingLastPathComponent)
            }
        }
    }
    return nil
}

extension String {
    var decapitalizedString: String {
        return String(characters.prefix(1)).lowercased() + String(characters.dropFirst())
    }
    func trim() -> String {
        return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

func typeForValue(_ value: AnyObject) -> String {
    if value is String { return "NSString" }
    if value is NSNumber { return "NSNumber" }
    if value is NSArray { return "NSArray" }
    if value is NSDictionary { return "NSDictionary" }
    if value is Data { return "NSData" }
    assert(false, "Invalid type \(value)")
    return "Any"
}

func getterForValue(_ value: AnyObject) -> String {
    if value is String { return "stringForKey" }
    if value is NSNumber { return "numberForKey" }
    if value is NSArray { return "arrayForKey" }
    if value is NSDictionary { return "dictionaryForKey" }
    if value is Data { return "dataForKey" }
    assert(false, "Invalid type \(value)")
    return "Any"
}

func swiftTypeForValue(_ value: AnyObject) -> String {
    if value is String { return "String" }
    if value is NSNumber { return "NSNumber" }
    if value is NSArray { return "Array<String>" }
    if value is NSDictionary { return "NSDictionary" }
    if value is Data { return "Data" }
    assert(false, "Invalid type \(value)")
    return "Any"
}

func getterSwiftForValue(_ value: AnyObject) -> String {
    if value is String { return "string(forKey: " }
    if value is NSNumber { return "number(forKey: " }
    if value is NSArray { return "array(forKey: " }
    if value is NSDictionary { return "dictionary(forKey: " }
    if value is Data { return "data(forKey: " }
    assert(false, "Invalid type \(value)")
    return ""
}

func getterSwiftSuffixForValue(_ value: AnyObject) -> String {
    if value is String { return " as String" }
    if value is NSNumber { return " as NSNumber" }
    if value is NSArray { return " as! Array<String>" }
    if value is NSDictionary { return " as NSDictionary" }
    if value is Data { return "" }
    assert(false, "Invalid type \(value)")
    return ""
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

func generateConfig() {
    
    // Get args
    var configName = "SampleConfig"
    var lang: Lang = .swift
    let fileManager = FileManager.default
    var rootPath = fileManager.currentDirectoryPath
    
    if 1 < CommandLine.arguments.count {
        configName = CommandLine.arguments[1]
    }
    
    if 2 < CommandLine.arguments.count {
        if	CommandLine.arguments[2] == "--swift" {
            lang = .swift
        }
        else if CommandLine.arguments[2] == "--objC" {
            lang = .objC
        }
    }
    
    if 3 < CommandLine.arguments.count {
        rootPath = CommandLine.arguments[3]
    }
    
    var config: NSDictionary!
    var dir: String!
    var isJson: Bool!
    
    print("Config name \(configName) language \(lang) root path \(rootPath)")
    
    if let path = pathForFile("\(configName).json", root: rootPath) {
        print("Parsing json")
        isJson = true
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: "\(path)/\(configName).json"), options: .alwaysMapped)
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            dir = path
            config = convertJSON(json ?? {
                print("Could not parse: \(json)")
                return
            })
        } catch let error {
            print(error.localizedDescription)
            return
        }
    } else if let path = pathForFile("\(configName).plist", root: rootPath) {
        isJson = false
        print("Reading plist")
        dir = path
        config = NSDictionary(contentsOfFile: "\(path)/\(configName).plist")!
    } else {
        print("No input file found")
        return
    }
    
    var fileExist = false
    
    let generateFileWithContents = { (contents: String, fileExtension: String) in
        
        let data = (contents as NSString).data(using: String.Encoding.utf8.rawValue)
        var filePath: String = pathForFile("\(configName).\(fileExtension)", root: rootPath) ?? dir
        filePath += "/\(configName).\(fileExtension)"
        
        fileExist = fileExist || fileManager.fileExists(atPath: filePath)
        print("Creating \(filePath)")
        fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    
    switch lang {
    case .objC:
        if isJson == true {
            print("JSON source is not supported for Obj-C")
            return
        }
        let hFile = genObjCHeaderForConfig(config, configName: configName)
        generateFileWithContents(hFile, "h")
        
        let mFile = genObjCImplementationForConfig(config, configName: configName)
        generateFileWithContents(mFile, "m")
        
    case .swift:
        let swiftFile = genSwiftForConfig(config, configName:configName, isJson: isJson)
        generateFileWithContents(swiftFile, "swift")
    }
    
    
    
    // Open finder if a new file was added so you can drag it to Xcode
    if !fileExist {
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [dir]
        task.launch()
    }
    
    
    print("Done")
}

generateConfig()
