# INLConfig

## 1. Overview

`INLConfig` is an iOS library for loading your configuration from a plist. Its goal is to have an easily maintainable configuration (by replacing things like global constants with a plist) without sacrificing productivity. After you add an item to the plist, you can start using it with autocomplete without doing any further configuration. This is achieved by a script that generates supporting code.

The library contains the `INLConfig` class that extracts your configuration from the plist and the `genconfig.swift` script that generates `INLConfig` categories/extensions for easy access to the items in the plist.

## 2. Setup

First, add a plist configuration file.

To enable code generation add a new Run script build phase. For each of your configuration plists run the genconfig.swift script with two parameters: 1. the name of the configuration file without the .plist extension, 2. the programming language that should be generated (--objC and --swift are supported)
```
./genconfig.swift SampleConfig --objC
./genconfig.swift AnotherConfig --swift
```

After you build the project (cmd+B) a finder window will open with the created configuration files. Drag them into Xcode.
You can even move them into a different directory as long as it’s a subdirectory of the project source directory. In this case the script will not create new files but update the existing ones.

_Note: Do not modify the code in the generated files because it will be overwritten when the script is run again_

You can now use the configuration in your code
```
// swift file, swift config
INLConfig.sampleConfig.sampleString
INLConfig.sampleNumber

// swift file, objC config
INLConfig.sampleConfig().sampleString()
INLConfig.sampleNumber()

// objC file
[[INLConfig sampleConfig] sampleString];
[INLConfig sampleNumber];
```
