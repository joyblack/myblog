0、准备

安装之前请保证正确的配置了HADOOP。

1.解压
```
[root@h133 module]# tar -zxvf sqoop-1.4.7.tar.gz -C ../module/
```

2、设置环境变量
```
export SQOOP_HOME=/opt/module/sqoop-1.4.7
export PATH=$PATH:$SQOOP_HOME/bin
```

3、拷贝jar文件到hadoop yarn lib下
```
[root@h133 sqoop-1.4.7]# cp sqoop-1.4.7.jar ../hadoop-2.7.2/share/hadoop/yarn/
```

4、修改配置文件，去掉一些不必要的组件，例如zoonkeeper
```
[root@h133 sqoop-1.4.7]# sqoop
Warning: /opt/module/sqoop-1.4.7/../hbase does not exist! HBase imports will fail.
....
Try 'sqoop help' for usage.
#### 去除警告
# vi bin/configure-sqoop
# Check: If we can't find our dependencies, give up here.
#if [ ! -d "${HADOOP_COMMON_HOME}" ]; then
#  echo "Error: $HADOOP_COMMON_HOME does not exist!"
#  echo 'Please set $HADOOP_COMMON_HOME to the root of your Hadoop installation.'
#  exit 1
#fi
#if [ ! -d "${HADOOP_MAPRED_HOME}" ]; then
#  echo "Error: $HADOOP_MAPRED_HOME does not exist!"
#  echo 'Please set $HADOOP_MAPRED_HOME to the root of your Hadoop MapReduce installation.'
#  exit 1
#fi

## Moved to be a runtime check in sqoop.
#if [ ! -d "${HBASE_HOME}" ]; then
#  echo "Warning: $HBASE_HOME does not exist! HBase imports will fail."
#  echo 'Please set $HBASE_HOME to the root of your HBase installation.'
#fi

## Moved to be a runtime check in sqoop.
#if [ ! -d "${HCAT_HOME}" ]; then
#  echo "Warning: $HCAT_HOME does not exist! HCatalog jobs will fail."
#  echo 'Please set $HCAT_HOME to the root of your HCatalog installation.'
#fi

#if [ ! -d "${ACCUMULO_HOME}" ]; then
#  echo "Warning: $ACCUMULO_HOME does not exist! Accumulo imports will fail."
#  echo 'Please set $ACCUMULO_HOME to the root of your Accumulo installation.'
#fi
#if [ ! -d "${ZOOKEEPER_HOME}" ]; then
#  echo "Warning: $ZOOKEEPER_HOME does not exist! Accumulo imports will fail."
#  echo 'Please set $ZOOKEEPER_HOME to the root of your Zookeeper installation.'
#fi
```

5、拷贝jdbc驱动程序到sqoop的lib目录
```
[root@h133 software]# cp mysql-connector-java-5.1.45.jar ../module/sqoop-1.4.7/lib/
```

6、测试远程连接
```
#### 列出mysql所有数据库信息
[root@h133 software]# cp mysql-connector-java-5.1.45.jar ../module/sqoop-1.4.7/lib/
[root@h133 software]# sqoop list-databases --connect jdbc:mysql://10.21.11.242:3306/ --username root --password zhaoyi
19/01/08 08:11:52 INFO sqoop.Sqoop: Running Sqoop version: 1.4.7
19/01/08 08:11:52 WARN tool.BaseSqoopTool: Setting your password on the command-line is insecure. Consider using -P instead.
19/01/08 08:11:52 INFO manager.MySQLManager: Preparing to use a MySQL streaming resultset.
information_schema
mysql
performance_schema
sunrun_blog
sunrun_sdfs
```

7、导入数据
```
[root@h133 software]# sqoop import --connect jdbc:mysql://10.21.1.242:3306/sunrun_sdfs --username root --password sunrunvas --table sdfs_web_config -m 1
19/01/09 09:23:39 INFO sqoop.Sqoop: Running Sqoop version: 1.4.7
```
我们导入了远程数据库的sdfs_web_config表。

8、结果
```
1,default_admin_password,sunrunvas,1,新建管理员以及重置用户密码时，用户的默认密码。
2,file_max_history_number,50,1,用户文档历史版本的最大数目，超过此数目遵循队列原则剔除最旧的版本文件。默认值为4，最小值为1
3,user_upfile_size,2048,1,用户上传文件上传的大小限制（0~2048，单位MB）
4,uc_url,https://uc_url,1,uc服务器的URL，选择uc来源时有效
....

```

运行此命令之后本地还会生成一个sdfs_web_config.java文件。

