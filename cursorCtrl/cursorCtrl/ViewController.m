//
//  ViewController.m
//  cursorCtrl
//
//  Created by Tomás Vega on 3/26/19.
//  Copyright © 2019 Tomás Vega. All rights reserved.
//

#import "ViewController.h"
#include <ApplicationServices/ApplicationServices.h>
#include <unistd.h>
//#import "GCDAsyncSocket.h" // for TCP
#import "GCDAsyncUdpSocket.h" // for UDP

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setScreenSize];
//    [self moveCursor];
//    NSURL* url = [[NSURL alloc] initWithString:@"http://localhost:8080"];
//    SocketIOClient* socket = [[SocketIOClient alloc] initWithSocketURL:url config:@{@"log": @YES];
//    [socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
//        NSLog(@"socket connected");
//    }];
//[socket connect];
//    // Do any additional setup after loading the view.
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![udpSocket bindToPort:33336 error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return;
    } else {
        NSLog(@"No error binding");
    }
    if (![udpSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }

//    [udpSocket receiveWithTimeout:-1 tag:0];
//    [listenSocket acceptOnPort:port error:&error]
//    [NSTimer scheduledTimerWithTimeInterval:2.0
//                                     target:self
//                                   selector:@selector(targetMethod:)
//                                   userInfo:nil
//                                    repeats:NO];
}

- (void) setScreenSize {
//    CGDirectDisplayID displayID = CGMainDisplayID();
//    size_t screenWidth = CGDisplayPixelsWide(displayID);
//    size_t screenHeight = CGDisplayPixelsHigh(displayID);
//    NSLog(@"%zu", screenWidth);
//    NSLog(@"%zu", screenHeight);
    
    NSScreen *screen = [NSScreen mainScreen];
    NSDictionary *description = [screen deviceDescription];
    NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
//    CGSize displayPhysicalSize = CGDisplayScreenSize([[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);
    //    NSLog(@"DPI is %0.2f",
    //          (displayPixelSize.width / displayPhysicalSize.width) * 25.4f);
    
    NSLog(@"pixelSize.width %0.2f", displayPixelSize.width);
    NSLog(@"pixelSize.height %0.2f", displayPixelSize.height);
    _screenWidth = displayPixelSize.width;
    _screenHeight = displayPixelSize.height;
    //    NSLog(@"physSize.width %0.2f", displayPhysicalSize.width);
    //    NSLog(@"physSize.height %0.2f", displayPhysicalSize.height);
    NSPoint mouseWarpLocation = NSMakePoint(_screenWidth/2, _screenHeight/2);
    
    
    CGEventRef move1 = CGEventCreateMouseEvent(
                                               NULL, kCGEventMouseMoved,
                                               mouseWarpLocation,
                                               kCGMouseButtonLeft // ignored
                                               );
    CGEventPost(kCGHIDEventTap, move1);
    CFRelease(move1);
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}



- (void) moveCursor {
    // Move to 200x200
    CGEventRef move1 = CGEventCreateMouseEvent(
                                               NULL, kCGEventMouseMoved,
                                               CGPointMake(0, 0),
                                               kCGMouseButtonLeft // ignored
                                               );
    // Move to 250x250
    CGEventRef move2 = CGEventCreateMouseEvent(
                                               NULL, kCGEventMouseMoved,
                                               CGPointMake(1680, 1050),
                                               kCGMouseButtonLeft // ignored
                                               );
    // Left button down at 250x250
    CGEventRef click1_down = CGEventCreateMouseEvent(
                                                     NULL, kCGEventLeftMouseDown,
                                                     CGPointMake(1680, 1050),
                                                     kCGMouseButtonLeft
                                                     );
    // Left button up at 250x250
    CGEventRef click1_up = CGEventCreateMouseEvent(
                                                   NULL, kCGEventLeftMouseUp,
                                                   CGPointMake(1680, 1050),
                                                   kCGMouseButtonLeft
                                                   );
    
    // Now, execute these events with an interval to make them noticeable
    CGEventPost(kCGHIDEventTap, move1);
    sleep(1);
    CGEventPost(kCGHIDEventTap, move2);
    sleep(1);
    CGEventPost(kCGHIDEventTap, click1_down);
    CGEventPost(kCGHIDEventTap, click1_up);
    
    // Release the events
    CFRelease(click1_up);
    CFRelease(click1_down);
    CFRelease(move2);
    CFRelease(move1);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
}

- (void)updateCursor:(NSString *)data {
    NSPoint mouseLoc;
    mouseLoc = [NSEvent mouseLocation]; //get current mouse position
    
    NSArray *elems = [data componentsSeparatedByString: @","];
    NSString *cmd = elems[0];
    if ([cmd isEqualToString:@"I"]) {
        NSString *x = elems[2];
        NSString *y = elems[3];
        NSString *z = elems[4];
//        NSLog(@"%@ %@ %@", x, y, z);
        
//        NSInteger deltaX = _screenWidth
        NSInteger newX = [x integerValue] * -1 * 0.8 + _prevX * 0.2;
        NSInteger newY = [y integerValue] * 0.8 + _prevY * 0.2;
        NSInteger deltaX = newX - _prevX;
        NSInteger deltaY = newY - _prevY;
        _prevX = newX;
        _prevY = newY;
//        if (deltaX == 0 && deltaY == 0) {
//            return;
//        }
//        CGPoint mousePoint = CGPointMake([NSEvent mouseLocation].x, [NSScreen mainScreen].frame.size.height - [NSEvent mouseLocation].y);
        NSLog(@"Mouse location: %f %f", mouseLoc.x, mouseLoc.y);
        NSInteger nY = [NSScreen mainScreen].frame.size.height - [NSEvent mouseLocation].y;
        NSLog(@"%ld", (long)nY);
        NSLog(@"DeltaX: %ld, DeltaY: %ld", (long)deltaX, (long)deltaY);
        NSInteger mouseX = mouseLoc.x + deltaX;
        NSInteger mouseY = (_screenHeight - mouseLoc.y) + deltaY;
        if (mouseX > _screenWidth) {
            mouseX = _screenWidth;
        } else if (mouseX < 0) {
            mouseX = 0;
        }
        if (mouseY > _screenHeight) {
            mouseY = _screenHeight;
        } else if (mouseY < 0) {
            mouseY = 0;
        }
        NSLog(@"New Mouse location: %ld %ld", (long)mouseX, (long)mouseY);
        NSLog(@"--------");
        NSPoint mouseWarpLocation = NSMakePoint(mouseX, mouseY);
        

        CGEventRef move1 = CGEventCreateMouseEvent(
           NULL, kCGEventMouseMoved,
           mouseWarpLocation,
           kCGMouseButtonLeft // ignored
        );
        CGEventPost(kCGHIDEventTap, move1);
        CFRelease(move1);

    } else if ([cmd isEqualToString:@"G"]) {
        NSLog(@"TAP");
    }
    
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg) {
//        NSLog(@"RECV: %@", msg);
        [self updateCursor:msg];
    } else {
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
    }
}
@end
