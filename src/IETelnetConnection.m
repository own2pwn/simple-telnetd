//
//  IETelnetConnection.m
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

#import "IETelnetConnection.h"
#import "NSArray+FP.h"

@implementation IETelnetConnection

- (void)sendResponseLine:(nonnull NSString *)line
{
    NSString *raw = [NSString stringWithFormat:@"  %@\r\n", line];
    [self sendCommand:[raw dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendResponseLines:(nonnull NSArray <NSString *> *)lines
{
    NSString *raw = [lines rd_reduce:^NSString *(NSString *sum, NSString *line) {
        return [sum stringByAppendingFormat:@"  %@\r\n", line];
    } from:@""];
    [self sendCommand:[raw dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendError:(NSString *)error
{
    NSString *raw = [NSString stringWithFormat:@"  [!] %@\r\n", error];
    [self sendCommand:[raw dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)didReceiveCommandLine:(NSString *)input
{
    // We were given a raw user input, now we need to parse command line arguments and pass
    // them further to our delegate for actual execution.
    // Since command line arguments parsing is non-trival and goes way beyond the scope
    // of this simple daemon, I'd like to consider the following options:
    //
    // 1.   Split the given string by whitespaces and call it a day. In this scenario users
    //      won't be able to use string arguments with whitespace characters in them. Multiline
    //      strings would also be handled incorrectly.
    //
    // 2.   Delegate all parsing to a shell (Bash), i.e. invoke `sh -c` with a raw user input string.
    //      In this scenario we wouldn't be able to enforce the whitelist of programs a user is able
    //      to execute, though.
    //      Sure, we can spawn a restrictive sheel wrapped in chroot environment but, once again,
    //      it goes beyond the scope of this daemon, so I'd rather not.
    //
    // Given that the task description didn't mention anything about *the kind* of arguments, I suppose
    // that we can stick with #1 and parse the user's input in a dumb way (i.e. no multi-word args).

    NSArray <NSString *> *components = [input componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (components.count == 0) {
        NSLog(@"Were given an empty input string, aborting");
    }
    NSString *programPath = [components firstObject];
    NSArray <NSString *> *arguments = @[];
    if (components.count > 1) {
        arguments = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];
    }

    if ([self.executor respondsToSelector:@selector(execute:arguments:connection:)]) {
        [self.executor execute:programPath arguments:arguments connection:self];
    }
}

@end
