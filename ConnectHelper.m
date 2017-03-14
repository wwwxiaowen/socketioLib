/*********************************************************************
 * 版权所有   apj_zzz
 *
 * 文件名称： ConnectHelper
 * 内容摘要： 即时通信连接管理类
 * 其它说明： 实现文件
 * 作 成 者： ZGD
 * 完成日期： 2016年07月26日
 * 修改记录1：
 * 修改日期：
 * 修 改 人：
 * 修改内容：
 * 修改记录2：
 **********************************************************************/

#import "ConnectHelper.h"
#import "UserData.h"
#import "UUMessage.h"
#import "Common.h"
#import "BettingOddsView.h"
#import "KLCPopup.h"
#import "Base64.h"
#import "MJExtension.h"
#import "UserWebService.h"

static ConnectHelper *sui;

@implementation ConnectHelper
@synthesize roomSocket;

+ (ConnectHelper *)shareInstence
{
    @synchronized(self) {
        if (!sui)
        {
            sui = [[ConnectHelper alloc] init];
            sui.roomSocket = [[SocketIOClient alloc] initWithSocketURL:[NSURL URLWithString:HC_HOST] config:@{@"log": @YES, @"forcePolling": @YES}];
            
        }
        
        return sui;
    }
}

//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
//{
//    if ([keyPath isEqualToString:@"status"]) {
//        
//        if (sui.roomSocket.status == SocketIOClientStatusConnected && [[UserData getUserData] isLogin]) {
//            NSMutableDictionary *ttDict = [NSMutableDictionary dictionaryWithCapacity:3];
//            [ttDict setObject:[UserData getUserData].userID forKey:@"userID"];
//            [ttDict setObject:[UserData getUserData].nickname forKey:@"nickName"];
//            if ([UserData getUserData].face) {
//                [ttDict setObject:[UserData getUserData].face forKey:@"icon"];
//            }else{
//                [ttDict setObject:@"userDefaultHeader" forKey:@"icon"];
//            }
//            
//            [UserData getUserData].socDict = ttDict;
//            // 登录服务器
//            [[ConnectHelper shareInstence] connectLogin:[UserData getUserData].socDict];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"userStatusNotification" object:nil];
//        }else{
//            [UserData getUserData].serverTime = @"-1";
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"userStatusNotification" object:nil];
//        }
//    }
//}

-(void)updateUserStatus
{
    if (sui.roomSocket.status == SocketIOClientStatusConnected && [[UserData getUserData] isLogin]) {
        NSMutableDictionary *ttDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [ttDict setObject:[UserData getUserData].userID forKey:@"userID"];
        [ttDict setObject:[UserData getUserData].nickname forKey:@"nickName"];
        if ([UserData getUserData].face) {
            [ttDict setObject:[UserData getUserData].face forKey:@"icon"];
        }else{
            [ttDict setObject:@"userDefaultHeader" forKey:@"icon"];
        }
        
        [UserData getUserData].socDict = ttDict;
        // 登录服务器
        [[ConnectHelper shareInstence] connectLogin:[UserData getUserData].socDict];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"userStatusNotification" object:nil];
    }else{
        [UserData getUserData].serverTime = @"-1";
        [[NSNotificationCenter defaultCenter] postNotificationName:@"userStatusNotification" object:nil];
    }
}

// 连接服务器
-(void)connectHost
{
    // 添加监听
//    [self.roomSocket addObserver:self forKeyPath:@"handlers" options:NSKeyValueObservingOptionNew  context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUserStatus) name:@"userStatusChange" object:nil];
    [sui.roomSocket connectWithTimeoutAfter:10 withHandler:^{
        NSLog(@"连接超时");
    }];
    
    [sui.roomSocket on:@"reconnect" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        NSLog(@"重连sock信息:%@",dataArray);
    }];
    
}

// 断开连接
-(void)disconnect
{
    [sui.roomSocket disconnect];
}

// 登录用户到实时通讯
-(void)connectLogin:(NSDictionary *)userInfo
{
    [sui.roomSocket emit:@"connectUser" with:@[userInfo]];
    
    [sui.roomSocket on:@"bettingBack" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        NSLog(@"开奖结果揭晓:%@",dataArray);
        [[NSNotificationCenter defaultCenter] postNotificationName:TimeNoticeUpdate object:nil];
        if (dataArray.count != 0) {
            [self apllyData:dataArray.firstObject];
        }
    }];
    
}


-(void)apllyData:(NSDictionary *)tDict
{
    NSString *baseStr = tDict[@"key"];
    if (baseStr) {
        NSString *jsonStr = [baseStr base64DecodedString];
        NSArray *tmpArray = [Common arrayWithJsonString:jsonStr];
        NSMutableArray *tDataArray = [NSMutableArray arrayWithCapacity:1];
        for (NSDictionary *ttDict in tmpArray) {
            if ([[ttDict objectForKey:@"user_id"] isEqualToString:[UserData getUserData].userID]) {
                [tDataArray addObject:ttDict];
            }
        }
        if (tDataArray.count != 0) {
            BettingOddsView *bodds = [[BettingOddsView alloc]init];
            KLCPopup *pop = [KLCPopup  popupWithContentView:bodds showType:KLCPopupShowTypeFadeIn dismissType:KLCPopupDismissTypeFadeOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
            [pop show];
            [bodds showOddsWithArray:tDataArray];
            [UserWebService getUserInfo:[UserData getUserData].userID blcok:^(id aDict, int errCode) {
                if (errCode == 0) {
                    return ;
                }
                NSString *code = [aDict objectForKey:@"code"];
                if (code.intValue != 1) {
                    return;
                }
                NSDictionary *dataDict = aDict[@"data"];
                NSString *money = [NSString stringWithFormat:@"%@",dataDict[@"money"]];
                [UserData getUserData].money = money;
            }];
        }
    }
    
    
}

// 加入房间
-(void)joinRoomChat:(NSDictionary *)userInfo roomID:(NSString *)roomId
{
    if (userInfo) {
        [sui.roomSocket emit:@"join" with:@[userInfo,roomId]];
    }
    
    // 房间消息监听
    [sui.roomSocket on:@"roomInfo" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        if (self.roomDelegate) {
//            [self.roomDelegate roomSystemTips:dataArray[0]];
            [self.roomDelegate roomMemberList:dataArray[1]];
        }
    }];
    
    // 房间消息监听
    [sui.roomSocket on:@"fromMsg" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        if (self.roomDelegate) {
            [self.roomDelegate roomMessageReceive:dataArray[0]];
        }
    }];
    
    // 投注计时器监听
    [sui.roomSocket on:@"bettingTime" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        if (dataArray.count != 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:TimeCountUpDate object:dataArray.firstObject];
            if (dataArray.firstObject) {
                NSDictionary *tmpDict = dataArray.firstObject;
                [UserData getUserData].serverTime = [NSString stringWithFormat:@"%@",tmpDict[@"serverTime"]];
            }
        }
        
    }];
}

// 离开房间
-(void)leave
{
    [UserData getUserData].bettingStatus = @"-1";
    [sui.roomSocket emit:@"leave" with:@[]];
}

// 发送消息
-(void)sendRoomMessage:(NSDictionary *)msgInfo
{
    [sui.roomSocket emit:@"toMsg" with:@[msgInfo]];
    
    // 发送返回
    [sui.roomSocket on:@"sendBack" callback:^(NSArray * _Nonnull dataArray, SocketAckEmitter * _Nonnull ack) {
        if (self.roomDelegate) {
            NSLog(@"消息发送返回:%@",dataArray);
            if (dataArray.count > 0) {
                NSDictionary *aDict = dataArray.firstObject;
                if (aDict[@"messageId"] ) {
                    [UUMessage messageStatusUpdate:@"1" msgId:aDict[@"messageId"]];
                }
            }
            
        }
    }];
    
}
@end
