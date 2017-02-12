//
//  ViewController.m
//  ios-iot-objC
//
//  Created by James Sturtevant on 2/10/17.
//  Copyright © 2017 James Sturtevant. All rights reserved.
//

#import "ViewController.h"
@import CocoaMQTT;

@interface ViewController ()

@end

@implementation ViewController

CocoaMQTT *mqtt;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)connect:(id)sender {
    CocoaMQTT *mqtt = [[CocoaMQTT alloc]  initWithClientID:@"<devicename>" host:@"<hub-name>.azure-devices.net" port:8883];
    mqtt.username = @"<yourhubname>.azure-devices.net/<devicename>";
    mqtt.password = @"SharedAccessSignature <yoursas>";
    mqtt.keepAlive = 60;
    mqtt.enableSSL = true;
    mqtt.delegate = self;
    
    [mqtt connect];
    
    NSLog(@"connect");
    
    
}

-(void)mqtt:(CocoaMQTT *)mqtt didConnectAck:(enum CocoaMQTTConnAck)ack{
    NSLog(@"didConnectAck: %hhu",ack);
    
    if (ack == CocoaMQTTConnAckAccept) {
        CocoaMQTTMessage *message = [CocoaMQTTMessage alloc];
        message.topic = @"devices/workshopdevice/messages/events/";
        message.payload = [self getPayload:@"test"];
        
        [mqtt publish: message];
        //[mqtt subscribe "devices/workshopdevice/messages/devicebound/#", qos: CocoaMQTTQOS.qos1]
    }
}

-(NSArray<NSNumber *> *)getPayload:(NSString *)message {
    const char *chars = [message UTF8String];
    NSMutableArray<NSNumber *> *payload = [[NSMutableArray<NSNumber *> alloc] init];
    for (int i=0; i < [message length]; i++) {
        
        NSNumber *num = [[NSNumber alloc] initWithInt: chars[i]];
        [payload addObject:num];
    }
    
    return payload;
}

-(void)mqtt:(CocoaMQTT *)mqtt didConnect:(NSString *)host port:(NSInteger)port{
    NSLog(@"didConnect %@:%li", host, (long)port);
}

-(void)mqtt:(CocoaMQTT *)mqtt didPublishAck:(uint16_t)id{

}

-(void)mqtt:(CocoaMQTT *)mqtt didPublishMessage:(CocoaMQTTMessage *)message id:(uint16_t)id{}

-(void)mqtt:(CocoaMQTT *)mqtt didReceive:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler{}
-(void)mqtt:(CocoaMQTT *)mqtt didReceiveMessage:(CocoaMQTTMessage *)message id:(uint16_t)id{}
-(void)mqtt:(CocoaMQTT *)mqtt didSubscribeTopic:(NSString *)topic{}
-(void)mqtt:(CocoaMQTT *)mqtt didUnsubscribeTopic:(NSString *)topic{}
-(void)mqttDidDisconnect:(CocoaMQTT *)mqtt withError:(NSError *)err{}
-(void)mqttDidPing:(CocoaMQTT *)mqtt{}
-(void)mqttDidReceivePong:(CocoaMQTT *)mqtt{}

@end
