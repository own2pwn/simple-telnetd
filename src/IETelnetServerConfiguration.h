//
//  IETelnetServerConfiguration.h
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

@import Foundation;

/// A container for multiple server options such as whitelist of commands, preferred port number and
/// an execution timeout value.
///
/// Each configuration is backed by a file on disk. See @c IETelnetDaemon for the default configuration file URL
@interface IETelnetServerConfiguration : NSObject

@property (strong, readonly, nonnull) NSURL *URL;
@property (strong, readonly, nonnull) NSArray <NSString *> *whitelist;
@property (readonly) NSUInteger preferredPort;
@property (readonly) NSUInteger timeout; // A timeout in seconds. 0 means no timeout at all.

- (nullable instancetype)initWithContentsOfURL:(nonnull NSURL *)configurationFileURL
                                 preferredPort:(NSUInteger)port
                                commandTimeout:(NSUInteger)timeout;

/// Reload the configuration from the disk
- (void)reload;

@end
