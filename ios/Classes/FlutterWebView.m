#import "FlutterWebView.h"
FlutterEventSink eventSinkSecond;

@implementation FlutterNativeWebFactory {
  NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    _messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  FlutterNativeWebController* webviewController =
      [[FlutterNativeWebController alloc] initWithWithFrame:frame
                                       viewIdentifier:viewId
                                            arguments:args
                                      binaryMessenger:_messenger];
  return webviewController;
}

@end

@implementation FlutterNativeWebController {
  WKWebView* _webView;
  int64_t _viewId;
  FlutterMethodChannel* _channel;
  FlutterEventSink _eventSink;
  NSTimer* timer;


}

- (instancetype)initWithWithFrame:(CGRect)frame
                   viewIdentifier:(int64_t)viewId
                        arguments:(id _Nullable)args
                  binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if ([super init]) {
    _viewId = viewId;
    _webView = [[WKWebView alloc] initWithFrame:frame];

    __weak __typeof__(self) weakSelf = self;
    _webView.navigationDelegate = weakSelf;
    NSString* channelName = [NSString stringWithFormat:@"ponnamkarthik/flutterwebview_%lld", viewId];
    _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [weakSelf onMethodCall:call result:result];
    }];

    NSString* pageFinishedChannelName = [NSString stringWithFormat:@"ponnamkarthik/flutterwebview_stream_pagefinish_%lld", viewId];

    FlutterEventChannel* finishedChannel = [FlutterEventChannel
              eventChannelWithName:pageFinishedChannelName
                     binaryMessenger:messenger];
        [finishedChannel setStreamHandler:self];
      
      NSString* pageSuccessChannelName = [NSString stringWithFormat:@"ponnamkarthik/my_second_event_channel_%lld",viewId];
     
      SecondStreamHandler* secondStreamHandler =
             [[SecondStreamHandler alloc] init];
      
         FlutterEventChannel* secondEventChannel =
             [FlutterEventChannel eventChannelWithName:pageSuccessChannelName
                                       binaryMessenger:messenger];
     // messenger sendOnChannel:<#(nonnull NSString *)#> message:<#(NSData * _Nullable)#>
         [secondEventChannel setStreamHandler:secondStreamHandler];

  }
  return self;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
       _eventSink(@"loading page sucess");
    timer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(parseHtml) userInfo:nil repeats:YES];

 

}

- (void)parseHtml {
    [_webView evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(id html, NSError *error){
        
        NSString *htmlContent = (NSString*)html;
        if ( [htmlContent containsString:@"trung"]) {
             eventSinkSecond(@"checkoutsucess");
            [self->timer invalidate];
            self->timer = nil;
        }
           
            

    }];
}

- (FlutterError*)onListenWithArguments:(id)arguments
                             eventSink:(FlutterEventSink)eventSink {
               _eventSink = eventSink;
                 return nil;
           }

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
      _eventSink = nil;
        return nil;
}
- (UIView*)view {
  return _webView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"loadUrl"]) {
    [self onLoadUrl:call result:result];
  } else if ([[call method] isEqualToString:@"loadData"]) {
      [self onLoadData:call result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}


- (void)onLoadUrl:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSString* url = [call arguments];
  if (![self loadUrl:url]) {
    result([FlutterError errorWithCode:@"loadUrl_failed"
                               message:@"Failed parsing the URL"
                               details:[NSString stringWithFormat:@"URL was: '%@'", url]]);
  } else {
    result(nil);
  }
}

- (bool)loadUrl:(NSString*)url {
  NSURL* nsUrl = [NSURL URLWithString:url];
  if (!nsUrl) {
    return false;
  }
  NSURLRequest* req = [NSURLRequest requestWithURL:nsUrl];
  [_webView loadRequest:req];
  return true;
}


- (void)onLoadData:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* data = [call arguments];
    if (![self loadData:data]) {
        result([FlutterError errorWithCode:@"loadData_failed"
                                   message:@"Failed parsing the data"
                                   details:[NSString stringWithFormat:@"data was: '%@'", data]]);
    } else {
        result(nil);
    }
}

- (bool)loadData:(NSString*)data {
   
    [_webView loadHTMLString:data baseURL:nil];
    return true;
}

@end

@implementation SecondStreamHandler
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    eventSinkSecond = eventSink;
  return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    eventSinkSecond = nil;
  return nil;
}
@end
