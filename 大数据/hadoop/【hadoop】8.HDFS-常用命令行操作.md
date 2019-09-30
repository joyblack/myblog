# 简介
通过本教程您可以学习到:
1. HDFS命令行语法模式
2. 所有命令列表
3. 常用的命令行操作
4. 命令实际测试及结果

# 1、基本语法
hadoop的hdfs操作基本语法很简单即
```
hadoop fs xxx
```
以hadoop fs引导的命令。

# 2、所有命令列表
有一定linux基础的朋友都知道，要查看一个命令的具体用法，直接通过敲打该命令，系统就会为我们输出该命令的操作文档，例如现在我们查看`hadoop fs`的相关信息：
```shell
[root@h133 ~]# hadoop fs
Usage: hadoop fs [generic options]
	[-appendToFile <localsrc> ... <dst>]
	[-cat [-ignoreCrc] <src> ...]
	[-checksum <src> ...]
	[-chgrp [-R] GROUP PATH...]
	[-chmod [-R] <MODE[,MODE]... | OCTALMODE> PATH...]
	[-chown [-R] [OWNER][:[GROUP]] PATH...]
	[-copyFromLocal [-f] [-p] [-l] <localsrc> ... <dst>]
	[-copyToLocal [-p] [-ignoreCrc] [-crc] <src> ... <localdst>]
	[-count [-q] [-h] <path> ...]
	[-cp [-f] [-p | -p[topax]] <src> ... <dst>]
	[-createSnapshot <snapshotDir> [<snapshotName>]]
	[-deleteSnapshot <snapshotDir> <snapshotName>]
	[-df [-h] [<path> ...]]
	[-du [-s] [-h] <path> ...]
	[-expunge]
	[-find <path> ... <expression> ...]
	[-get [-p] [-ignoreCrc] [-crc] <src> ... <localdst>]
	[-getfacl [-R] <path>]
	[-getfattr [-R] {-n name | -d} [-e en] <path>]
	[-getmerge [-nl] <src> <localdst>]
	[-help [cmd ...]]
	[-ls [-d] [-h] [-R] [<path> ...]]
	[-mkdir [-p] <path> ...]
	[-moveFromLocal <localsrc> ... <dst>]
	[-moveToLocal <src> <localdst>]
	[-mv <src> ... <dst>]
	[-put [-f] [-p] [-l] <localsrc> ... <dst>]
	[-renameSnapshot <snapshotDir> <oldName> <newName>]
	[-rm [-f] [-r|-R] [-skipTrash] <src> ...]
	[-rmdir [--ignore-fail-on-non-empty] <dir> ...]
	[-setfacl [-R] [{-b|-k} {-m|-x <acl_spec>} <path>]|[--set <acl_spec> <path>]]
	[-setfattr {-n name [-v value] | -x name} <path>]
	[-setrep [-R] [-w] <rep> <path> ...]
	[-stat [format] <path> ...]
	[-tail [-f] <file>]
	[-test -[defsz] <path>]
	[-text [-ignoreCrc] <src> ...]
	[-touchz <path> ...]
	[-truncate [-w] <length> <path> ...]
	[-usage [cmd ...]]

Generic options supported are
-conf <configuration file>     specify an application configuration file
-D <property=value>            use value for given property
-fs <local|namenode:port>      specify a namenode
-jt <local|resourcemanager:port>    specify a ResourceManager
-files <comma separated list of files>    specify comma separated files to be copied to the map reduce cluster
-libjars <comma separated list of jars>    specify comma separated jar files to include in the classpath.
-archives <comma separated list of archives>    specify comma separated archives to be unarchived on the compute machines.

The general command line syntax is
bin/hadoop command [genericOptions] [commandOptions]
```

为了查看更详细的信息，直接使用help命令
```
[root@h133 ~]# hadoop fs -help
```
该命令在上一个命令的基础上对每一个参数进行了详细的解释。

# 3、实操命令
1、-help：查看命令具体文档
``` shell
# hadoop fs -help
```

2、-ls：列出目录信息，添加参数`-R`递归列出
```
[root@h133 ~]# hadoop fs -ls /user
Found 1 items
drwxr-xr-x   - root supergroup          0 2019-01-03 02:03 /user/zhaoyi
[root@h133 ~]# hadoop fs -ls -R /user
drwxr-xr-x   - root supergroup          0 2019-01-03 02:03 /user/zhaoyi
drwxr-xr-x   - root supergroup          0 2019-01-03 02:05 /user/zhaoyi/input
-rw-r--r--   3 root supergroup  212046774 2019-01-03 02:05 /user/zhaoyi/input/hadoop-2.7.2.tar.gz
-rw-r--r--   3 root supergroup         17 2019-01-03 02:05 /user/zhaoyi/input/zhaoyi.txt
```

3、-mkdir：创建目录，添加参数-p，递归创建
```
[root@h133 ~]# hadoop fs -mkdir -p /user/yuanyong/test
[root@h133 ~]#  hadoop fs -ls /user
Found 2 items
drwxr-xr-x   - root supergroup          0 2019-01-03 03:36 /user/yuanyong
drwxr-xr-x   - root supergroup          0 2019-01-03 02:03 /user/zhaoyi
```

4、-moveFromLocal：从本地移动到HDFS
```
[root@h133 ~]# touch new.file
[root@h133 ~]# ls
1  anaconda-ks.cfg  new.file
[root@h133 ~]# hadoop fs -moveFromLocal new.file /user/yuanyong/test
[root@h133 ~]# ls
1  anaconda-ks.cfg
[root@h133 ~]# hadoop fs -ls -R /user/yuanyong/test
-rw-r--r--   3 root supergroup          0 2019-01-03 03:40 /user/yuanyong/test/new.file
```
我们在本地创建了一个文件`new.file`，并将其使用命令移动到了`/user/yuanyong/test`路径下。通过本地查看命令和HDFS查看命令可以观察到文件的移动结果。

5、-moveToLocal：从HDFS移动到本地
```
[root@h133 ~]# hadoop fs -moveToLocal /user/yuanyong/test/new.file ./
moveToLocal: Option '-moveToLocal' is not implemented yet.
```
目前还没实现该命令，要实现此需求我们只需下载该文件并在HDFS上删除该文件即可。

6、-appendToFile：追加一个文件到HDFS文件中
```
[root@h133 ~]# touch something.txt
[root@h133 ~]# vi something.txt 
[root@h133 ~]# cat something.txt 
this is append info.
[root@h133 ~]# hadoop fs -appendToFile something.txt /user/yuanyong/test/new.file
[root@h133 ~]# hadoop fs -cat /user/yuanyong/test/new.file
this is append info.
```

6、-cat: 显示文件内容

7、-tail: 显示文件的末尾内容，和linux的tail命令差不多
```
[root@h133 ~]# hadoop fs -tail -f /user/yuanyong/test/new.file
this is append info.
```

8、-chgrp/-chmod/-chown：和linux上的命令一致。

9、-copyFromLocal：和`-moveFromLocal`一样的使用方式，不过是复制。

10、-copyToLocal：和`-moveToLocal`一样的使用方式，不过是复制。只不过该方法可以顺利的运行了。

11、-cp ：从hdfs的一个路径拷贝到hdfs的另一个路径
```
[root@h133 ~]# hadoop fs -cp /user/yuanyong/test/new.file /user
[root@h133 ~]# hadoop fs -cat /user/new.file
this is append info.
```

12、-mv：从hdfs的一个路径移动到hdfs的另一个路径，和-cp使用方式一致。


> 我们不难发现，很多命令都是基于linux命令上的在封装，甚至功能一模一样，我们需要留意的就是语义环境而已。了解本地、HDFS文件系统两个概念即可。

13、-getmerge：合并下载HDFS文件为一个文件到本地（Get all the files in the directories that match the source file pattern and merge and sort them to only one file on local fs.）。
```
[root@h133 ~]# hadoop fs -ls -R /user/zhaoyi/input
-rw-r--r--   3 root supergroup         29 2019-01-03 06:12 /user/zhaoyi/input/a.txt
-rw-r--r--   3 root supergroup         21 2019-01-03 06:12 /user/zhaoyi/input/b.txt
-rw-r--r--   3 root supergroup         24 2019-01-03 06:12 /user/zhaoyi/input/c.txt
[root@h133 ~]# hadoop fs -getmerge /user/zhaoyi/ abc
[root@h133 ~]# hadoop fs -getmerge /user/zhaoyi/input abc
[root@h133 ~]# cat abc 
this is a text file content.
this is b file text.
this is c file content.
```
> 测试之前可以往input目录下多方几个文件，目前我放置了3个文件。合并的时候，我指定合并的文件名为abc。内容随意。

> 如果你指定的是一个目录并在后面写上一个*，则该命令会将该目录下（包括子目录）的所有文件进行合并。

```
[root@h133 ~]# hadoop fs -put c.txt /user/zhaoyi/input/input2
[root@h133 ~]# hadoop fs -getmerge /user/zhaoyi/input/* abc
[root@h133 ~]# cat abc 
this is a text file content.
this is b file text.
this is c file content.
this is c file content.
[root@h133 ~]# hadoop fs -getmerge /user/zhaoyi/input abc
[root@h133 ~]# cat abc 
this is a text file content.
this is b file text.
this is c file content.
```

14、-put：上传文件。

15、-rm：删除文件
```
-rm [-f] [-r|-R] [-skipTrash] <src> ... :
  Delete all files that match the specified file pattern. Equivalent to the Unix
  command "rm <src>"     
  -skipTrash  option bypasses trash, if enabled, and immediately deletes <src>   
  -f          If the file does not exist, do not display a diagnostic message or 
              modify the exit status to reflect an error.                        
  -[rR]       Recursively deletes directories  
```

16、-rmdir：删除空目录

17、-df ：统计文件系统的可用空间信息，和linux命令一致。
```
[root@h133 ~]# hadoop fs -df -h
Filesystem          Size   Used  Available  Use%
hdfs://h133:8020  51.0 G  180 K     44.3 G    0%
```
> -h 命令格式化输出合适的字节单位。


18、-du：统计文件夹的使用信息，和linux命令一致。
```
[root@h133 ~]# hadoop fs -du /
140  /user
```
> 同样可以使用-h命令。

19、-count：统计一个指定目录下文件深度、文件节点个数以及大小。
```
[root@h133 ~]# hadoop fs -count  /user/zhaoyi/input
           2            4                 98 /user/zhaoyi/input
```
20、-setrep：设置hdfs中文件的副本数量
```
[root@h133 ~]# hadoop fs -setrep 2 /user/zhaoyi/input/a.txt
Replication 2 set: /user/zhaoyi/input/a.txt
```
这时候可以通过web端查看这个文件的副本数，已经被设置为2了。

# 参考
本系列的文章参考资料来源有3个地方：
1. 尚硅谷官方大数据教学视频。
2. 书籍《hadoop权威指南 第四版》
3. 官方文档。