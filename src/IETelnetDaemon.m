//
//  IETelnetDaemon.m
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "IETelnetDaemon.h"
#import "IETelnetServer.h"

static NSString * _Nonnull const IETelnetDaemonDefaultPath = @"/tmp/simple-telnetd.conf";
static NSUInteger const IETelnetDaemonDefaultPreferredPort = 4040;
static NSUInteger const IETelnetDaemonDefaultTimeout = 0;

@interface IETelnetDaemon()
@property (strong) IETelnetServer *server;
@property (strong) dispatch_source_t signalHandlingSource;
@end

@implementation IETelnetDaemon

- (instancetype)init
{
    if ((self = [super init])) {
        IETelnetServerConfiguration *configuration = [self serverConfiguration];
        NSAssert(configuration != nil, @"Invalid configuration (file does not exist)");
        
        _server = [[IETelnetServer alloc] initWithConfiguration:[self serverConfiguration]];
        [self listenSIGHUP];
    }
    return self;
}

- (void)dealloc
{
    if (self.signalHandlingSource) {
        dispatch_source_cancel(self.signalHandlingSource);
    }
}

#pragma mark - Lifecycle

- (void)run
{
    [self.server run];
}

- (void)listenSIGHUP
{
    // 1) Make sure not to trigger any default signal handlers for SIGHUP
    struct sigaction action = { 0 };
    action.sa_handler = SIG_IGN;
    sigaction(SIGHUP, &action, NULL);

    // 2) Register our own handler in which we reload the configuration file
    self.signalHandlingSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGHUP,
                                                       0, dispatch_get_main_queue());
    dispatch_source_set_event_handler(self.signalHandlingSource, ^{
        [self.server.configuration reload];
    });
    dispatch_resume(self.signalHandlingSource);
}

#pragma mark - Server Configuration

- (nullable IETelnetServerConfiguration *)serverConfiguration
{
    // 1) Create a configuration file if it's not there already
    // NOTE: we do not handle any errors that are due to invalid permissions and such
    NSURL *defaultURL = [NSURL fileURLWithPath:IETelnetDaemonDefaultPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:defaultURL.path]) {
        NSLog(@"%s: Attempt to create an empty configuration file at %@",
              __PRETTY_FUNCTION__, defaultURL);
        [self createEmptyConfigurationFileAtURL:defaultURL];
    }
    // 2) fetch a custom timeout passed as a command line argument (if any)
    NSUInteger timeout = IETelnetDaemonDefaultTimeout;
    NSString *customTimeoutString = [[NSUserDefaults standardUserDefaults] stringForKey:@"timeout"];
    if (customTimeoutString != nil) {
        timeout = (NSUInteger)customTimeoutString.integerValue;
    }
    // 3) do the same with the preferred port number
    NSUInteger preferredPort = IETelnetDaemonDefaultPreferredPort;
    NSString *customPreferredPortString = [[NSUserDefaults standardUserDefaults] stringForKey:@"port"];
    if (customPreferredPortString != nil) {
        preferredPort = (NSUInteger)customPreferredPortString.integerValue;
    }

    return [[IETelnetServerConfiguration alloc] initWithContentsOfURL:defaultURL
                                                        preferredPort:preferredPort
                                                       commandTimeout:timeout];
}

- (void)createEmptyConfigurationFileAtURL:(nonnull NSURL *)fileURL
{
    BOOL created = [[NSFileManager defaultManager] createFileAtPath:fileURL.path
                                                           contents:[NSData data]
                                                         attributes:nil];
    NSAssert(created, @"%s: Failed to create an empty configuration file %@",
             __PRETTY_FUNCTION__, fileURL);
}

@end
