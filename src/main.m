//
//  main.m
//  simple-telnetd
//
//  Created by Dmitry Rodionov on 11/06/2017.
//  Copyright © 2017 Internals Exposed. All rights reserved.
//

@import Foundation;
#import "IETelnetDaemon.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        IETelnetDaemon *daemon = [IETelnetDaemon new];
        [daemon run];
    }
}
