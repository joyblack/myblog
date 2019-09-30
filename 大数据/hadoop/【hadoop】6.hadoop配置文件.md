# 简介
通过本教程您可以学习到
1. hadoop配置文件的组成；
2. hadoop配置文件的主要内容。

Hadoop配置文件分两类：
* 默认配置文件
* 自定义配置文件

只有用户想修改某一默认配置值时，才需要修改自定义配置文件，更改相应属性值。

# 1、默认配置文件
（1）默认配置文件：存放在hadoop相应的jar包中。
* hadoop-common-2.7.2.jar/ core-default.xml
* hadoop-hdfs-2.7.2.jar/ hdfs-default.xml
* hadoop-yarn-common-2.7.2.jar/ yarn-default.xml
* hadoop-mapreduce-client-core-2.7.2.jar/ core-default.xml

通过这些配置文件，我们可以了解到各种配置属性的初始值。例如我们之前在core-site.xml中配置的临时目录的路径以及文件存储协议，在`core-site.xml`中可以找到对应的配置项，并且了解到其默认值:
```xml
···
<property>
  <name>hadoop.tmp.dir</name>
  <value>/tmp/hadoop-${user.name}</value>
  <description>A base for other temporary directories.</description>
</property>
···
<!-- file system properties -->
<property>
  <name>fs.defaultFS</name>
  <value>file:///</value>
  <description>The name of the default file system.  A URI whose
  scheme and authority determine the FileSystem implementation.  The
  uri's scheme determines the config property (fs.SCHEME.impl) naming
  the FileSystem implementation class.  The uri's authority is used to
  determine the host, port, etc. for a filesystem.</description>
</property>
···
```
这些文档我们可以手动保存下来，也可以在官网查询到具体的信息，在有需求的同时查看对应的配置项默认值及其描述。

# 2、自定义配置文件
其位置位于`${HADOOP_HOME}/etc`下，也就是我们用来配置一些覆盖默认属性的配置文件，其名字和默认配置文件的名字一一对应一致。


