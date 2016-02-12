//
//  ConfigService.h
//
//  Created by Tomas Hakel on 28/01/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INLConfig : NSObject

-(instancetype _Nonnull)initWithPlist:(NSString * _Nonnull)plistName;
-(void)loadConfigurationWithPlist:(NSString * _Nonnull)plistName;

-(NSString * _Nullable)stringForKey:(NSString * _Nonnull)key;
-(NSNumber * _Nullable)numberForKey:(NSString * _Nonnull)key;
-(NSData * _Nullable)dataForKey:(NSString * _Nonnull)key;
-(NSArray * _Nullable)arrayForKey:(NSString * _Nonnull)key;
-(NSDictionary * _Nullable)dictionaryForKey:(NSString * _Nonnull)key;

@end

#define loadConfig(plistName)\
	static INLConfig * config = nil;\
	static dispatch_once_t onceToken;\
	dispatch_once(&onceToken, ^{\
		config = [[INLConfig alloc] init];\
		[config loadConfigurationWithPlist:plistName];\
	});\
	return config;
