//
//  IETelnetServer.h
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

@import Foundation;
#import "IETelnetServerConfiguration.h"

/// This class represents an actual server that listens for requests on a specific port. Each request
/// specifies a command to execute and a list of arguments for this command. The command's output
/// is then sent as a response back to the client.
///
/// The server has a white list of commands to execute (see @c IETelnetServerConfiguration) and
/// will return an error when processing a request to execute a command not from this list.
///
/// Internally, this server uses Apple's QServer from RemoteCurrency sample project which provides
/// a high-level foundation for building a TCP server that supports IPv4/IPv6 and Bonjour discovery.
@interface IETelnetServer : NSObject

@property (strong, readonly, nonnull) IETelnetServerConfiguration *configuration;
@property (readonly) NSUInteger assignedPort;

/// Initialize with the default configuration
/// NOTE: The server won't automatically start running after initializing. Call -start
/// (or -run) to actually start the server.
- (nonnull instancetype)init NS_UNAVAILABLE;
/// Initialize with a custom configuration
/// NOTE: The server won't automatically start running after initializing. Call -start
/// (or -run) to actually start the server.
- (nonnull instancetype)initWithConfiguration:(nonnull IETelnetServerConfiguration *)configuration;

/// Starts the server
- (void)start;
/// Starts the server and keeps it running (by spinning the runloop) until it's stopped
- (void)run;
/// Stops the server
- (void)stop;

@end
