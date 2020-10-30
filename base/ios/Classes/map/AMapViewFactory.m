//
// Created by Yohom Bao on 2018/11/25.
//

#import "AMapViewFactory.h"
#import "MAMapView.h"
#import "MapModels.h"
#import "AMapBasePlugin.h"
#import "UnifiedAssets.h"
#import "MJExtension.h"
#import "NSString+Color.h"
#import "FunctionRegistry.h"
#import "MapHandlers.h"

static NSString *mapChannelName = @"me.yohom/map";
//static NSString *markerClickedChannelName = @"me.yohom/marker_clicked";

static NSString *mapChangeEventChannelName = @"me.yohom/mapview_event";

static NSString *markerEventChannelName = @"me.yohom/marker_event";

@interface MarkerEventHandler : NSObject <FlutterStreamHandler>
@property(nonatomic, strong) FlutterEventSink sink;
@end

@interface MapChangeEventHandler : NSObject <FlutterStreamHandler>
@property(nonatomic, strong) FlutterEventSink sink;
@end

@implementation MarkerEventHandler {
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  _sink = events;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  return nil;
}
@end

@implementation MapChangeEventHandler {
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  _sink = events;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  return nil;
}
@end

@implementation AMapViewFactory {
}

- (NSObject <FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject <FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                     viewIdentifier:(int64_t)viewId
                                          arguments:(id _Nullable)args {
  UnifiedAMapOptions *options = [UnifiedAMapOptions mj_objectWithKeyValues:(NSString *) args];

  AMapView *view = [[AMapView alloc] initWithFrame:frame
                                           options:options
                                    viewIdentifier:viewId];
  return view;
}

@end

@implementation AMapView {
  CGRect _frame;
  int64_t _viewId;
  UnifiedAMapOptions *_options;
  FlutterMethodChannel *_methodChannel;
  FlutterEventChannel *_markerClickedEventChannel;
  FlutterEventChannel *_mapChangeEventChannel;
  MAMapView *_mapView;
  MarkerEventHandler *_eventHandler;
  MapChangeEventHandler *_mapChangeEventHandler;
}

- (instancetype)initWithFrame:(CGRect)frame
                      options:(UnifiedAMapOptions *)options
               viewIdentifier:(int64_t)viewId {
  self = [super init];
  if (self) {
    _frame = frame;
    _viewId = viewId;
    _options = options;

    _mapView = [[MAMapView alloc] initWithFrame:_frame];
    [self setup];
  }
  return self;
}

- (UIView *)view {
  return _mapView;
}

- (void)setup {
  //region 初始化地图配置
  // 尽可能地统一android端的api了, ios这边的配置选项多很多, 后期再观察吧
  // 因为android端的mapType从1开始, 所以这里减去1
  _mapView.mapType = (MAMapType) (_options.mapType - 1);
  _mapView.showsScale = _options.scaleControlsEnabled;
  _mapView.zoomEnabled = _options.zoomGesturesEnabled;
  _mapView.showsCompass = _options.compassEnabled;
  _mapView.scrollEnabled = _options.scrollGesturesEnabled;
  _mapView.cameraDegree = _options.camera.tilt;
  _mapView.rotateEnabled = _options.rotateGesturesEnabled;
  if (_options.camera.target) {
    _mapView.centerCoordinate = [_options.camera.target toCLLocationCoordinate2D];
  }
  _mapView.zoomLevel = _options.camera.zoom;
  // fixme: logo位置设置无效
  CGPoint logoPosition = CGPointMake(0, _mapView.bounds.size.height);
  if (_options.logoPosition == 0) { // 左下角
    logoPosition = CGPointMake(0, _mapView.bounds.size.height);
  } else if (_options.logoPosition == 1) { // 底部中央
    logoPosition = CGPointMake(_mapView.bounds.size.width / 2, _mapView.bounds.size.height);
  } else if (_options.logoPosition == 2) { // 底部右侧
    logoPosition = CGPointMake(_mapView.bounds.size.width, _mapView.bounds.size.height);
  }
  _mapView.logoCenter = logoPosition;
  _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  //endregion

  _methodChannel = [FlutterMethodChannel methodChannelWithName:[NSString stringWithFormat:@"%@%lld", mapChannelName, _viewId]
                                               binaryMessenger:[AMapBasePlugin registrar].messenger];
  __weak __typeof__(self) weakSelf = self;
  [_methodChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
    NSObject <MapMethodHandler> *handler = [MapFunctionRegistry mapMethodHandler][call.method];
    if (handler && weakSelf) {
      __typeof__(self) strongSelf = weakSelf;
      [[handler initWith:strongSelf->_mapView] onMethodCall:call :result];
    } else {
      result(FlutterMethodNotImplemented);
    }
  }];
  _mapView.delegate = weakSelf;

  _eventHandler = [[MarkerEventHandler alloc] init];
  _markerClickedEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", markerEventChannelName, _viewId]
                                                         binaryMessenger:[AMapBasePlugin registrar].messenger];
  [_markerClickedEventChannel setStreamHandler:_eventHandler];
    
  _mapChangeEventHandler = [[MapChangeEventHandler alloc] init];
  _mapChangeEventChannel = [FlutterEventChannel eventChannelWithName:[NSString stringWithFormat:@"%@%lld", mapChangeEventChannelName, _viewId] binaryMessenger:[AMapBasePlugin registrar].messenger];
  
  [_mapChangeEventChannel setStreamHandler:_mapChangeEventHandler];
}

#pragma MAMapViewDelegate

/// 点击annotation回调
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MarkerAnnotation class]]) {
        MarkerAnnotation *annotation = (MarkerAnnotation *) view.annotation;
        NSDictionary *d = @{
                            @"event": @"click",
                            @"options": [annotation.markerOptions mj_JSONString],
                            @"latitude": @(annotation.coordinate.latitude),
                            @"longitude": @(annotation.coordinate.longitude),
                            };
        if (_eventHandler.sink != NULL) {
            _eventHandler.sink([d mj_JSONString]);
        }
    }
}

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view didChangeDragState:(MAAnnotationViewDragState)newState
   fromOldState:(MAAnnotationViewDragState)oldState {
    if ([view.annotation isKindOfClass:[MarkerAnnotation class]]) {
        MarkerAnnotation *annotation = (MarkerAnnotation *) view.annotation;
        NSString *event = @"";
        if (newState == MAAnnotationViewDragStateStarting) {
            event = @"drag_begin";
        } else if (newState == MAAnnotationViewDragStateEnding) {
            event = @"drag_end";
        } else if (newState == MAAnnotationViewDragStateDragging) {
            event = @"drag";
        } else if (newState == MAAnnotationViewDragStateCanceling) {
            event = @"drag_cancel";
        }
        NSDictionary *d = @{
                            @"event": event,
                            @"options": [annotation.markerOptions mj_JSONString],
                            @"latitude": @(annotation.coordinate.latitude),
                            @"longitude": @(annotation.coordinate.longitude),
                            };
        if (_eventHandler.sink != NULL) {
            _eventHandler.sink([d mj_JSONString]);
        }
    }
}

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

/// 渲染overlay回调
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay {
  // 绘制折线
  if ([overlay isKindOfClass:[PolylineOverlay class]]) {
    PolylineOverlay *polyline = (PolylineOverlay *) overlay;

    MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:polyline];

    UnifiedPolylineOptions *options = [polyline options];

    polylineRenderer.lineWidth = (CGFloat) (options.width * 0.5); // 相同的值, Android的线比iOS的粗
    polylineRenderer.strokeColor = [options.color hexStringToColor];
    polylineRenderer.lineJoinType = (MALineJoinType) options.lineJoinType;
    polylineRenderer.lineCapType = (MALineCapType) options.lineCapType;
    if (options.isDottedLine) {
      polylineRenderer.lineDashType = (MALineDashType) ((MALineCapType) options.dottedLineType + 1);
    } else {
      polylineRenderer.lineDashType = kMALineDashTypeNone;
    }

    return polylineRenderer;
  } else if ([overlay isKindOfClass:[CircleOverlay class]]) {
      CircleOverlay *circle = (CircleOverlay *) overlay;
      
      MACircleRenderer *polylineRenderer = [[MACircleRenderer alloc] initWithCircle:circle];
      
      UnifiedCircleOptions *options = [circle options];
      
      polylineRenderer.fillColor = [options.color hexStringToColor];
      
      return polylineRenderer;
  }

  return nil;
}

/// 渲染annotation, 就是Android中的marker
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
  if ([annotation isKindOfClass:[MAUserLocation class]]) {
    return nil;
  }

    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *routePlanningCellIdentifier = @"RoutePlanningCellIdentifier";
        
        MAAnnotationView *annotationView = [_mapView dequeueReusableAnnotationViewWithIdentifier:routePlanningCellIdentifier];
        if (annotationView == nil) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:routePlanningCellIdentifier];
        }
        
        if ([annotation isKindOfClass:[MarkerAnnotation class]]) {
            UnifiedMarkerOptions *options = ((MarkerAnnotation *) annotation).markerOptions;
            annotationView.zIndex = (NSInteger) options.zIndex;
            if (options.icon != nil) {
                annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getAssetPath:options.icon]];
            } else {
                annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/default_marker.png"]];
            }
            //        annotationView.imageView.frame = CGRectMake(0, 0, 20, 23);
            annotationView.centerOffset = CGPointMake(options.anchorU, options.anchorV);
            annotationView.calloutOffset = CGPointMake(options.infoWindowOffsetX, options.infoWindowOffsetY);
            annotationView.draggable = options.draggable;
            annotationView.canShowCallout = options.infoWindowEnable;
            annotationView.enabled = options.enabled;
            annotationView.highlighted = options.highlighted;
            annotationView.selected = options.selected;
            
            UILabel *lbl = [annotationView viewWithTag:100];
            if (lbl == nil && options.content) {
                lbl = [UILabel new];
                lbl.font = [UIFont systemFontOfSize:14];
                //            lbl.textColor = [UIColor redColor];
                lbl.tag = 100;
                [annotationView addSubview:lbl];
                lbl.textAlignment = NSTextAlignmentCenter;
                lbl.textColor = UIColorFromRGB(options.contentColor);
            }
            lbl.text = options.content;
        } else {
            if ([[annotation title] isEqualToString:@"起点"]) {
                annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/amap_start.png"]];
            } else if ([[annotation title] isEqualToString:@"终点"]) {
                annotationView.image = [UIImage imageWithContentsOfFile:[UnifiedAssets getDefaultAssetPath:@"images/amap_end.png"]];
            }
        }
        
        if (annotationView.image != nil) {
            annotationView.centerOffset = CGPointMake(0, -18);
            
            CGSize size = annotationView.imageView.frame.size;
            CGFloat width = 36;
            CGFloat height = 36;
            if ([annotation isKindOfClass:[MarkerAnnotation class]]) {
                UnifiedMarkerOptions *options = ((MarkerAnnotation *) annotation).markerOptions;
                
                if (options.iconSize) {
                    width = options.iconSize.latitude;
                    height = options.iconSize.longitude;
                }
                
                UILabel *lbl = [annotationView viewWithTag:100];
                lbl.frame = CGRectMake(0, 0, options.contentSize.latitude, options.contentSize.longitude);
                
                if (options.offset) {
                    annotationView.centerOffset = CGPointMake(options.offset.latitude, options.offset.longitude);
                }
            } else {
            }
            annotationView.frame = CGRectMake(annotationView.center.x + size.width / 2, annotationView.center.y, width, height); 
        }

    return annotationView;
  }

  return nil;
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MACoordinateRegion region;
    CLLocationCoordinate2D centerCoordinate = mapView.region.center;
    region.center = centerCoordinate;
    
    NSDictionary *d = @{
                        @"latitude": @(centerCoordinate.latitude),
                        @"longitude": @(centerCoordinate.longitude),
                        };
    if (_mapChangeEventHandler.sink != NULL) {
        _mapChangeEventHandler.sink([d mj_JSONString]);
    } else {
        NSLog(@"map change is not listened");
    }
}

@end
