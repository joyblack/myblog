# 简介
通过本章节您可以学习到如何安装spark standalone模式的环境，使用该模式，我们就无需安装hadoop的环境，直接使用spark运作集群。

# 1、安装过程
1、下载安装包spark-2.4.0-bin-hadoop2.7.tgz。

2、3台机器分别安装java环境，ssh环境，为了方便起见，直接将防火墙关闭（`systemctl stop firewalld`）。
```
192.168.102.131 h131
192.168.102.132 h132
192.168.102.133 h133
```

3、解压安装包到目录
```
# tar -zxvf spark-2.4.0-bin-hadoop2.7.tgz -C /opt/module
```

4、进入到Spark安装配置目录
```
cd /opt/module/spark-2.4.0-bin-hadoop2.7/conf/
```

5、将slaves.template复制为slaves，将其他两台机器作为服役节点
```
h132
h133
```

6、将spark-env.sh.template复制为spark-env.sh，并添加如下配置：
```
SPARK_MASTER_HOST=h131
SPARK_MASTER_PORT=7077
```

7、在sbin目录下的spark-config.sh 文件中加入如下JAVA_HOME环境变量配置
```
# vi /opt/module/spark-2.4.0-bin-hadoop2.7/sbin/spark-config.sh
export JAVA_HOME=/opt/module/jdk1.8.0_131
```

8、将整个spark包拷贝到其他节点上。
```
# scp -r spark-2.4.0-bin-hadoop2.7 root@h132:/opt/module/
# scp -r spark-2.4.0-bin-hadoop2.7 root@h133:/opt/module/
```

9、启动集群
```
# cd sbin
# sh start-all.sh
```
访问master节点的8080端口，如果可以正常访问，则说明安装成功。

# 2、配置hadoop环境
为了方便之后的history server，我们还是需要搭建一套hadoop环境。
```
# sbin/stop-all.sh
```

# 3、配置history server
在此之前先配置好hadoop环境。
```
****** 0、配置环境变量
# vi /etc/profile
export PATH=$PATH:$HADOOP_HOME/bin
export PATH=$PATH:$HADOOP_HOME/sbin

****** 1、配置namenode
# cd /opt/module/hadoop-2.7.7/etc/hadoop
# vi core-site.xml
<!-- 指定HDFS中NameNode的地址 -->
<property>
        <name>fs.defaultFS</name>
        <value>hdfs://h131:8020</value>
</property>
<!-- 指定hadoop运行时产生文件的存储目录 -->
<property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/module/hadoop-2.7.7/data/tmp</value>
</property>

****** 2、配置服役节点
# vi slaves
h131
h132
h133

****** 3、配置hdfs
# vi hdfs-site.xml
<!-- 指定数据节点存储副本数，默认是3，因此可不配置-->
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
<!-- 指定SecondaryNameNode地址-->
<property>
  <name>dfs.namenode.secondary.http-address</name>
  <value>h132:50090</value>
</property>

****** 4、配置yarn
# vi yarn-site.xml
<!-- reducer获取数据的方式 -->
<property>
	<name>yarn.nodemanager.aux-services</name>
	<value>mapreduce_shuffle</value>
</property>
<!-- 指定YARN的ResourceManager的地址 -->
<property>
	<name>yarn.resourcemanager.hostname</name>
	<value>h133</value>
</property>

****** 5、配置mapreduce
# mv mapred-site.xml.template mapred-site.xml
# vi mapred-site.xml
<!-- 指定mr运行在yarn上 -->
<property>
  <name>mapreduce.framework.name</name>
  <value>yarn</value>
</property>

****** 5、将JAVA_HOME信息写入各个环境脚本文件中
# vi hadoop-env.sh
# vi yarn-env.sh
# vi mapred-env.sh
export JAVA_HOME=/opt/module/jdk1.8.0_131

****** 6、将整个hadoop包分发到集群
# cd /opt/module
# scp -r hadoop-2.7.7 root@h132:/opt/module/
# scp -r hadoop-2.7.7 root@h133:/opt/module/

****** 7、在我们指定的namenode主机上格式化节点
# hdfs namenode -format

****** 8、h131上启动hdfs
# start-dfs.sh

****** 9、h133上启动yarn
# start-yarn.sh
```
验证正确，访问50070端口查看是否OK。

1、进入配置目录
```
# cd /opt/module/spark-2.4.0-bin-hadoop2.7/conf
```

2、spark-default.conf.template复制为spark-default.conf，并开启Log（去掉注释，并修改主机名）：
```
# mv spark-defaults.conf.template spark-defaults.conf
# vi spark-defaults.conf
spark.master                     spark://h131:7077
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://h131:8020/directory
```
> 在HDFS上创建好你所指定的eventLog日志目录:`hadoop fs -mkdir /directory`。

3、修改spark-env.sh文件，添加如下配置
```
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=4000 -Dspark.history.retainedApplications=3 -Dspark.history.fs.logDirectory=hdfs://master01:8020/directory"
```

4、启动spark集群
```
# ./sbin/start-all.sh
```

5、启动history server
```
# ./sbin/start-history-server.sh
```
访问h131的4000端口，查看是否可以访问。


