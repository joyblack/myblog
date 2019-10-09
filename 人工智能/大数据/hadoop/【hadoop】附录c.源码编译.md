# 简介
https://wiki.apache.org/hadoop/Hadoop2OnWindows

从本章节你可以学习到:从官方下载hadoop源码编译为可直接解压使用的压缩包。

# 1、前期准备工作
1、CentOS联网 

2、jar包准备(hadoop源码、JDK7 、 maven、 ant 、protobuf)
* hadoop-2.7.2-src.tar.gz
* jdk-7u79-linux-x64.gz
* apache-ant-1.9.9-bin.tar.gz
* apache-maven-3.0.5-bin.tar.gz
* protobuf-2.5.0.tar.gz

# 2、jar包安装
> 所有操作必须在root用户下完成

1、JDK解压、配置环境变量(JAVA_HOME、PATH)，验证java-version(如下都需要验证是否配置成功)
```shell
[root@hadoop101 software] # tar -zxf jdk-7u79-linux-x64.gz -C /opt/module/
[root@hadoop101 software]# vi /etc/profile
#JAVA_HOME
export JAVA_HOME=/opt/module/jdk1.7.0_79
export PATH=$PATH:$JAVA_HOME/bin
[root@hadoop101 software]# source /etc/profile
```
验证
```
java -version
```
2、Maven解压、配置MAVEN_HOME和PATH。
```
[root@hadoop101 software]# tar -zxvf apache-maven-3.0.5-bin.tar.gz -C /opt/module/
[root@hadoop101 apache-maven-3.0.5]#  vi /etc/profile
#MAVEN_HOME
export MAVEN_HOME=/opt/module/apache-maven-3.0.5
export PATH=$PATH:$MAVEN_HOME/bin
[root@hadoop101 software]#source /etc/profile
```
验证
```
mvn -version
```
3、ant解压、配置  ANT _HOME和PATH。
```
[root@hadoop101 software]# tar -zxvf apache-ant-1.9.9-bin.tar.gz -C /opt/module/
[root@hadoop101 apache-ant-1.9.9]# vi /etc/profile
#ANT_HOME
export ANT_HOME=/opt/module/apache-ant-1.9.9
export PATH=$PATH:$ANT_HOME/bin
[root@hadoop101 software]#source /etc/profile
```
验证
```
ant -version
```
4、安装 glibc-headers 和 g++
```shell
[root@hadoop101 apache-ant-1.9.9]# yum install glibc-header
[root@hadoop101 apache-ant-1.9.9]# yum install gcc-c++
```
5、安装make和cmake
```shell
[root@hadoop101 apache-ant-1.9.9]# yum install make
[root@hadoop101 apache-ant-1.9.9]# yum install cmake
```
6、安装protobuf
```shell
[root@hadoop101 software]# tar -zxvf protobuf-2.5.0.tar.gz -C /opt/module/
[root@hadoop101 opt]# cd /opt/module/protobuf-2.5.0/
[root@hadoop101 protobuf-2.5.0]#./configure 
[root@hadoop101 protobuf-2.5.0]# make 
[root@hadoop101 protobuf-2.5.0]# make check 
[root@hadoop101 protobuf-2.5.0]# make install 
[root@hadoop101 protobuf-2.5.0]# ldconfig 
```
设置环境变量
```
[root@hadoop101 hadoop-dist]# vi /etc/profile
#LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/module/protobuf-2.5.0
export PATH=$PATH:$LD_LIBRARY_PATH
[root@hadoop101 software]# source /etc/profile
```
验证
```
protoc --version
```
7、安装openssl库
``` shell
[root@hadoop101 software]#yum install openssl-devel
8）安装 ncurses-devel库：
[root@hadoop101 software]#yum install ncurses-devel
```
到此，编译工具安装基本完成。

# 3、编译源码
1、创建/opt/tool目录，并下载您需要编译的hadoop版本的源码，此处我是2.7.7版本：
```
# mkdir /opt/tool
# cd /opt/tool
# wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7-src.tar.gz
# tar -xvf hadoop-2.7.7-src.tar.gz
# cd hadoop-2.7.7-src
```

2、通过maven执行编译命令
```
[root@hadoop101 hadoop-2.7.2-src]# mvn package -Pdist,native -DskipTests -Dtar
```
等待时间30分钟左右，最终成功是全部SUCCESS。

4、成功的64位hadoop包在/opt/hadoop-2.7.2-src/hadoop-dist/target下。
```
[root@hadoop101 target]# pwd
/opt/hadoop-2.7.2-src/hadoop-dist/target
```
# 常见的问题及解决方案
1、MAVEN install时候JVM内存溢出

处理方式：在环境配置文件和maven的执行文件均可调整MAVEN_OPT的heap大小。（详情查阅MAVEN 编译 JVM调优问题，[点击前往](http://outofmemory.cn/code-snippet/12652/maven-outofmemoryerror-method)

2、编译期间maven报错。可能网络阻塞问题导致依赖库下载不完整导致，多次执行命令（一次通过比较难）：
```
[root@hadoop101 hadoop-2.7.2-src]#mvn package -Pdist,native -DskipTests -Dtar
```
3、报ant、protobuf等错误，插件下载未完整或者插件版本问题，最开始链接有较多特殊情况，同时推荐网址：
[2.7.0版本的问题汇总帖子](http://www.tuicool.com/articles/IBn63qf)

# 参考
1. 尚硅谷官方教程。



