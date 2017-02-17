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
NSString *sasToken;

NSString *iotHubName = @"<yourhubname>";
NSString *deviceName = @"<yourdevicename>";
NSString *azureFunctionName = @"<yourazureregistrationfunction>";
NSString *azureFunctionCode = @"<yourazurefunctioncode>";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)GetAuth {
    NSString *urlPath = [NSString stringWithFormat:@"https://%@.azurewebsites.net/api/registerdevice?code=%@", azureFunctionName, azureFunctionCode];
    
    NSURL *url = [NSURL URLWithString:urlPath];
    NSDictionary *dictionary = @{ @"name" : deviceName };
    
    
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
            sasToken = json[@"SASToken"];
            
            NSLog(@"%@", sasToken);
            [self Connect];
        }
        else
        {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
    
    [task resume];
}

- (IBAction)sendMessage:(id)sender {
    CocoaMQTTMessage *message = [CocoaMQTTMessage alloc];
    
    NSString *topic = [NSString stringWithFormat:@"devices/%@/messages/events/", deviceName];
    message.topic = topic;
    
    NSString *payload = [NSString stringWithFormat:@"{'DeviceId': '%@', 'Message':'testme'}", deviceName];
    message.payload = [self getPayload:payload];
    
    [mqtt publish: message];
    
    NSLog(@"send");
}

-(void) Connect {
    
    NSString *host = [NSString stringWithFormat:@"%@.azure-devices.net", iotHubName];
    NSString *username = [NSString stringWithFormat:@"%@.azure-devices.net/%@", iotHubName, deviceName];
    
    mqtt = [[CocoaMQTT alloc]  initWithClientID:deviceName host:host port:8883];
    mqtt.username = username;
    mqtt.password = sasToken;
    mqtt.keepAlive = 60;
    mqtt.enableSSL = true;
    mqtt.delegate = self;
    
    [mqtt connect];
    
    NSLog(@"connect");
}

- (IBAction)register:(id)sender {
    [self GetAuth];
}

- (IBAction)connect:(id)sender {
    [self GetAuth];
}

-(void)mqtt:(CocoaMQTT *)mqtt didConnectAck:(enum CocoaMQTTConnAck)ack{
    NSLog(@"didConnectAck: %hhu",ack);
    
    if (ack == CocoaMQTTConnAckAccept) {
        NSString *subscription = [NSString stringWithFormat:@"devices/%@/messages/devicebound/#", deviceName];
        [mqtt subscribe: subscription qos:CocoaMQTTQOSQos1];
    }
    else{
        NSLog(@"did not successfully connect");
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
