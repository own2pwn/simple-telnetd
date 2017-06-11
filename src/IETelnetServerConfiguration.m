//
//  IETelnetServerConfig.m
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "IETelnetServerConfiguration.h"
#import "NSArray+FP.h"

@interface IETelnetServerConfiguration()
@property (strong, readwrite, nonnull) NSArray <NSString *> *whitelist;
@property (readwrite) NSUInteger preferredPort;
@property (readwrite) NSUInteger timeout;
@end

@implementation IETelnetServerConfiguration

#pragma mark - Initialization

- (nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)configurationFileURL
                                 preferredPort:(NSUInteger)port
                                commandTimeout:(NSUInteger)timeout
{
    NSArray <NSString *> *maybeWhitelist = [self fetchWhitelistFromURL:configurationFileURL];
    if (maybeWhitelist == nil) {
        return nil;
    }
    
    if ((self = [super init])) {
        _URL = configurationFileURL;
        _whitelist = maybeWhitelist;
        _preferredPort = port;
        _timeout = timeout;
    }
    return self;
}

#pragma mark - Public Interface

- (void)reload
{
    self.whitelist = [self fetchWhitelistFromURL:self.URL];
}

#pragma mark - File IO

- (nullable NSArray <NSString *> *)fetchWhitelistFromURL:(nonnull NSURL *)fileURL
{
    // 1) Load the whole file in memory
    NSError *error = nil;
    NSString *contents = [NSString stringWithContentsOfURL:fileURL
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (contents == nil) {
        NSLog(@"%s: Could not open the configuration file at %@: %@",
              __PRETTY_FUNCTION__, fileURL, error);
        return nil;
    }
    // 2) Split the text by whitespaces/newlines
    return [contents componentsSeparatedByCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
