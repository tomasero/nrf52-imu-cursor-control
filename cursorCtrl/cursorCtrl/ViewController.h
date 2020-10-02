//
//  ViewController.h
//  cursorCtrl
//
//  Created by Tomás Vega on 3/26/19.
//  Copyright © 2019 Tomás Vega. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"


@interface ViewController : NSViewController <GCDAsyncUdpSocketDelegate>
{
    long tag;
    GCDAsyncUdpSocket *udpSocket;
}

@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, assign) bool init;
@property (nonatomic, assign) NSInteger prevX;
@property (nonatomic, assign) NSInteger prevY;
//@property (nonatomic, assign) SocketIO *socketIO;

- (void) moveCursor;

@end

