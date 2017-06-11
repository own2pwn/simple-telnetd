//
//  IETelnetServer.m
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "IETelnetServer.h"
#import "IETelnetConnection.h"
#import "QServer.h"

@interface IETelnetServer() <QServerDelegate, IFCommandExecutor, QCommandConnectionDelegate>
@property (strong) QServer *server;
@property (readwrite) NSUInteger assignedPort;
@end

@implementation IETelnetServer

#pragma mark - Creation

- (instancetype)initWithConfiguration:(IETelnetServerConfiguration *)configuration
{
    if ((self = [super init])) {
        _configuration = configuration;
    }
    return self;
}

#pragma mark - Lifetime

- (void)start
{
    NSAssert(self.server == nil, @"The server is already running");
    // 1) Try to create a server with the given configuration
    self.server = [[QServer alloc] initWithDomain:nil type:nil name:nil
                                    preferredPort:self.configuration.preferredPort];
    NSAssert(self.server != nil, @"Failed to create a server with configuration: %@",
             self.configuration);
    // 2) Make ourselves a delegate of the server to actually accept incoming requests and
    // send replies
    self.server.delegate = self;
    // 3) Finally we're ready to start the newly created server
    [self.server start];

    self.assignedPort = self.server.registeredPort;
}

- (void)run
{
    // 1) Start the server
    [self start];
    // 2) Keep the server running by spinning the runloop until it is stopped by someone
    while (self.server != nil) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
}

- (void)stop
{
    NSAssert(self.server != nil, @"The server is not running");
    [self.server stop];
    self.server.delegate = nil;
    self.server = nil;
}

#pragma mark - QServerDelegate's

- (void)serverDidStart:(QServer *)server
{
    NSLog(@"Server is up and running!");
}

- (void)server:(QServer *)server didStopWithError:(NSError *)error
{
    NSLog(@"Server is shutting down");
    [self stop];
}

- (id)server:(QServer *)server connectionForInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    IETelnetConnection *connection = [[IETelnetConnection alloc] initWithInputStream:inputStream
                                                                        outputStream:outputStream];
    if (connection != nil) {
        connection.delegate = self;
        connection.executor = self;
        [connection open];
    }
    return connection;
}

- (void)server:(QServer *)server closeConnection:(id)someConnection
{
    NSParameterAssert([someConnection isKindOfClass:[IETelnetConnection class]]);
    IETelnetConnection *connection = (IETelnetConnection *)someConnection;
    [connection close];
}

- (void)server:(QServer *)server logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString *log = [[NSString alloc] initWithFormat:format arguments:argList];
    NSLog(@"Server log: %@", log);
}

#pragma mark - QCommandConnectionDelegate's

- (void)connection:(QCommandConnection *)connection willCloseWithError:(NSError *)error
{
    [self.server closeOneConnection:connection];
}

#pragma mark - IFCommandExecutor's

- (void)execute:(NSString *)program arguments:(NSArray<NSString *> *)arguments connection:(IETelnetConnection *)connection
{
    // 1) Make sure the program we're going to execute is actually whitelisted
    if (![self.configuration.whitelist containsObject:program]) {
        NSString *error = [NSString stringWithFormat:@"Operation not permitted (%@ is not whitelisted)", program];
        [connection sendError:error];
        return;
    }
    // 2) Prepare an NSTask
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = program;
    task.arguments = arguments;
    NSPipe *output = [NSPipe pipe];
    task.standardOutput = output;
    NSPipe *error = [NSPipe pipe];
    task.standardError = error;
    // 3) Enforce a timeout on the program via a GCD semaphore
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    task.qualityOfService = NSQualityOfServiceUserInitiated;
    task.terminationHandler = ^(NSTask *t) {
        dispatch_semaphore_signal(sema);
    };
    // 4) Launch the task
    [task launch];
    // 5) Wait for it to complete (or for a set timeout)
    dispatch_time_t timeout = DISPATCH_TIME_FOREVER;
    if (self.configuration.timeout != 0) {
        timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.configuration.timeout * NSEC_PER_SEC));
    }
    long status = dispatch_semaphore_wait(sema, timeout);
    // 6) Make sure the task is terminated gracefully
    if (status != 0) {
        [connection sendError:@"Execution error (timeout)"];;
        return;
    }
    // 7) Route everything from stderr (if anything)
    NSFileHandle *errorHandle = [error fileHandleForReading];
    NSData *rawError = [errorHandle readDataToEndOfFile];
    NSString *errorString = [[NSString alloc] initWithData:rawError encoding:NSUTF8StringEncoding];
    if (errorString.length > 0) {
        [connection sendError:[errorString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]];
    }
    if (task.terminationReason != NSTaskTerminationReasonExit) {
        NSString *error = [NSString stringWithFormat:@"Execution error (exit status %d)", task.terminationStatus];
        [connection sendError:error];
        return;
    }
    // 8) Fetch the output of the program and pass it to the client
    NSFileHandle *outputHandle = [output fileHandleForReading];
    NSData *rawOutput = [outputHandle readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:rawOutput encoding:NSUTF8StringEncoding];

    [connection sendResponseLines:[outputString componentsSeparatedByCharactersInSet:
                                   [NSCharacterSet newlineCharacterSet]]];
}

@end
