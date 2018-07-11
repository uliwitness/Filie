//
//  FILDSStore.h
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString * const FILDSStoreIconLocationProperty;


@interface FILDSStore : NSObject

-(instancetype) initWithURL: (NSURL *)inURL;
-(NSDictionary<NSString *, id> *) propertiesForFile: (NSString *)fileName;
-(NSArray<NSString *> *) filenames;

@end
