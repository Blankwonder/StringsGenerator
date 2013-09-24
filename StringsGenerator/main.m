//
//  main.m
//  StringsGenerator
//
//  Created by Blankwonder on 9/24/13.
//
//

#import <Foundation/Foundation.h>
#import "config.h"

static void _printLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    fprintf(stdout, "%s\n", [str UTF8String]);
    va_end(args);
}


int main(int argc, char *argv[])
{
    @autoreleasepool {
        NSError *error = nil;

        NSFileManager *fm = [NSFileManager defaultManager];

        NSArray *paths = [fm subpathsOfDirectoryAtPath:sourcePath error:nil];
        NSMutableArray *sourceFilePaths = [NSMutableArray array];
        for (NSString *path in paths) {
            if ([path hasSuffix:@".m"] ||
                [path hasSuffix:@".h"] ||
                [path hasSuffix:@".cpp"] ||
                [path hasSuffix:@".mm"]) {
                [sourceFilePaths addObject:path];
            }
        }

        NSMutableSet *resultSet = [NSMutableSet set];
        for (NSString *path in sourceFilePaths) {
            NSString *fullPath = [sourcePath stringByAppendingPathComponent:path];
            NSString *str = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];

            NSError *error = NULL;
            NSString *pattern = [NSString stringWithFormat:@"%@\\([^)]*?\\\"\\)", functionName];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

            [regex enumerateMatchesInString:str options:0 range:NSMakeRange(0, [str length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [resultSet addObject:[str substringWithRange:result.range]];
            }];
        }

        _printLog(@"Found %d records", resultSet.count);

        NSMutableDictionary *map = [NSMutableDictionary dictionary];

        for (NSString *record in resultSet) {
            NSUInteger dotPosition = [record rangeOfString:@","].location;
            NSString *key = [record substringWithRange:NSMakeRange(20, dotPosition - 21)];
            NSString *content = [record substringWithRange:NSMakeRange(dotPosition + 1, record.length - dotPosition - 1)];

            content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            content = [content substringWithRange:NSMakeRange(2, content.length - 4)];

            if (map[key]) {
                if (![map[key] isEqualToString:content]) {
                    _printLog(@"Warning: Same key with different content: %@", key);
                    _printLog(@"Value1: %@, Value2: %@", map[key], content);
                }
            } else {
                map[key] = content;
            }
        }

        NSMutableArray *lines = [NSMutableArray array];
        NSMutableString *content = [NSMutableString string];
        [map enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [lines addObject:[NSString stringWithFormat:@"\"%@\" = \"%@\";", key, obj]];
            [content appendFormat:@"%@\n", obj];
        }];
        [lines sortUsingSelector:@selector(compare:)];

        NSString *enResult = [lines componentsJoinedByString:@"\n"];
        [enResult writeToFile:baseStringsFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];

        NSMutableDictionary *translatedMap = [NSMutableDictionary dictionary];
        NSMutableDictionary *translatedDeprecatedMap = [NSMutableDictionary dictionary];

        NSString *translatedStr = [NSString stringWithContentsOfFile:translatedStringsFilePath encoding:NSUTF8StringEncoding error:nil];

        NSMutableSet *keyTest = [NSMutableSet setWithArray:map.allKeys];
        [translatedStr enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            NSUInteger position = [line rangeOfString:@"="].location;
            if (position != NSNotFound) {
                NSUInteger commentPosition = [line rangeOfString:@"//"].location;
                if (commentPosition != NSNotFound) {
                    line = [line substringToIndex:commentPosition];
                }

                NSString *key = [line substringWithRange:NSMakeRange(0, position)];
                NSString *content = [line substringWithRange:NSMakeRange(position + 1, line.length - position - 1)];
                NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"\" ;"];
                content = [content stringByTrimmingCharactersInSet:cset];
                key = [key stringByTrimmingCharactersInSet:cset];

                if (map[key]) {
                    if (content.length > 0) {
                        translatedMap[key] = content;
                        [keyTest removeObject:key];
                    }
                } else {
                    translatedDeprecatedMap[key] = content;
                }
            }
        }];

        NSMutableArray *translatedlines = [NSMutableArray array];
        [translatedMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [translatedlines addObject:[NSString stringWithFormat:@"\"%@\" = \"%@\";", key, obj]];
        }];
        [translatedlines sortUsingSelector:@selector(compare:)];

        if (keyTest.count > 0) {
            [translatedlines addObject:@""];
            [translatedlines addObject:@"/*New*/"];

            [keyTest enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                [translatedlines addObject:[NSString stringWithFormat:@"\"%@\" = \"\"; //%@", obj, map[obj]]];
            }];
        }

        if (translatedDeprecatedMap.count > 0) {
            [translatedlines addObject:@""];
            [translatedlines addObject:@"/*Deprecated*/"];
            
            [translatedDeprecatedMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [translatedlines addObject:[NSString stringWithFormat:@"\"%@\" = \"%@\";", key, obj]];
            }];
        }
        
        NSString *translatedResult = [translatedlines componentsJoinedByString:@"\n"];
        [translatedResult writeToFile:translatedStringsFilePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
    
    return 0;
}