## simple-telnetd

This is a very naiive implementation of a simple telnet daemon for macOS that allows clients to execute a  limited set of commands and receive their output back.

Each command may have zero or more arguments *(note that string literals with whitespaces are not supported)* and follows this format:

```
/path/to/executable [argument1 argument2 argument3 ...]
```

### Building

Open `simple-telnetd.xcodeproj` and press the Run button (cmd+R). Or use `xcodebuild` to build the daemon via command line interface:

```
$ xcodebuild -target simple-telnetd -configuration Release
```

### Configuration

Which commands are allowed is determined by the contents of the configuration file /tmp/simple-telnetd.conf. For example if you want to only allow `cat` and `echo` commands, the configuration file will looks like follows:

```
/bin/cat
/bin/echo
```

The daemon has a whitelist-based approach of filtering commands so if you don't specify anything in the  configuration file, `simple-telnetd` is going to do nothing.


### Usage (server)

Just launch it:

```
$ simple-telnetd
```

Alternatively you can specify the exact port on which the daemon will be listening for incoming requests and the timeout in seconds before the daemon interrupts a running command:

```
$ simple-telnetd -port 1337 -timeout 5
```

The configuration file for simple-telnetd is loaded *once* at the daemon startup so it won't notice any changes to this file. To let the daemon know that it need to reload its configuration and apply new whitelist rules, send it a SIGHUP signal:

```
$ killall -SIGHUP simple-telnetd
```


### Usage (client)

The easiest way to test this daemon is to use the actual telnet client built in macOS:

```

$ telnet localhost 1337
Trying ::1...
Connected to localhost.
Escape character is '^]'.
/bin/echo "hey"
  "hey"

/bin/cat foobar
  [!] cat: foobar: No such file or directory
```

> Note that while the daemon does capture all of the command's output (i.e. stdout and stderr), it is not possible to interact with the command via stdin or any other facility.

## Architecture

```                                                                                  
                                                                                     
    ┌───────────────────┐    IETelnetDaemon is an "application" class that has the   
    │                   │    following responsibilities:                       
    │  IETelnetDaemon   │                                                            
    │                   │    1.  Parse command line arguments (e.g. timeout, port    
    └───────────────────┘    number, etc)                                            
              │                                                                      
              │              2.  Set up the telnet server with the specified         
              │              configuration                                           
              │                                                                      
              │              3.  Handle signals (e.g. SIGHUP for reloading the       
              │              current configuration)                                  
              │                                                                      
              │                                                                      
              ▼                                                                      
    ┌───────────────────┐    IETelnetServer represents an actual server that         
    │                   │    listens for requests on a specific port. Each request   
 ┌──│  IETelnetServer   │─┐  specifies a command to execute and a list of            
 │  │                   │ │  arguments for this command. The command's output is     
 │  └───────────────────┘ │  then sent as a response back to the client.             
 │            │           │                                                          
 │            │           │                                                          
 │            │           │                                 A container for multiple 
 │            │           │  ┌───────────────────────────┐  server options such as   
 │            │           │  │                           │  whitelist of commands,   
 │            │           └─▶│IETelnetServerConfiguration│  preferred port number and
 │            │              │                           │  an execution timeout     
 │            │              └───────────────────────────┘  value.                   
 │            │                                                                      
 │            │                                             Each configuration is    
 │            │                                             backed by a file on disk.
 │            │                                                                      
 │            │                                                                      
 │            │               ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                                  
 │            │                                                                      
 │            └──────────────▶│      QServer      │──────────────┐                   
 │                                                               │                   
 │                            └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘              ▼                   
 │                                                     ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐         
 │                                                                                   
 │                                                     │QCommandConnection │         
 │        Internally the server uses Apple's QServer       ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   
 │        from RemoteCurrency sample project which     └ ─ ─                      │  
 │        provides a high-level foundation for             │QCommandLineConnection   
 │        building a TCP server that supports                                     │  
 │        IPv4/IPv6 and Bonjour discovery.                 └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   
 │                                                                                   
 │                                                                                   
 │                                                                                   
 │        ┌───────────────────┐  Each request from a client initiates a new          
 │        │                   │  connection. This connection class is a simple       
 ├───────▶│IETelnetConnection │  bridge that provides a high-level interface         
 │        │                   │  for receiving the actual request and sending a      
 │        └───────────────────┘  reply back to the client.                           
 │                                                                                   
 └────────┐                      Each connection has a reference to a command        
          │                      executor which is responsible for actual            
          │                      execution of requested programs and passing         
          │                      their output back to the client.                    
          ▼                                                                          
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐            In current implementation the telnet server         
                                 itself acts as a command launcher but it'd be       
│      NSTask       │            simple to move this responsibility to a             
                                 separate class.                                     
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘                                                                
                                                                                     
                                                                                     
We use NSTask to execute whitelisted                                                 
commands and parse their output (stdout                                              
and stderr).                                                                         
                                                                                     
We also set a timeout on each command                                                
invocation using GCD semaphore and report                                            
any execution errors to the client.                                                  
                                                                                                                                              
```

### Copyrights

QServer[.h, .m], QCommandConnection[.h, .m], QCommandLineConnection[.h, .m]
	Copyright (c) 2011 Apple Inc. All Rights Reserved.

IE* classes
	Copyright © 2017 Dmitry Rodionov. All rights reserved.







