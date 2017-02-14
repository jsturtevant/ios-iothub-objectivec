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
- (void)PostUrl {
    NSURL *url = [NSURL URLWithString:@"https://url.com"];
    NSDictionary *dictionary = @{ @"name" : @"yourname" };
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = JSONData;
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data,
                                                                                     NSURLResponse *response,
                                                                                     NSError *error)
    {
        if (!error)
        {
            NSLog(@"Status code: %li", (long)((NSHTTPURLResponse *)response).statusCode);
            NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
            NSLog(@"%@", text);
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"%@", json);
        }
        else
        {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
    
    // Start the task.
    [task resume];
}

- (IBAction)sendMessage:(id)sender {
    CocoaMQTTMessage *message = [CocoaMQTTMessage alloc];
    message.topic = @"devices/workshopdevice/messages/events/";
    message.payload = [self getPayload:@"{ 'DeviceId': 'workshopdevice', 'Message': 'hello'}"];
    
    [mqtt publish: message];
}


- (IBAction)register:(id)sender {
    [self PostUrl];
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
        
        [mqtt subscribe: @"devices/workshopdevice/messages/devicebound/#" qos:CocoaMQTTQOSQos1];
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
-(void)mqtt:(CocoaMQTT *)mqtt didReceiveMessage:(CocoaMQTTMessage *)message id:(uint16_t)id{
    NSLog(@"didReceivedMessage: %@", message.string);
}
-(void)mqtt:(CocoaMQTT *)mqtt didSubscribeTopic:(NSString *)topic{}
-(void)mqtt:(CocoaMQTT *)mqtt didUnsubscribeTopic:(NSString *)topic{}
-(void)mqttDidDisconnect:(CocoaMQTT *)mqtt withError:(NSError *)err{}
-(void)mqttDidPing:(CocoaMQTT *)mqtt{}
-(void)mqttDidReceivePong:(CocoaMQTT *)mqtt{}

@end
