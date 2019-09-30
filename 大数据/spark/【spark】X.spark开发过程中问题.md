# 简介

# 1、问题简介
当向HDFS中写入文件时，发生如下的错误，原因是本地用户的账户名不为root。
```
Exception in thread "main" org.apache.hadoop.security.AccessControlException: Permission denied: user=10160, access=WRITE, inode="/":root:supergroup:drwxr-xr-x
```
到Namenode上修改hadoop的配置文件：conf/hdfs-site.xml, 找到 dfs.permissions的配置项 , 将value值改为false：
```xml
<property>
    <name>dfs.permissions</name>
    <value>false</value>
</property>
```
