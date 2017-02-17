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

- (void)Connect {
    if (sasToken == (id)[NSNull null] || sasToken.length == 0 ){
        [self CallAuthService];
        return;
    }

    //other wise we have a valid sastoken and call connect
    [self ConnectToHub];
}

-(void) CallAuthService {
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
                                          [self ConnectToHub];
                                      }
                                      else
                                      {
                                          NSLog(@"Error: %@", error.localizedDescription);
                                      }
                                  }];
    
    [task resume];
}

- (IBAction)sendMessage:(id)sender {
    NSString *topic = [NSString stringWithFormat:@"devices/%@/messages/events/", deviceName];
    NSString *payload = [NSString stringWithFormat:@"{'DeviceId': '%@', 'Message':'testme'}", deviceName];

    [mqtt publish:topic withString: payload qos:CocoaMQTTQOSQos1 retained:false dup:false];
    
    NSLog(@"send");
}

-(void) ConnectToHub {
    NSString *host = [NSString stringWithFormat:@"%@.azure-devices.net", iotHubName];
    NSString *username = [NSString stringWithFormat:@"%@.azure-devices.net/%@", iotHubName, deviceName];
    
    mqtt = [[CocoaMQTT alloc]  initWithClientID:deviceName host:host port:8883];
    mqtt.username = username;
    mqtt.password = sasToken;
    mqtt.keepAlive = 60;
    mqtt.enableSSL = true;
    mqtt.delegate = self;
    
    [mqtt connect];
    NSLog(@"connect sent");
}

- (IBAction)connect:(id)sender {
    [self Connect];
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
