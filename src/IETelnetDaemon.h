//
//  IETelnetDaemon.h
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

@import Foundation;

/// A simple "application" class that has the following three responsibilities:
///
/// 1.  Parse command line arguments (e.g. timeout, port number, etc)
///
/// 2.  Set up the telnet server with the specified configuration
///
/// 3.  Handle signals (e.g. SIGHUP for reloading the current configuration)
@interface IETelnetDaemon : NSObject

- (void)run;

@end
