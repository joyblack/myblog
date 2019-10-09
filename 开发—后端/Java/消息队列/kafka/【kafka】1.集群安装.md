# 简介
要配置kafka，首先要配置zookeeper保证集群的高可用。因此本教程包含两者的配置。

1、下载kafka:https://www.apache.org/dyn/closer.cgi?path=/kafka/2.1.0/kafka_2.11-2.1.0.tgz

2、下载zookeoper：http://mirror.bit.edu.cn/apache/zookeeper/

# 0、准备工作
1、目前配置三台机器的集群，配置好hosts文件:
```
192.168.102.131 h131
192.168.102.132 h132
192.168.102.133 h133
```

2、配置好三台机器间的SSH无秘钥登录（虽然不是必须，但是作为集群间更好的管理，这是必要的步骤）

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
#可以待后续克隆完剩下两台后，再写上其他两台的ip
server.1=192.168.102.131:2888:3888
server.2=192.168.102.132:2888:3888
server.3=192.168.102.133:2888:3888
```

3、分发到zookeeper到其他两台机器
```
# scp -r zookeeper-3.4.10/ root@h132:/opt/module/
# scp -r zookeeper-3.4.10/ root@h133:/opt/module/
```

4、在三台机器上的dataDir目录/data/zookeeper/下写一个myid文件，对应zoo.cfg里的server.1、server.2、server.3
```
*** server1、2和3
# cd /opt/module/zookeeper-3.4.10/
# mkdir zkdata
# mkdir zkdatalog

*** server1
# echo "1" > /opt/module/zookeeper-3.4.10/zkdata/myid

*** server2
# echo "2" > /opt/module/zookeeper-3.4.10/zkdata/myid

*** server3
# echo "3" > /opt/module/zookeeper-3.4.10/zkdata/myid
```

5、启动各台服务
```
# ./bin/zkServer.sh start
```

6、查看状态
```
# /bin/zkServer.sh status
2 follower, 1 leader.
```

X、其他命令
```
*** 停止服务
# bin/zkServer.sh stop 
```

# 2、配置kafka
1、解压kafka。

2、进入安装目录修改配置文件
```
# cd /opt/module/kafka_2.12-2.1.0/config
# vi server.properties
```
server.properties的配置信息如下，注意每台机器略微不同，详情见注释
```
# 三台机器分别是1，2以及3
broker.id=1
# 对应自身ip
listeners=PLAINTEXT://192.168.102.131:9092
# 对应自身ip
advertised.listeners=PLAINTEXT://192.168.102.131:9092
# zookeeper集群地址
zookeeper.connect=192.168.102.131:2181,192.168.102.132:2181,192.168.102.133:2181
```

3、将安装包分发到其他两台机器
```
# scp -r kafka_2.12-2.1.0/ root@h132:/opt/module/
# scp -r kafka_2.12-2.1.0/ root@h133:/opt/module/
```

4、修改各自的IP配置：broker.id、listeners以及advertised。
```
# vi server.properties
```
具体见第2步中的注释，例如，第二台机器的配置应该是这样
```
# 三台机器分别是1，2以及3
broker.id=2
# 对应自身ip
listeners=PLAINTEXT://192.168.102.132:9092
# 对应自身ip
advertised.listeners=PLAINTEXT://192.168.102.132:9092
# zookeeper集群地址
zookeeper.connect=192.168.102.131:2181,192.168.102.132:2181,192.168.102.133:2181
```

5、启动集群
```
bin/kafka-server-start.sh -daemon ./config/server.properties
```

> 如果正常的话，则应该不会有任何输出信息；如果不正常，可查看详细日志文件：`tail -fn 100 logs/server.log`


6、测试集群

（1）任意一台机器上创建话题，例如创建一个名为`zhaoyi`的话题（指定分区为2）：
```
# bin/kafka-topics.sh --create --zookeeper 192.168.102.131:2181,192.168.102.132:2181,192.168.102.133:2181 --replication-factor 2 --partitions 2 --topic zhaoyi
```
得到如下的输出
```
Created topic "zhaoyi".
```

（2）查看所有分区
```
# bin/kafka-topics.sh --zookeeper 192.168.102.131:2181 --list
```
得到如下的输出
```
__consumer_offsets
zhaoyi
```

（3）启动一个生产者(通过控制台)，往topic队列（zhaoyi）中写入数据，例如，我们在192.168.102.133上执行：
```
# bin/kafka-console-producer.sh --broker-list 192.168.102.131:9092,192.168.102.132:9092,192.168.102.132:9092 --topic zhaoyi
>
```

(4) （3）执行之后进入一个等待输入命令行，即需要我们输入消息。这时候，我们再从另一台机器，例如192.168.102.132上启动一个消费者（通过控制台）。)
```
bin/kafka-console-consumer.sh --bootstrap-server 192.168.102.131:9092,192.168.102.132:9092,192.168.102.133:9092 --topic zhaoyi
```
执行该命令之后，控制台处于阻塞状态，因为他已经进入了监听模式，监听zhaoyi话题的任何产出信息。

（5）回到创建生产者的机器上，往等待命令行输入任何消息，敲击回车
```
>I love you, deer!
>
```

（6）这时候我们观察进入阻塞模式的消费者控制台，即192.168.102.132服务器，可以看到接收到了信息：
```
I love you, deer!
```

至此，配置结束。

X、其他命令
```
*** 停止服务
# bin/kafka-server-stop.sh

*** 查看某个topic的消息
# bin/kafka-topics.sh --zookeeper 192.168.102.131:2181 --describe --topic zhaoyi
```