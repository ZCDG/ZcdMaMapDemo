//
//  ViewController.m
//  ZcdMaMapDemo
//
//  Created by ZCD on 2017/5/24.
//  Copyright © 2017年 ZCD. All rights reserved.
//

#import "ViewController.h"
#import "AMapLocationKit/AMapLocationKit.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "SelectAroundTableViewCell.h"
#import "MANaviRoute.h"
#import "CommonUtility.h"
#import "RouteCommon.h"
#import "RouteDetailViewController.h"
#import <AMapNaviKit/AMapNaviKit.h>
#import "SpeechSynthesizer.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController () <MAMapViewDelegate,AMapSearchDelegate,AMapLocationManagerDelegate,UISearchBarDelegate,UISearchResultsUpdating,UITableViewDelegate,UITableViewDataSource,AMapNaviDriveViewDelegate,AMapNaviDriveManagerDelegate>
@property(nonatomic,strong)MAMapView *mapView ;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic,strong)AMapSearchAPI *search;//搜索
@property (nonatomic,assign)CLLocationCoordinate2D currentLocation;//当前位置
@property (nonatomic,strong)NSMutableArray *placeArr;//搜索到的所有地方存在该数组
@property(nonatomic,strong)UISearchBar *searchBar;
@property (nonatomic, strong)UITableView *tableView;//搜索出来的tableV
@property (nonatomic,strong)NSMutableArray *searchList;
//路线规划
@property (nonatomic, strong) AMapRoute *route;
/* 当前路线方案索引值. */
@property (nonatomic) NSInteger currentCourse;
/* 路线方案个数. */
@property (nonatomic) NSInteger totalCourse;
/* 用于显示当前路线方案. */
@property (nonatomic) MANaviRoute * naviRoute;
@property (nonatomic, strong) MAPointAnnotation *destinationAnnotation;
@property (nonatomic,retain) NSArray *pathPolylines;
//导航
@property (nonatomic, strong) AMapNaviDriveManager *driveManager;

@property (nonatomic, strong) AMapNaviDriveView *driveView;
@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;
@property (nonatomic, assign) CLLocationCoordinate2D coor;//导航终点位置

@end
static const NSInteger RoutePlanningPaddingEdge                    = 20;
@implementation ViewController
- (NSMutableArray *)searchList
{
    if (!_searchList) {
        _searchList = [NSMutableArray array];
    }
    return _searchList;
}
- (NSArray *)pathPolylines
{
    if (!_pathPolylines) {
        _pathPolylines = [NSArray array];
    }
    return _pathPolylines;
}
//大头针设置
//-(void)viewDidAppear:(BOOL)animated{
//    [super viewDidAppear:animated];
//    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
//    pointAnnotation.coordinate = CLLocationCoordinate2DMake(39.989631, 116.481018);
//    pointAnnotation.title = @"方恒国际";
//    pointAnnotation.subtitle = @"阜通东大街6号";
//    
//    [_mapView addAnnotation:pointAnnotation];
//}
//- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
//{
//    if ([annotation isKindOfClass:[MAPointAnnotation class]])
//    {
//        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
//        MAAnnotationView *annotationView = (MAAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
//        if (annotationView == nil)
//        {
//            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
//                                                          reuseIdentifier:reuseIndetifier];
//        }
//        annotationView.image = [UIImage imageNamed:@"restaurant"];
//        //设置中心点偏移，使得标注底部中间点成为经纬度对应点
//        annotationView.centerOffset = CGPointMake(0, -18);
//        return annotationView;
//    }
//    return nil;
//}
//



- (void)viewDidLoad {
    [super viewDidLoad];
    self.placeArr = [NSMutableArray array];
    //修改右侧navigationBar.backItem
    UIButton *rightButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 44, 44)];
    [rightButton setImage:[UIImage imageNamed:@"list"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(clickRightItem) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
    self.searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0, 7, [UIScreen mainScreen].bounds.size.width, 30)];
    self.searchBar.backgroundColor = [UIColor clearColor];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"请输入目的地";
    self.navigationItem.titleView = self.searchBar;
    ///地图需要v4.5.0及以上版本才必须要打开此选项（v4.5.0以下版本，需要手动配置info.plist）
    [AMapServices sharedServices].enableHTTPS = YES;
    
    ///初始化地图
    _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    
    ///把地图添加至view
    self.view = _mapView;
    
    [self createTableView];

    ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.delegate = self;
    //开启室内地图方法
    self.mapView.showsIndoorMap = YES;    //YES：显示室内地图；NO：不显示；
    _mapView.zoomLevel = 16;
    
    
    //定位
    self.locationManager = [[AMapLocationManager alloc] init];
    self.locationManager.delegate = self;
    //   定位超时时间，最低2s，此处设置为2s
    self.locationManager.locationTimeout =2;
    //   逆地理请求超时时间，最低2s，此处设置为2s
    self.locationManager.reGeocodeTimeout = 2;
    //iOS 9（不包含iOS 9） 之前设置允许后台定位参数，保持不会被系统挂起
    [self.locationManager setPausesLocationUpdatesAutomatically:NO];
    
    //iOS 9（包含iOS 9）之后新特性：将允许出现这种场景，同一app中多个locationmanager：一些只能在前台定位，另一些可在后台定位，并可随时禁止其后台定位。
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    //开始持续定位
    [self.locationManager setLocatingWithReGeocode:YES];
    [self.locationManager startUpdatingLocation];
    //搜索
    //初始化检索对象
    [AMapServices sharedServices].apiKey = @"df652dacb1680d5814b21ff185ecc135";
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;

}
#pragma mark -UISearchBarDelegate
-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    NSLog(@"did begin");
    if (searchBar.text.length > 0) {
        self.tableView.hidden = NO;
        //发起输入提示搜索
        AMapInputTipsSearchRequest *tipsRequest = [[AMapInputTipsSearchRequest alloc] init];
        //关键字
        tipsRequest.keywords = _searchBar.text;
        //城市
        tipsRequest.city = @"福州";
        if (self.tableView.hidden) {
            self.tableView.hidden = NO;
        }
        //执行搜索
        [_search AMapInputTipsSearch : tipsRequest];
    }
}


- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    
    return YES;
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"%@",searchText);
    if (searchText.length > 0) {
        //发起输入提示搜索
        AMapInputTipsSearchRequest *tipsRequest = [[AMapInputTipsSearchRequest alloc] init];
        //关键字
        tipsRequest.keywords = _searchBar.text;
        //城市
        tipsRequest.city = @"福州";
        if (self.tableView.hidden) {
            self.tableView.hidden = NO;
        }
        //执行搜索
        [_search AMapInputTipsSearch : tipsRequest];
    }else
    {
        [self.tableView reloadData];
        self.tableView.hidden = YES;
        [searchBar resignFirstResponder];
        
    }
}

//实现输入提示的回调函数
-(void)onInputTipsSearchDone:(AMapInputTipsSearchRequest*)request response:(AMapInputTipsSearchResponse *)response{
    if(response.tips.count == 0)
    {
        return;
    }
    //通过AMapInputTipsSearchResponse对象处理搜索结果
    //先清空数组
    [self.searchList removeAllObjects];
    for (AMapTip *p in response.tips) {
        //把搜索结果存在数组
        [self.searchList addObject:p];
    }
    if (self.searchList.count > 0) {
        self.tableView.hidden = NO;
    }    NSLog(@"%@",self.searchList);
    //刷新表视图
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}
//接收位置更新
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode
{
    _currentLocation = location.coordinate;
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    if (reGeocode)
    {
        NSLog(@"reGeocode:%@", reGeocode.formattedAddress);
    }
    self.mapView.showsUserLocation = YES;
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(_currentLocation.latitude, _currentLocation.longitude);
    [_mapView setCenterCoordinate:center];
}
//设置跟随箭头
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // 让定位箭头随着方向旋转

    
}
#pragma mark 搜索附近
-(void)startSearchArroundPlace{

    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(_currentLocation.latitude, _currentLocation.longitude);
    [_mapView setCenterCoordinate:center];
    //构造AMapPOIAroundSearchRequest对象，设置周边请求参数
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    //当前位置
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.latitude longitude:_currentLocation.longitude];
    NSLog(@"%f----%f",_currentLocation.latitude,_currentLocation.longitude);
    //关键字
    request.keywords = @"停车场";
    request.types = @"公共设施|生活服务";
    request.radius =  1500;///< 查询半径，范围：0-50000，单位：米 [default = 3000]
    request.sortrule = 0;
    request.requireExtension = YES;
    //发起周边搜索
    [_search AMapPOIAroundSearch:request];
}
//搜索附近返回结果
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    if(response.pois.count == 0)
    {
        return;
    }
    NSLog(@"%@",response);
    for (AMapPOI *p in response.pois) {
        NSDictionary *dataDic = @{@"Address":p.address,@"latitude":[NSString stringWithFormat:@"%f",p.location.latitude],@"longitude":[NSString stringWithFormat:@"%f",p.location.longitude],@"name":p.name};
        if (![self.placeArr containsObject:dataDic]) {
            [self.placeArr addObject:dataDic];
        }
    }
    for (int i = 0 ;i < self.placeArr.count;i++) {
        NSDictionary *dataDic = self.placeArr[i];
        NSLog(@"%@",dataDic[@"name"]);
        MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
        pointAnnotation.coordinate = CLLocationCoordinate2DMake([dataDic[@"latitude"] floatValue], [dataDic[@"longitude"] floatValue]);
        pointAnnotation.title = dataDic[@"name"];
        pointAnnotation.subtitle = dataDic[@"Address"];
        [_mapView addAnnotation:pointAnnotation];
    }

}
- (void)clickRightItem{
    [self startSearchArroundPlace];

}
#pragma mark 设置比例尺
-(void)setScaleShow{
    _mapView.showsScale= YES;  //设置成NO表示不显示比例尺；YES表示显示比例尺
    
    _mapView.scaleOrigin= CGPointMake(_mapView.scaleOrigin.x, 22);  //设置比例尺位置
}
#pragma mark 设置指南针
-(void)setComPass{
    _mapView.showsCompass= YES; // 设置成NO表示关闭指南针；YES表示显示指南针
    
    _mapView.compassOrigin= CGPointMake(_mapView.compassOrigin.x, 22); //设置指南针位置
}
#pragma marak MAMapView.logoCenter 属性来调整Logo的显示位置
-(void)setFrameLogo{
    //MAMapView.logoCenter 属性来调整Logo的显示位置
    _mapView.logoCenter = CGPointMake(CGRectGetWidth(self.view.bounds)-55, 450);
}
#pragma mark 设置地图图层
-(void)setMapType{
    [self.mapView setMapType:MAMapTypeSatellite];
}
#pragma mark 设置精度圈样式
-(void)setLocationRepresentation{
    //自定义定位小蓝点
    MAUserLocationRepresentation *r = [[MAUserLocationRepresentation alloc] init];
    r.showsAccuracyRing = NO;///精度圈是否显示，默认YES
    r.showsHeadingIndicator = NO;///是否显示方向指示(MAUserTrackingModeFollowWithHeading模式开启)。默认为YES
    r.fillColor = [UIColor redColor];///精度圈 填充颜色, 默认 kAccuracyCircleDefaultColor
    r.strokeColor = [UIColor blueColor];///精度圈 边线颜色, 默认 kAccuracyCircleDefaultColor
    r.lineWidth = 2;///精度圈 边线宽度，默认0
    r.locationDotBgColor = [UIColor greenColor];///定位点背景色，不设置默认白色
    r.locationDotFillColor = [UIColor grayColor];///定位点蓝色圆点颜色，不设置默认蓝色
    r.image = [UIImage imageNamed:@"你的图片"]; ///定位图标, 与蓝色原点互斥
    [self.mapView updateUserLocationRepresentation:r];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)createTableView{
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight- 64) style:UITableViewStylePlain];
    [self.tableView registerClass:[SelectAroundTableViewCell class] forCellReuseIdentifier:@"selectAroundTableViewCellLong"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
    self.tableView.hidden = YES;
}
#pragma mark UITableViewDelegate
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SelectAroundTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectAroundTableViewCellLong" forIndexPath:indexPath];
    AMapTip *tip = _searchList[indexPath.row];
    if (tip.address.length < 1) {
        cell.contentLabel.hidden = YES;
        cell.topLabel.frame =  CGRectMake(30, 10, ScreenWidth - 60, 30);
    }else {
        cell.contentLabel.hidden = NO;
        cell.topLabel.frame =  CGRectMake(30, 5, ScreenWidth - 60, 20);
    }
    cell.topLabel.text = tip.name;
    cell.contentLabel.text = tip.address;
    return cell;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
     [_searchBar resignFirstResponder];
    AMapTip *tip = self.searchList[indexPath.row];
    if (tip.address.length < 1) {
        NSLog(@"请选择有详细地址的地点");
        return;
    }
    _coor.longitude = tip.location.longitude;
    _coor.latitude = tip.location.latitude;
    NSLog(@"选中位置的经度%f,选中位置的纬度%f name %@  address %@",tip.location.latitude,tip.location.longitude,tip.name,tip.address);

//    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(tip.location.latitude, tip.location.longitude);
//    [_mapView setCenterCoordinate:center];
//    //添加大头针
//    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
//    pointAnnotation.coordinate = CLLocationCoordinate2DMake(tip.location.latitude, tip.location.longitude);
//    pointAnnotation.title = [NSString stringWithFormat:@"%@",tip.name];
//    pointAnnotation.subtitle = [NSString stringWithFormat:@"%@",tip.address];
//    [_mapView addAnnotation:pointAnnotation];
    [self initDriveView];
    [self initDriveManager];
    [self initProperties];
    [self calculateRoute];
    self.tableView.hidden = YES;

}
//导航
- (void)initDriveView{
    if (self.driveView == nil){
        self.driveView = [[AMapNaviDriveView alloc] initWithFrame:self.view.bounds];
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.driveView setDelegate:self];
        
        [self.view addSubview:self.driveView];
    }
}
//构造 AMapNaviDriveManager 的同时，将 AMapNaviDriveView 添加为导航数据的 Representative，使其可以接收到导航诱导数据。
- (void)initDriveManager
{
    if (self.driveManager == nil)
    {
        self.driveManager = [[AMapNaviDriveManager alloc] init];
        [self.driveManager setDelegate:self];
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        [self.driveManager addDataRepresentative:self.driveView];
    }
}
- (void)initProperties
{
    self.startPoint = [AMapNaviPoint locationWithLatitude:_currentLocation.latitude longitude:_currentLocation.longitude];
    self.endPoint   = [AMapNaviPoint locationWithLatitude:_coor.latitude longitude:_coor.longitude];
}
- (void)calculateRoute{
    //进行路径规划
    [self.driveManager calculateDriveRouteWithStartPoints:@[self.startPoint]
                                                endPoints:@[self.endPoint]
                                                wayPoints:nil
                                          drivingStrategy:17];
    
}
//在路线规划成功的回调函数中，开启实时导航。
- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //算路成功后开始GPS导航
    [self.driveManager startGPSNavi];
}
//语音
- (BOOL)driveManagerIsNaviSoundPlaying:(AMapNaviDriveManager *)driveManager
{
    return [[SpeechSynthesizer sharedSpeechSynthesizer] isSpeaking];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //设置区域的行数(重点),这个就是使用委托之后需要需要判断是一下是否是需要使用Search之后的视图:
    if (self.searchList.count > 0) {
        return self.searchList.count;
    }else{
        return 0;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView*annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
        annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
        annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
        annotationView.pinColor = MAPinAnnotationColorPurple;
        return annotationView;
    }
    return nil;
}
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{
    NSLog(@"%f",     view.annotation.coordinate.latitude);
    self.destinationAnnotation= view.annotation;
    //步行
    AMapWalkingRouteSearchRequest *navi = [[AMapWalkingRouteSearchRequest alloc] init];
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:_currentLocation.latitude
                                           longitude:_currentLocation.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude: view.annotation.coordinate.latitude
                                                longitude: view.annotation.coordinate.longitude];
    [self.search AMapWalkingRouteSearch:navi];
}
/* 路径规划搜索回调. */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response
{
    if (response.route == nil)
    {
        return;
    }
    //通过AMapNavigationSearchResponse对象处理搜索结果
    NSString *route = [NSString stringWithFormat:@"Navi: %@", response.route];
    
    AMapPath *path = response.route.paths[0]; //选择一条路径
    AMapStep *step = path.steps[0]; //这个路径上的导航路段数组
    NSLog(@"%@",step.polyline);   //此路段坐标点字符串
    
    if (response.count > 0)
    {
        //移除地图原本的遮盖
        [_mapView removeOverlays:_pathPolylines];
        _pathPolylines = nil;
        
        // 只显⽰示第⼀条 规划的路径
        _pathPolylines = [self polylinesForPath:response.route.paths[0]];
        NSLog(@"%@",response.route.paths[0]);
        //添加新的遮盖，然后会触发代理方法进行绘制
        [_mapView addOverlays:_pathPolylines];
    }
    //解析response获取路径信息，具体解析见 Demo

}
//路线解析
- (NSArray *)polylinesForPath:(AMapPath *)path
{
    if (path == nil || path.steps.count == 0)
    {
        return nil;
    }
    NSMutableArray *polylines = [NSMutableArray array];
    [path.steps enumerateObjectsUsingBlock:^(AMapStep *step, NSUInteger idx, BOOL *stop) {
        NSUInteger count = 0;
        CLLocationCoordinate2D *coordinates = [self coordinatesForString:step.polyline
                                                         coordinateCount:&count
                                                              parseToken:@";"];
        
        
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
        
        //          MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coordinates count:count];
        
        [polylines addObject:polyline];
        free(coordinates), coordinates = NULL;
    }];
    return polylines;
}
//解析经纬度
- (CLLocationCoordinate2D *)coordinatesForString:(NSString *)string
                                 coordinateCount:(NSUInteger *)coordinateCount
                                      parseToken:(NSString *)token
{
    if (string == nil)
    {
        return NULL;
    }
    
    if (token == nil)
    {
        token = @",";
    }
    
    NSString *str = @"";
    if (![token isEqualToString:@","])
    {
        str = [string stringByReplacingOccurrencesOfString:token withString:@","];
    }
    
    else
    {
        str = [NSString stringWithString:string];
    }
    
    NSArray *components = [str componentsSeparatedByString:@","];
    NSUInteger count = [components count] / 2;
    if (coordinateCount != NULL)
    {
        *coordinateCount = count;
    }
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D*)malloc(count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < count; i++)
    {
        coordinates[i].longitude = [[components objectAtIndex:2 * i]     doubleValue];
        coordinates[i].latitude  = [[components objectAtIndex:2 * i + 1] doubleValue];
    }
    
    
    return coordinates;
}


//绘制遮盖时执行的代理方法
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    /* 自定义定位精度对应的MACircleView. */
    
    //画路线
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        //初始化一个路线类型的view
        MAPolylineRenderer *polygonView = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        //设置线宽颜色等
        polygonView.lineWidth = 8.f;
        polygonView.strokeColor = [UIColor colorWithRed:0.015 green:0.658 blue:0.986 alpha:1.000];
        polygonView.fillColor = [UIColor colorWithRed:0.940 green:0.771 blue:0.143 alpha:0.800];
        polygonView.lineJoinType = kMALineJoinRound;//连接类型
        //返回view，就进行了添加
        return polygonView;
    }
    return nil;
    
}
/* 展示当前路线方案. */
- (void)presentCurrentCourse
{
//    MANaviAnnotationType type = MANaviAnnotationTypeWalking;
    self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentCourse] withNaviType:1 showTraffic:YES startPoint:[AMapGeoPoint locationWithLatitude:_currentLocation.latitude longitude:_currentLocation.longitude] endPoint:[AMapGeoPoint locationWithLatitude:self.destinationAnnotation.coordinate.latitude longitude:self.destinationAnnotation.coordinate.longitude]];
    [self.naviRoute addToMapView:self.mapView];
    
    /* 缩放地图使其适应polylines的展示. */
    [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines]
                        edgePadding:UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge)
                           animated:YES];
//     [self gotoDetailForRoute:self.route type:AMapRoutePlanningTypeWalk];
}
/* 进入详情页面. */
- (void)gotoDetailForRoute:(AMapRoute *)route type:(AMapRoutePlanningType)type
{
    RouteDetailViewController *routeDetailViewController = [[RouteDetailViewController alloc] init];
    routeDetailViewController.route      = route;
    routeDetailViewController.routePlanningType = type;
    
    [self.navigationController pushViewController:routeDetailViewController animated:YES];
}


- (void)updateTotal
{
    self.totalCourse = self.route.paths.count;
}

@end
