# 配置

## 1、配置core-site.xml
```xml
<configuration>
    //配置namenode主机和端口
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://h24:9000</value>  
    </property>
    <property>
    //配置hadoop的临时文件目录以及fsimage文件目录，不能放在temp下
        <name>hadoop.tmp.dir</name>
        <value>/opt/module/hadoop-2.7.7/tmp</value>
    </property>
</configuration>
```

## 2、配置hdfs-site.xml  
```xml
<configuration>
    <!-- 配置web访问端口 -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>h24:50070</value>
    </property>
    <!-- 配置备用节点 -->
    <property>
        <name>dfs.namenode.secondary.https-address</name>
        <value>h24:50090</value>
    </property>
</configuration>
```

## 3、配置slavers
```
h24
```

## 4、配置Java_HOME
```
vi hadoop-env.sh
export JAVA_HOME=/opt/module/jdk1.8.0_131
```

## 5、启动
```
hdfs namenode -format
start-hdfs.sh
```