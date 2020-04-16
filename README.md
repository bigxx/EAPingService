#  iOS SimplePing的使用
## 说明
PING （Packet Internet Groper），因特网 包探索器，用于测试网络连接量的程序。Ping是工作在  TCP/IP 网络体系结构中应用层的一个服务命令， 主要是向特定的目的主机发送  ICMP （Internet Control Message Protocol 因特网报文控制协议） Echo  请求报文，测试目的站是否可达及了解其有关状态。
Apple 的 SimplePing 封装了 ping 的功能，提供了简单的 API，以编程的方式对没有管理员权限的远程主机执行 ping 操作，支持 IPv4 和 IPv6。

## 启动Ping
要在自己的项目中使用 SimplePing，需要先下载 [SimplePing](https://developer.apple.com/library/archive/samplecode/SimplePing/Introduction/Intro.html#//apple_ref/doc/uid/DTS10000716) 文件，并添加到项目中。
SimplePing 的使用方法：
	* 通过主机名创建 SimplePing 
	* 指定地址类型
	* 设置代理
	* 开始ping
```
_pinger = [[SimplePing alloc] initWithHostName:self.hostName];
_pinger.addressStyle = SimplePingAddressStyleAny;
_pinger.delegate = self;
[_pinger start];
```

成功开启 ping 后，在代理方法
```
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
```

调用后，发送数据包
```
[_pinger sendPingWithData:nil];
```

调用一次则发送一次数据包，所以为了模拟终端的 ping 效果，需要添加定时器方法调用，添加参数一个*最大发送次数*，判断是否停止 ping。记录下数据包的发送时间，后面计算延迟的时候会用上。
```
- (void)sendPacket {
    if (MaxSendTimes < 1) {
        [self stopPing];
        return;
    }
    // 最大发送数-1
    MaxSendTimes -= 1;
    // 重置ping开始时间
    self.pingModel.sendDate = [NSDate date];
    // 发包数+1
    self.packetCount += 1;
    // 连续丢包数+1
    self.continualLossCount += 1;
    // 发送数据包
    [_pinger sendPingWithData:nil];
    
    // 超时操作
    [self performSelector:@selector(timeoutAction) withObject:nil afterDelay:TimeoutSecond / 1000.0];
}
```

在这里，还做了一个超时处理，大概的逻辑是，发送数据包的时间开始算，超过设定好的超时时间还未收到数据包即算超时。超时后，则中断 ping，输出超时错误。
这里我将超时时间设置为 2 秒，测试中发现高延迟的网站（steam之类的）还是很容易就超时了，导致 ping 终止，体验上并不好，所以添加了一个参数*连续丢包数*。
在代理中，是无法判断是否丢包了，在发送时，我将*连续丢包数*加 1，一旦有收到数据包则重置该参数为 0。一旦超时，先判断是否大于设定的最大*连续丢包数*，是则停止 ping 操作。
```
// MARK:超时
- (void)timeoutAction {
    if (self.continualLossCount < MaxContinualLossCount) {
        return;
    }
    self.pingModel.status = EPingStatusTimeout;
    self.pingModel.delaySec = [self getDelaySeconds];
    [self stopPing];
}
```

## 延迟计算
延迟的计算其实就是：
收到数据包的时间 - 发送数据包的时间 = 延迟（毫秒）

在收到数据包的代理方法中记录下时间
```
- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
```

根据上述逻辑计算出时间差
```
// MARK:获取延迟毫秒
- (NSTimeInterval)getDelaySeconds {
    NSTimeInterval delaySec = 0;
    // 当前时间-开始时间
    self.pingModel.receiveDate = [NSDate date];
    delaySec = [self.pingModel.receiveDate timeIntervalSinceDate:self.pingModel.sendDate] * 1000;
    return delaySec;
}
```

## 丢包率计算
丢包率是指测试中所丢失数据包数量占所发送数据组的比率。计算方法是:“[(输入报文-输出报文)/输入报文]*100%”。丢包率与数据包长度以及包发送频率相关。
每发送一次即算*发包数*，成功收到数据包则将*收包数*加 1。
则通过百科描述得出公式：
（（发包数 - 收包数）/ 发包数）* 100 = 丢包率
```
// 计算丢包率
float lossRate = (self.packetCount - self.receiveCount) / (float)self.packetCount;
if (isnan(lossRate)) {
    lossRate = 0.00;
}
```

