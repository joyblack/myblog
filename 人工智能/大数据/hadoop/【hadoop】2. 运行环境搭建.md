
# 简介
通过本教程您可以学习到：
1. 安装jdk
2. 安装单机版本的hadoop

# 1、安装hadoop
集群环境下的安装和单机其实差不多一样，不过麻烦在于对机器的需求量比较大。为了方便，本教程只演示单机的安装。

您需要具备的安装包为hadoop-2.7.2.tar.gz、jdk-8u131-linux-x64.tar.gz。即jdk1.8和hadoop-2.7的tar安装包。

## 1.1 安装JDK
为了统一管理，我们将涉及到的安装包软件都安装到opt目录的module目录下，同时，使用software文件夹存储安装包。

1、opt目录创建两文件夹
```
# cd /opt
# mkdir software
# mkdir module
```

2、在module下安装jdk.
```
# cd /opt/sottware
# tar -zxvf jdk-8u131-linux-x64.tar.gz -C /opt/module
```

3、修改prfile文件，添加环境变量信息
```
vi /etc/profile
```

4、在文件末尾添加内容，保存修改并退出。
```
# JAVA_HOME
export JAVA_HOME=/opt/module/jdk1.8.0_131
export PATH=$PATH:$JAVA_HOME/bin
```
> jdk1.8.0_131是我们解压之后的jdk目录的文件夹名称。第二串是往PAHT路径中添加我们的jdk信息，使用冒号分隔。

4、使修改生效
```
# source /etc/profile
```

## 1.2 安装hadoop
1、安装hadoop的方式和jdk非常相似。回到software文件夹下

2、在module下安装jdk.
```
# cd /opt/sottware
# tar -zxvf hadoop-2.7.2.tar.gz -C /opt/module
```

3、修改prfile文件，添加环境变量信息
```
vi /etc/profile
```

4、在文件末尾添加内容，保存修改并退出。
```
# HADOOP_HOME
export HADOOP_HOME=/opt/module/hadoop-2.7.2
export PATH=$PATH:$HADOOP_HOME/bin
export PATH=$PATH:$HADOOP_HOME/sbin
```
> hadoop-2.7.2是我们解压之后的hadoop目录的文件夹名称。第二串是往PAHT路径中添加我们的hadoop命令的信息，查看hadoop文件夹，我们可以发现bin及sbin两个目录下都有-命令，都将他们添加到环境变量中。

4、使修改生效
```
# source /etc/profile
```
输入hadoop命令查看是否有提示输出，如果没有，可以尝试重启系统。

5、在hadoop环境shell文件中指定JAVA_HOME
* 查看当前JAVA_HOME的具体值并复制此值，将其写到`hadoop-env.sh`中。
```
echo $JAVA_HOME
```
进入hadoop的配置文件中
```
vi /opt/module/hadoop-2.7.2/etc/hadoop/hadoop-env.sh
```
找到配置JAVA_HOME的地方，将其值定为常数路径，也就是我们刚刚通过变量输出的结果。
```
# The java implementation to use.
export JAVA_HOME=/opt/module/jdk1.8.0_131
```
至此，hadoop的安装基本完成了。通过下一节，我们开始尝试在本地安装好的环境下运行一些官方提供的参考案例。

# 参考
1. 尚硅谷官方教学视频。
2. 书籍《hadoop权威指南 第四版》附录B