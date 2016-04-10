//
//  ios_path.mm
//  Dungeons
//
//  Created by Andrew Meckling on 2016-03-23.
//  Copyright © 2016 Andrew Meckling. All rights reserved.
//

#include "ios_path.h"
#import <Foundation/Foundation.h>

const char* ios_path( const char* filename, const char* ext )
{
    NSString * path = [[NSBundle mainBundle]
                       pathForResource: [NSString stringWithUTF8String: filename]
                       ofType:          [NSString stringWithUTF8String: ext]];
    
    return [path cStringUsingEncoding:1];
}

const char* ios_path( const char* name )
{
    NSArray<NSString *> * parts = [[NSString stringWithUTF8String: name] componentsSeparatedByString: @"."];
    
    NSString * path = [[NSBundle mainBundle]
                       pathForResource: [parts objectAtIndex: 0]
                       ofType:          parts.count == 2 ? [parts objectAtIndex: 1] : @""];
    
    return [path cStringUsingEncoding:1];
}

const char* ios_path( std::string path )
{
    return ios_path( path.c_str() );
}

