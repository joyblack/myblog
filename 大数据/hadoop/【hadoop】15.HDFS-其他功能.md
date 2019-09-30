# 简介
本章节我们讲讲HDFS的一些其他杂项功能，他们都是作为辅助功能而存在的。

# 1、集群间数据拷贝
我们之间使用scp实现了两个远程主机之间的文件复制，该方式可以实现文件的推拉。
```
scp -r hello.txt root@h133:~/hello.txt		//push
scp -r root@h134:/user/hello.txt  hello.txt //pull
scp -r root@h1333:/user/hello.txt root@h134:/user/   //通过本地主机中转实现两个远程主机的文件复制；如果在两个远程主机之间ssh没有配置的情况下可以使用该方式。
```
我们也可以采用discp命令实现两个hadoop集群之间的递归数据复制
```
bin/hadoop distcp hdfs://h133:9000/user/hello.txt hdfs://h233:9000/user/hello.txt
```
> 我们目前的环境只有一个集群，所以暂时无法演示。

# 2、Hadoop存档
每个文件均按块存储，每个块的元数据存储在namenode的内存中，因此hadoop存储小文件会非常低效。因为大量的小文件会耗尽namenode中的大部分内存。但注意，存储小文件所需要的磁盘容量和存储这些文件原始内容所需要的磁盘空间相比也不会增多。例如，一个1MB的文件以大小为128MB的块存储，使用的是1MB的磁盘空间，而不是128MB。

Hadoop存档文件或HAR文件，是一个更高效的文件存档工具，它将文件存入HDFS块，在减少namenode内存使用的同时，允许对文件进行透明的访问。

这样做的好处：Hadoop存档文件可以用作MapReduce的输入。

1、需要启动yarn进程
```
start-yarn.sh
```

2、归档文件 归档成一个叫做xxx.har的文件夹，该文件夹下有相应的数据文件。Xx.har目录是一个整体，该目录看成是一个归档文件即可。
```
archive -archiveName <NAME>.har -p <parent path> [-r <replication factor>]<src>* <dest>
```
我们练习归档，将/user这个目录进行归档。
```
#### 查看/user中的文件
[root@h135 current]# hadoop fs -ls /user
Found 7 items
-rw-r--r--   3 root supergroup          5 2019-01-03 16:38 /user/444.txt
-rw-r--r--   3 root supergroup         19 2019-01-04 13:24 /user/consisit.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:27 /user/h132.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:28 /user/h133.txt
-rw-r--r--   3 root supergroup         23 2019-01-05 15:11 /user/h134.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:28 /user/h135.txt
drwxr-xr-x   - root supergroup          0 2019-01-03 15:58 /user/zhaoyi

#### 执行归档操作
[root@h135 current]# hadoop archive -archiveName myhar.har -p /user /

#### 查看归档之后目录变化
[root@h135 current]# hadoop fs -ls  /
Found 7 items
-rw-r--r--   3 root supergroup         19 2019-01-05 14:57 /h134.txt
drwxr-xr-x   - root supergroup          0 2019-01-06 10:23 /myhar.har
-rw-r--r--   3 root supergroup         23 2019-01-05 19:07 /newslaver.txt
-rw-r--r--   3 root supergroup          4 2019-01-04 15:50 /seen_txid
drwxr-xr-x   - root supergroup          0 2019-01-05 19:34 /system
drwx------   - root supergroup          0 2019-01-06 10:20 /tmp
drwxr-xr-x   - root supergroup          0 2019-01-05 15:11 /user


#### 查看归档生成的har文件内容
[root@h135 current]# hadoop fs -ls -R /myhar.har
-rw-r--r--   3 root supergroup          0 2019-01-06 10:23 /myhar.har/_SUCCESS
-rw-r--r--   5 root supergroup        699 2019-01-06 10:23 /myhar.har/_index
-rw-r--r--   5 root supergroup         23 2019-01-06 10:23 /myhar.har/_masterindex
-rw-r--r--   3 root supergroup        133 2019-01-06 10:23 /myhar.har/part-0

#### 查看归档文件原文件内容
[root@h135 current]# hadoop fs -ls -R har:///myhar.har
-rw-r--r--   3 root supergroup          5 2019-01-03 16:38 har:///myhar.har/444.txt
-rw-r--r--   3 root supergroup         19 2019-01-04 13:24 har:///myhar.har/consisit.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:27 har:///myhar.har/h132.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:28 har:///myhar.har/h133.txt
-rw-r--r--   3 root supergroup         23 2019-01-05 15:11 har:///myhar.har/h134.txt
-rw-r--r--   3 root supergroup         19 2019-01-03 16:28 har:///myhar.har/h135.txt
drwxr-xr-x   - root supergroup          0 2019-01-03 15:58 har:///myhar.har/zhaoyi
-rw-r--r--   3 root supergroup         29 2019-01-03 15:58 har:///myhar.har/zhaoyi/a.txt
drwxr-xr-x   - root supergroup          0 2019-01-03 15:14 har:///myhar.har/zhaoyi/input

#### 操作归档文件的内容（复制一个文件）
[root@h135 current]# hadoop fs -cp har:///myhar.har/444.txt /
[root@h135 current]# hadoop fs -ls  /
Found 8 items
-rw-r--r--   3 root supergroup          5 2019-01-06 10:27 /444.txt
-rw-r--r--   3 root supergroup         19 2019-01-05 14:57 /h134.txt
drwxr-xr-x   - root supergroup          0 2019-01-06 10:23 /myhar.har
-rw-r--r--   3 root supergroup         23 2019-01-05 19:07 /newslaver.txt
-rw-r--r--   3 root supergroup          4 2019-01-04 15:50 /seen_txid
drwxr-xr-x   - root supergroup          0 2019-01-05 19:34 /system
drwx------   - root supergroup          0 2019-01-06 10:20 /tmp
drwxr-xr-x   - root supergroup          0 2019-01-05 15:11 /user
```
可以看到，归档过程中输出的日志记录表明后台的操作就是由mapreduce完成的，所以我们事先需将yarn相关守护进程开启。

执行归档操作之后，会在/也就是我们归档指定的目录生成har文件，并且原先的归档文件夹还是存在的，可以理解这是一个安全的拷贝操作。归档完成之后，可以按自己的需求决定是否删除原归档文件。

假设我们想要将归档文件“解压”出来（注意这其实和解压不一样），我们可以执行下面的命令，其实就是拷贝操作。
```
[root@h135 current]# hadoop fs -cp har:///myhar.har/* /
```

# 3、快照管理
快照相当于对目录做一个备份。并不会立即复制所有文件，而是指向同一个文件。当写入发生时，才会产生新文件。

快照相关语法:
```
（1）hdfs dfsadmin -allowSnapshot 路径   （功能描述：开启指定目录的快照功能）
（2）hdfs dfsadmin -disallowSnapshot 路径 （功能描述：禁用指定目录的快照功能，默认是禁用）
（3）hdfs dfs -createSnapshot 路径        （功能描述：对目录创建快照）
（4）hdfs dfs -createSnapshot 路径 名称   （功能描述：指定名称创建快照）
（5）hdfs dfs -renameSnapshot 路径 旧名称 新名称 （功能描述：重命名快照）
（6）hdfs lsSnapshottableDir         （功能描述：列出当前用户所有可快照目录）
（7）hdfs snapshotDiff 路径1 路径2 （功能描述：比较两个快照目录的不同之处）
（8）hdfs dfs -deleteSnapshot <path> <snapshotName>  （功能描述：删除快照）
```
我们练习使用一下快照
1、在/目录下创建一个文件夹test，并往里面上传2个文件。
```
[root@h133 current]# hadoop fs -mkdir /test
[root@h133 ~]# hadoop fs -put a.txt /test
[root@h133 ~]# hadoop fs -put b.txt /test
[root@h133 ~]# hadoop fs -ls -R /
drwxr-xr-x   - root supergroup          0 2019-01-06 10:51 /test
-rw-r--r--   3 root supergroup         29 2019-01-06 10:51 /test/a.txt
-rw-r--r--   3 root supergroup         21 2019-01-06 10:51 /test/b.txt
```

2、为test目录创建快照，并重命名为test-snap
```
[root@h133 ~]# hdfs dfsadmin -allowSnapshot /test
Allowing snaphot on /test succeeded
[root@h133 ~]# hdfs dfs -createSnapshot /test test-snap
Created snapshot /test/.snapshot/test-snap
```
> 创建快照之前要开启对应目录的快照开启功能`-allowSnapshot`。

3、查看快照目录
```
[root@h133 ~]# hdfs lsSnapshottableDir 
drwxr-xr-x 0 root supergroup 0 2019-01-06 10:53 1 65536 /test
```

4、上传一个文件到/test，然后查看和快照之间的不同
```
[root@h133 ~]# hadoop fs -put h133.txt /test
[root@h133 ~]# hdfs snapshotDiff /test . .snapshot/test-snap
Difference between current directory and snapshot test-snap under directory /test:
M	.
-	./h133.txt
```
可以看到，显示有所修改，并且快照相比于最新版本的目录少了一个h133.txt文件。

`hdfs snapshotDiff /test . .snapshot/test-snap`中，`.`代表的是当前状态，查看命令说明：
```
hdfs snapshotDiff <snapshotDir> <from> <to>:
	Get the difference between two snapshots, 
	or between a snapshot and the current tree of a directory.
	For <from>/<to>, users can use "." to present the current status,
	and use ".snapshot/snapshot_name" to present a snapshot,
	where ".snapshot/" can be omitted
```
该命令也可以用于不同快照之间的差异性比较。

5、恢复快照文件

如果我们想还原之间的快照版本，HDFS这个版本是没有提供任何命令的，简单的来说，我们可以通过cp命令直接copy快照文件到原路径即可。算是一种恢复快照文件的方案。
```
[root@h133 ~]# hadoop fs -rm -r /test/*
19/01/06 12:51:42 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 0 minutes, Emptier interval = 0 minutes.
Deleted /test/a.txt
19/01/06 12:51:42 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 0 minutes, Emptier interval = 0 minutes.
Deleted /test/b.txt
19/01/06 12:51:42 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 0 minutes, Emptier interval = 0 minutes.
Deleted /test/h133.txt
[root@h133 ~]# hadoop fs -ls /test


[root@h133 ~]# hdfs dfs -cp /test/.snapshot/test-snap/* /test
[root@h133 ~]# hadoop fs -ls /test
Found 2 items
-rw-r--r--   3 root supergroup         29 2019-01-06 12:55 /test/a.txt
-rw-r--r--   3 root supergroup         21 2019-01-06 12:55 /test/b.txt
```
上面的操作中，我们先删除了/test文件夹内的3个文件，然后从快照文件中将快照文件又还原了回来。需要注意的是，我们的rm操作并没有将.snapshoot快照文件删除。

6、删除快照
```
[root@h133 ~]# hdfs dfs -deleteSnapshot /test test-snap

[root@h133 ~]#  hdfs dfs -cp /test/.snapshot/test-snap/* /test
cp: `/test/.snapshot/test-snap/*': No such file or directory
```

7、关闭文件目录的快照功能
```
[root@h133 ~]# hdfs lsSnapshottableDir
drwxr-xr-x 0 root supergroup 0 2019-01-06 12:55 0 65536 /test
[root@h133 ~]# hdfs dfsadmin -disallowSnapshot /test
Disallowing snaphot on /test succeeded
[root@h133 ~]# hdfs lsSnapshottableDir
```
`hdfs dfsadmin -disallowSnapshot /test`关闭之后，别忘了使用命令`hdfs lsSnapshottableDir`查看一下操作的目录是否还在。

# 4、回收站

## 4.1、配置简介
HDFS也有回收站机制，只不过默认情况下是关闭的。

与其相关的配置项主要有以下三个，他们可以从core-site.xml中查询到
```
<property>
  <name>fs.trash.interval</name>
  <value>0</value>
  <description>Number of minutes after which the checkpoint
  gets deleted.  If zero, the trash feature is disabled.
  This option may be configured both on the server and the
  client. If trash is disabled server side then the client
  side configuration is checked. If trash is enabled on the
  server side then the value configured on the server is
  used and the client configuration value is ignored.
  </description>
</property>

<property>
  <name>fs.trash.checkpoint.interval</name>
  <value>0</value>
  <description>Number of minutes between trash checkpoints.
  Should be smaller or equal to fs.trash.interval. If zero,
  the value is set to the value of fs.trash.interval.
  Every time the checkpointer runs it creates a new checkpoint 
  out of current and removes checkpoints created more than 
  fs.trash.interval minutes ago.
  </description>
</property>

<!-- Static Web User Filter properties. -->
<property>
  <description>
    The user name to filter as, on static web filters
    while rendering content. An example use is the HDFS
    web UI (user to be used for browsing files).
  </description>
  <name>hadoop.http.staticuser.user</name>
  <value>dr.who</value>
</property>
```
从描述文档里面我们可以了解到，fs.trash.interval的默认值为0，0表示禁用回收站，可以设置删除文件的存活时间。
注意配置项fs.trash.checkpoint.interval=0，他用于配置检查回收站的间隔时间的值。显然，我们必须保证fs.trash.checkpoint.interval<=fs.trash.interval。

这里我们不配置他，则其值会等于我们配置的文件存活时间（fs.trash.interval）。

如果检查点已经启用，会定期使用时间戳重命名Current目录。.Trash中的文件在用户可配置的时间延迟后被永久删除。回收站中的文件和目录可以简单地通过将它们移动到.Trash目录之外的位置来恢复。

第三个配置项为hadoop.http.staticuser.user，我们修改他的值为root(正常情况下应该是自己的hadoop拥有者账户)。

## 4.2、测试
接下来我们来测试一下回收站功能。

1、启用回收站

往core-site.xml文件中加入如下配置，设置文件的有效时间为1分钟，WEB浏览者权限用户名为root.
```
<property>
    <name>fs.trash.interval</name>
    <value>1</value>
</property>
<property>
  <name>hadoop.http.staticuser.user</name>
  <value>root</value>
</property>
```
> hadoop.http.staticuser.user请配置为您当前系统的HDFS文件拥有者。

2、删除文件
```
[root@h133 ~]# hadoop fs -rm /test/a.txt
19/01/06 13:32:27 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 1 minutes, Emptier interval = 0 minutes.
Moved: 'hdfs://h133:8020/test/a.txt' to trash at: hdfs://h133:8020/user/root/.Trash/Current
```

3、查看回收站
```
drwx------   - root supergroup          0 2019-01-06 13:32 /user/root
[root@h133 ~]# hadoop fs -ls /user/root
Found 1 items
drwx------   - root supergroup          0 2019-01-06 13:32 /user/root/.Trash
```

4、如果通过WEB访问是没办法进入到此目录的，我们重启一下集群
```
[root@h134 current]# stop-yarn.sh

[root@h133 ~]# stop-dfs.sh 

[root@h133 ~]# start-dfs.sh 

[root@h134 current]# start-yarn.sh
```
这时候就可以通过web端进行访问了。

5、恢复回收站数据
通过mv命令可以移动回收站文件到正常的目录，但需要注意的是，文件会在删除后一分钟从回收站中彻底删除。
```
[root@h133 ~]# hadoop fs -rm /test/a.txt
19/01/06 13:45:56 INFO fs.TrashPolicyDefault: Namenode trash configuration: Deletion interval = 1 minutes, Emptier interval = 0 minutes.
Moved: 'hdfs://h133:8020/test/a.txt' to trash at: hdfs://h133:8020/user/root/.Trash/Current
[root@h133 ~]# hadoop fs -mv /user/root/.Trash/Current/a.txt /test
[root@h133 ~]# hadoop fs -mv /user/root/.Trash/190106134600/test/a.txt /test
[root@h133 ~]# hadoop fs -ls /test
Found 1 items
-rw-r--r--   3 root supergroup         29 2019-01-06 13:45 /test/a.txt
```
6、清空回收站
```
hdfs dfs -expunge
```


通过程序删除的文件不会经过回收站，需要调用moveToTrash()才进入回收站
``` java
Trash trash = New Trash(conf);
trash.moveToTrash(path);
```
## 4.3 回收站总结
回收站功能默认是禁用的。对于生产环境，建议启用回收站功能以避免意外的删除操作。启用回收站提供了从用户操作删除或用户意外删除中恢复数据的机会。但是为fs.trash.interval和fs.trash.checkpoint.interval设置合适的值也是非常重要的，以使垃圾回收以你期望的方式运作。例如，如果你需要经常从HDFS上传和删除文件，则可能需要将fs.trash.interval设置为较小的值，否则检查点将占用太多空间。

当启用垃圾回收并删除一些文件时，HDFS容量不会增加，因为文件并未真正删除。HDFS不会回收空间，除非文件从回收站中删除，只有在检查点过期后才会发生。

回收站功能默认只适用于使用Hadoop shell删除的文件和目录。使用其他接口(例如WebHDFS或Java API)以编程的方式删除的文件或目录不会移动到回收站，即使已启用回收站，除非程序已经实现了对回收站功能的调用。

有时你可能想要在删除文件时临时禁用回收站，也就是删除的文件或目录不用放在回收站而直接删除，在这种情况下，可以使用-skipTrash选项运行rm命令。


至此，关于HDFS的学习就完成了，接下来我们学习最有趣也是最核心的功能模块：MapReduce——这关系到我们的应用程序开发。
