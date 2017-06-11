//
//  IETelnetConnection.h
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "QCommandLineConnection.h"

@class IETelnetConnection;

/// See @IETelnetConnection
@protocol IFCommandExecutor <NSObject>
@required
- (void)execute:(nonnull NSString *)cmd
      arguments:(nonnull NSArray <NSString *> *)arguments
     connection:(nonnull IETelnetConnection *)connection;
@end

/// Each request from a client initiates a new connection. This connection class is a simple bridge
/// for receiving the actual request and sending a reply back to the client.
///
/// Each connection has a reference to a command executor which is responsible for actual execution
/// of requested programms and passing their output back to the client.
@interface IETelnetConnection: QCommandLineConnection

@property (weak, nullable) id <IFCommandExecutor> executor;

- (void)sendResponseLine:(nonnull NSString *)response;
- (void)sendResponseLines:(nonnull NSArray <NSString *> *)response;
- (void)sendError:(nonnull NSString *)error;

@end
