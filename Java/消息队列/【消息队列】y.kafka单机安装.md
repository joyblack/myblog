# 简介
要配置kafka，首先要配置zookeeper保证集群的高可用。因此本教程包含两者的配置。

http://kafka.apache.org/

1、下载kafka:https://www.apache.org/dyn/closer.cgi?path=/kafka/2.1.0/kafka_2.11-2.1.0.tgz

2、下载zookeoper：http://mirror.bit.edu.cn/apache/zookeeper/

> 百度云盘也放的有一份哦。

# 0、准备工作
1、目前配置是单机环境。

2、配置好本机的SSH无秘钥登录（虽然不是必须，但是作为集群间更好的管理，这是必要的步骤）

3、关闭防火墙。当然，为了安全起见，最好还是不要偷懒，应该针对性的开启需要开启的端口。

4、配置java jdk环境。


# 1、安装zookeeper
1、解压安装包并复制zoo.cfg模板文件为zoo.cfg
```
# cd /opt/module/zookeeper-3.4.10/conf
# cp zoo_sample.cfg zoo.cfg
```

2、配置zoo.cfg
```
# vi zoo.cfg
```
zoo.cfg配置如下：
```
#心跳间隔
tickTime=2000
#其他服务器连接到Leader时，最长能忍受的心跳间隔数：10*2000 = 20秒
initLimit=10
#发送消息时，多长忍受心跳间隔数：5*2000 = 10秒
syncLimit=5
#快照日志
dataDir=/opt/module/zookeeper-3.4.10/zkdata
#事务日志
dataLogDir=/opt/module/zookeeper-3.4.10/zkdatalog
#客户端连接zookeeper服务器的端口
clientPort=2181
```
3、启动服务
```
# ./bin/zkServer.sh start
```

4、查看状态
```
[root@h24 bin]# sh zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /opt/module/zookeeper-3.4.10/bin/../conf/zoo.cfg
Mode: standalone

[root@h24 bin]# jps
1892 NameNode
2025 DataNode
7723 Jps
2207 SecondaryNameNode
7631 QuorumPeerMain(zookeeper线程)
```

X、其他命令
```
*** 停止服务
# bin/zkServer.sh stop 
```

# 2、配置kafka
1、解压kafka。

2、修改conf/server.properties，放开注释项，添加自己的IP地址，方便别的机器访问：
```
listeners=PLAINTEXT://10.21.1.24:9092
```
3、直接启动服务
```
bin/kafka-server-start.sh -daemon ./config/server.properties
```

> 如果正常的话，则应该不会有任何输出信息；如果不正常，可查看详细日志文件：`tail -fn 100 logs/server.log`

4、查看服务
```
[root@h24 kafka_2.12-2.1.0]# jps
8097 Kafka(kafka服务进程)
8179 Jps
1892 NameNode
2025 DataNode
2207 SecondaryNameNode
7631 QuorumPeerMain
```

# 3、测试kafka
1、创建话题，例如创建一个名为`zhaoyi`的话题（指定分区为1）：
```
[root@h24 kafka_2.12-2.1.0]# bin/kafka-topics.sh --create --zookeeper h24:2181 --replication-factor 1 --partitions 1 --topic zhaoyi
Created topic "zhaoyi".
```

2、查看所有分区
```
[root@h24 bin]# ./kafka-topics.sh --zookeeper h24 --list
zhaoyi
```

3、启动一个生产者(通过控制台)，往topic队列（zhaoyi）中写入数据
```
[root@h24 bin]# ./kafka-console-producer.sh --broker-list h24:2181 --topic zhaoyi
>
```

4、（3）执行之后进入一个等待输入命令行，即需要我们输入消息。这时候，我们再开启一个新的ssh通道，在该机器上启动一个消费者（通过控制台）。
```
[root@h24 bin]# ./kafka-console-consumer.sh --bootstrap-server h24:9092 --topic zhaoyi
(空行)
```
执行该命令之后，控制台处于阻塞状态，因为他已经进入了监听模式，监听zhaoyi话题的任何产出信息。

（5）回到创建生产者的机器上，往等待命令行输入任何消息，敲击回车
```
>I love you, deer!
>
```

（6）这时候我们观察进入阻塞模式的消费者控制台，可以看到接收到了信息：
```
I love you, deer!
```

至此，配置结束。

X、其他命令
```
*** 停止服务
# bin/kafka-server-stop.sh

*** 查看某个topic的消息
# bin/kafka-topics.sh --zookeeper h24:2181 --describe --topic zhaoyi
```