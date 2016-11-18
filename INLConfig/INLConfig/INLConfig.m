//
//  ConfigService.m
//
//  Created by Tomas Hakel on 28/01/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

#import "INLConfig.h"

#define safeExtract(type, key) [self.config[key] isKindOfClass:[type class]] ? self.config[key] : nil;

@implementation INLConfig

-(instancetype)initWithPlist:(NSString *)plistName {
    if (self = [super init]) {
        [self loadConfigurationWithPlist:plistName];
    }
    return self;
}

-(instancetype)initWithJSON:(NSString *)jsonName {
    if (self = [super init]) {
        [self loadConfigurationWithJSON:jsonName];
    }
    return self;
}

-(void)loadConfigurationWithPlist:(NSString *)plistName {
    
    NSString * plistPath = [self pathForConfig:plistName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    }
    
    if (plistPath) {
        self.config = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        self.configName = plistName;
    }
}
    
-(void)loadConfigurationWithJSON:(NSString *)jsonName {
    
    NSString * plistPath = [self pathForConfig:jsonName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:jsonName]) {
        plistPath = [[NSBundle mainBundle] pathForResource:jsonName ofType:@"json"];
    }
    
    if (plistPath) {
        self.config = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        self.configName = jsonName;
    }
}

-(NSString *)pathForConfig:(NSString *)filename {
	return [[self storageDirectory] stringByAppendingPathComponent:filename];
}

-(NSString *)storageDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

-(NSString *)stringForKey:(NSString *)key {
	return safeExtract(NSString, key)
}

-(NSNumber *)numberForKey:(NSString *)key {
	return safeExtract(NSNumber, key);
}

-(NSData *)dataForKey:(NSString *)key {
	return safeExtract(NSData, key);
}

-(NSArray *)arrayForKey:(NSString *)key {
	return safeExtract(NSArray, key);
}

-(NSDictionary *)dictionaryForKey:(NSString *)key {
	return safeExtract(NSDictionary, key);
}

@end
