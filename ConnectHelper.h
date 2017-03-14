/*********************************************************************
 * 版权所有   apj_zzz
 *
 * 文件名称： ConnectHelper
 * 内容摘要： 即时通信连接管理类
 * 其它说明： 头文件
 * 作 成 者： ZGD
 * 完成日期： 2016年07月26日
 * 修改记录1：
 * 修改日期：
 * 修 改 人：
 * 修改内容：
 * 修改记录2：
 **********************************************************************/

#import <Foundation/Foundation.h>
#import <HotCommunity-Swift.h>

#define HC_HOST @"http://114.215.29.89:3001"

@protocol SocketRoomChatDelegate <NSObject>

@optional
// 用户列表返回
-(void)roomMemberList:(NSArray *)userList;
// 系统消息提示
-(void)roomSystemTips:(NSDictionary *)sysTip;
// 房间消息代理
-(void)roomMessageReceive:(NSDictionary *)message;

@end
@interface ConnectHelper : NSObject
@property (nonatomic,strong) SocketIOClient* roomSocket;
@property (nonatomic,assign) id<SocketRoomChatDelegate> roomDelegate;

+ (ConnectHelper *)shareInstence;

// 连接服务器
-(void)connectHost;
// 登录用户到实时通讯
-(void)connectLogin:(NSDictionary *)userInfo;//id、名字、头像

// 加入房间
-(void)joinRoomChat:(NSDictionary *)userInfo roomID:(NSString *)roomId;
// 离开房间
-(void)leave;

// 断开连接
-(void)disconnect;
// 发送消息
-(void)sendRoomMessage:(NSDictionary *)msgInfo;


@end
