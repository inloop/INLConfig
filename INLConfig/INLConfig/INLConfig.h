//
//  INLConfig.h
//  INLConfig
//
//  Created by Tomas Hakel on 12/02/2016.
//  Copyright © 2016 Inloop. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for INLConfig.
FOUNDATION_EXPORT double INLConfigVersionNumber;

//! Project version string for INLConfig.
FOUNDATION_EXPORT const unsigned char INLConfigVersionString[];


@interface INLConfig : NSObject

@property (strong, nonatomic) NSDictionary * _Nonnull config;
@property (strong, nonatomic) NSString * _Nonnull configName;

-(instancetype _Nonnull)initWithPlist:(NSString * _Nonnull)plistName;
-(void)loadConfigurationWithPlist:(NSString * _Nonnull)plistName;

-(NSString * _Nullable)stringForKey:(NSString * _Nonnull)key;
-(NSNumber * _Nullable)numberForKey:(NSString * _Nonnull)key;
-(NSData * _Nullable)dataForKey:(NSString * _Nonnull)key;
-(NSArray * _Nullable)arrayForKey:(NSString * _Nonnull)key;
-(NSDictionary * _Nullable)dictionaryForKey:(NSString * _Nonnull)key;

-(NSString * _Nonnull)pathForConfig:(NSString * _Nonnull)filename;

@end

#define inl_loadConfig(plistName)\
	static INLConfig * config = nil;\
	static dispatch_once_t onceToken;\
	dispatch_once(&onceToken, ^{\
		config = [[INLConfig alloc] init];\
		[config loadConfigurationWithPlist:plistName];\
	});\
	return config;

