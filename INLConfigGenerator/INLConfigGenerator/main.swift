import Foundation
import SwiftyJSON

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
}

func genObjCHeaderForConfig(_ config: NSDictionary, configName: String) -> String {
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

func genSwiftForConfig(_ config: NSDictionary, configName: String) -> String {
    return "\n//! Automatically generated file. Do not modify!\n\n"
        + "extension INLConfig {\n\n"
        + "\tstatic var \(configName.decapitalizedString): INLConfig {\n"
        + "\t\tstruct Static {\n"
        + "\t\t\tstatic let config: INLConfig = INLConfig(plist: \"\(configName)\")\n"
        + "\t\t}\n\t\treturn Static.config\n"
        + "\t}\n"
        + config.varGenReduce { key, value, type, name in
            "\n\tvar \(name): \(type) {\n"
                + "\t\treturn \(getterForValue(value))(\"\(key)\")!\n"
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
    
    print("Config name \(configName) language \(lang) root path \(rootPath)")
    
    if let path = pathForFile("\(configName).json", root: rootPath) {
        print("Parsing json")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
            
            let jsonObject = JSON(data: data)
            if jsonObject != JSON.null {
                print(jsonObject)
            } else {
                print("Empty JSON")
            }
        } catch let error {
            print(error.localizedDescription)
        }
    } else if let path = pathForFile("\(configName).plist", root: rootPath),
        let config = NSDictionary(contentsOfFile: "\(path)/\(configName).plist") {
        print("Reading plist")
        var fileExist = false
        
        let generateFileWithContents = { (contents: String, fileExtension: String) in
            
            let data = (contents as NSString).data(using: String.Encoding.utf8.rawValue)
            var filePath = pathForFile("\(configName).\(fileExtension)", root: rootPath) ?? path
            filePath += "/\(configName).\(fileExtension)"
            
            fileExist = fileExist || fileManager.fileExists(atPath: filePath)
            
            fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
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
    }
    print("Done")
}

generateConfig()

