# socketioLib 封装
socketio封装，之前一个项目里面用到的socketio做群聊，运行起来还比较稳定，自己封装了一下socketio，供大家借鉴参考

# 备注
对socketio有一些小的修改

# 使用方法
// 先连接服务器
-(void)connectHost;
// 登录用户到实时通讯
-(void)connectLogin:(NSDictionary *)userInfo;

