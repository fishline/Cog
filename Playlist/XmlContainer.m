//
//  XmlContainer.m
//  Xml
//
//  Created by Christopher Snowhill on 10/9/13.
//  Copyright 2013 __NoWork, Inc__. All rights reserved.
//

#import "XmlContainer.h"

#import "PlaylistEntry.h"

#import "Logging.h"

@implementation XmlContainer

+ (NSURL *)urlForPath:(NSString *)path relativeTo:(NSString *)baseFilename
{
	NSRange protocolRange = [path rangeOfString:@"://"];
	if (protocolRange.location != NSNotFound) 
	{
		return [NSURL URLWithString:path];
	}

	NSMutableString *unixPath = [path mutableCopy];

	//Get the fragment
	NSString *fragment = @"";
	NSScanner *scanner = [NSScanner scannerWithString:unixPath];
	NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"#1234567890"];
	while (![scanner isAtEnd]) {
		NSString *possibleFragment;
		[scanner scanUpToString:@"#" intoString:nil];

		if ([scanner scanCharactersFromSet:characterSet intoString:&possibleFragment] && [scanner isAtEnd]) 
		{
			fragment = possibleFragment;
			[unixPath deleteCharactersInRange:NSMakeRange([scanner scanLocation] - [possibleFragment length], [possibleFragment length])];
			break;
		}
	}
	DLog(@"Fragment: %@", fragment);

	if (![unixPath hasPrefix:@"/"]) {
		//Only relative paths would have windows backslashes.
		[unixPath replaceOccurrencesOfString:@"\\" withString:@"/" options:0 range:NSMakeRange(0, [unixPath length])];
		
		NSString *basePath = [[[baseFilename stringByStandardizingPath] stringByDeletingLastPathComponent] stringByAppendingString:@"/"];

		[unixPath insertString:basePath atIndex:0];
	}
	
	//Append the fragment
	NSURL *url = [NSURL URLWithString:[[[NSURL fileURLWithPath:unixPath] absoluteString] stringByAppendingString: fragment]];
	return url;
}

+ (NSDictionary *)entriesForContainerURL:(NSURL *)url
{
	if (![url isFileURL]) 
		return [NSDictionary dictionary];

    NSError *nserr;
    
    NSString *error;
    
	NSString *filename = [url path];
	
    NSString * contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&nserr];
    
    NSData* plistData = [contents dataUsingEncoding:NSUTF8StringEncoding];
	
    NSPropertyListFormat format;
    id plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if(!plist){
        ALog(@"Error: %@",error);
        return nil;
    }
    
    BOOL isArray = [plist isKindOfClass:[NSArray class]];
    BOOL isDict = [plist isKindOfClass:[NSDictionary class]];
    
    if (!isDict && !isArray) return nil;
    
    NSArray * items = (isArray) ? (NSArray*)plist : [(NSDictionary *)plist objectForKey:@"items"];
	
    NSDictionary *albumArt = (isArray) ? nil : [(NSDictionary *)plist objectForKey:@"albumArt"];

    NSArray *queueList = (isArray) ? [NSArray array] : [(NSDictionary *)plist objectForKey:@"queue"];
    
	NSMutableArray *entries = [NSMutableArray array];
	
    for (NSDictionary *entry in items)
	{
        NSMutableDictionary * preparedEntry = [NSMutableDictionary dictionaryWithDictionary:entry];
        
        [preparedEntry setObject:[self urlForPath:[preparedEntry objectForKey:@"URL"] relativeTo:filename] forKey:@"URL"];
        
        if (albumArt && [preparedEntry objectForKey:@"albumArt"])
            [preparedEntry setObject:[albumArt objectForKey:[preparedEntry objectForKey:@"albumArt"]] forKey:@"albumArt"];
        
        [entries addObject:[NSDictionary dictionaryWithDictionary:preparedEntry]];
	}
    
	return [NSDictionary dictionaryWithObjectsAndKeys:entries, @"entries", queueList, @"queue", nil];
}

@end
