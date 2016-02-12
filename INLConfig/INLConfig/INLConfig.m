//
//  ConfigService.m
//
//  Created by Tomas Hakel on 28/01/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

#import "INLConfig.h"

#define safeExtract(type, key) [self.config[key] isKindOfClass:[type class]] ? self.config[key] : nil;

@interface INLConfig ()
@property (strong, nonatomic) NSDictionary * config;
@end


@implementation INLConfig

-(instancetype)initWithPlist:(NSString *)plistName {
	if (self = [super init]) {
		[self loadConfigurationWithPlist:plistName];
	}
	return self;
}

-(void)loadConfigurationWithPlist:(NSString *)plistName {
	NSString * plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
	if (plistPath) {
		self.config = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	}
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
