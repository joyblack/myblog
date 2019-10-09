# 简介
通过本章节您可以学习到
1. hadoop基本开发环境的搭建
2. hadoop常用操作的客户端操作实现。

# 1、环境准备
## 1.1、hadoop jar包安置
1、将hadoop2.7.2.tar.gz解压到指定目录，例如
```
D:/software/hadoop-2.7.2
```
> hadoop2.7.2.tar.gz就是我们一开始在linux解压的编译包。

2、添加win10所需的组件到bin目录(D:/software/hadoop-2.7.2/bin)：将hadoopBin.rar解压，并将里面的7个文件复制到D:/software/hadoop-2.7.2/bin目录。

> 本系列相关的教程都会在章节`【hadoop】1.Hadoop简介`中提供的百度外链下载到。

> 我的是win10环境，所以需要添加以上的组件。

> 如果你的版本不一致，可以从相关网站下载到编译包，至少目前hadoop已经3.x了。

## 1.2、环境变量配置
1、添加HADOOP_HOME变量，值为D:/software/hadoop-2.7.2/；

2、编辑PATH变量，添加新值`%HADOOP_HOME%\bin`

3、进入windows命令行界面，检测是否成功

4、关联集群hosts主机名，修改windows的主机文件
```
C:\Windows\System32\drivers\etc
添加下面3台主机映射
```

5、创建目录`D:\hadoop`，并在内部创建一个test.txt文件，随便写入一些内容。接下来我们的测试就是将这个文件上传到HDFS集群。

> 接下来需要自己创建的测试文件就自己创建测试，这里不作过多说明了。

## 1.3、编写第一个客户端程序
1、使用idea创建一个maven项目

2、配置pom文件，信息如下
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.zhaoyi</groupId>
    <artifactId>firsthadoop</artifactId>
    <version>1.0-SNAPSHOT</version>
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <hadoop.version>2.7.3</hadoop.version>
    </properties>
    <dependencies>
    <!-- 引入hadoop相关依赖 -->
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-client</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-common</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-hdfs</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
    </dependencies>
</project>
```

3、创建类`com.zhaoyi.hdfs.HDFSClient`
``` java
package com.zhaoyi;

import com.google.common.annotations.VisibleForTesting;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.junit.Test;

import java.net.URI;

public class HDFSClient {
    private final static String HADOOP_USER = "root";
    private final static String HDFS_URL = "hdfs://h133:8020";

    public static void main(String[] args) throws Exception {
        // 1、获取配置实体
        final Configuration configuration = new Configuration();
        // 2、获取文件系统
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration,HADOOP_USER);
        // 3、拷贝本地数据到集群
        fileSystem.copyFromLocalFile(new Path("D:/hadoop/test.txt"),new Path("/user/zhaoyi/input"));
        // 4、关闭文件系统
        fileSystem.close();
    }  
}

```
运行该类，就可以发现我们创建的文件上传到了`/user/zhaoyi/input`下。接下来我们就在该类的基础上进行其他的测试。

> FileSystem.get共有3个重载方法，前两个方法提取的默认认证用户名都为当前用户的账户名，因此，如果您不指定用户名，会使用你的当前windows账户去认证，显然是没办法通过的。不过，如果你的HADOOP_USER和WINDOWS_USER一致的话，这里不会有什么问题。推荐使用get的第三个重载方法获取文件系统。


# 2、编写各种测试
## 2.1、查看文件系统实体信息
```java
    @Test
    // 获取文件系统
    public void getFileSystem() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration,HADOOP_USER);
        // print fs info
        System.out.println(fileSystem);
    }
```
输出
```
DFS[DFSClient[clientName=DFSClient_NONMAPREDUCE_-1963602416_1, ugi=root (auth:SIMPLE)]]
```

## 2.2、文件上传
编写测试用例
```java
    @Test
    public void putFileToHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
        // set destination path
        String destinationPath = "/user/yuanyong";
        // uploadFile
        fileSystem.copyFromLocalFile(true, new Path("D:/hadoop/前尘如梦.txt"),new Path(destinationPath) );
        // close fs
        fileSystem.close();
    }
```
我们来查看copyFromLocalFile的源码信息，第一个参数的最终执行：
``` java
return deleteSource ? srcFS.delete(src, true) : true;
```
该参数设置为true，则代表上传完成之后会将源文件给删除，是不是觉得很像move操作。如果您不想让他删除，可以省略此参数，或者设置为false即可。

## 2.3、文件下载
``` java
 @Test
    public void getFileFromHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
        // set download path.
        String downloadPath = "D:/";
//        fileSystem.copyToLocalFile(new Path("/user/new.file"),new Path(downloadPath));
        fileSystem.copyToLocalFile(false,new Path("/user/new.file"),new Path(downloadPath),false);
        fileSystem.close();
    }
```

同样，fileSystem.copyToLocalFile也有3个重载方法，其中第三个重载方法的第一个参数指定是否删除源文件，最后一个参数指定是否执行本地的文件系统校检（默认false），false则会在本地生成一个名为.filename.crc的校检文件，设置为true则不生成

> 关于文件校检：不指定本地校检时，会透明的创建一个.filename.crc的文件。校验文件大小的字节数由io.bytes.per.checksum属性设置，默认是512bytes,即每512字节就生成一个CRC-32校验和。

## 3.4、创建目录
``` java
    @Test
    public void makeDirInHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
        fileSystem.mkdirs(new Path("/user/areya/my/best/love"));
        System.out.println("create dir success.");
        fileSystem.close();
    }
```

> 创建目录默认就是递归方式。

> fileSystem.mkdirs有两个重载方法，另外一个` public boolean mkdirs(Path var1, FsPermission var2)`具体用到再说明。

## 3.5、删除文件
```java
    @Test
    public void deleteInHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
        fileSystem.delete(new Path("/user/areya"),true);
        System.out.println("delete dir success.");
        fileSystem.close();
    }
```
> fileSystem.delete也可只指定一个参数，不过该方法会在今后的版本删除，不推荐使用。

## 3.6、重命名文件
``` java
    @Test
    public void renameInHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
        fileSystem.rename(new Path("/user/yuanyong"),new Path("/user/hongqun"));
        System.out.println("rename dir success.");
        fileSystem.close();
    }
```

## 3.7、查看文件详情
接下来我们将当前测试在HDFS上的所有文件相关信息都打印一遍。
```java
 @Test
    public void getFileInfoInHDFS() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);

        // get all file.
        RemoteIterator<LocatedFileStatus> listFiles = fileSystem.listFiles(new Path("/"), true);

        while (listFiles.hasNext()){
            System.out.println("------------------");
            LocatedFileStatus fileStatus = listFiles.next();

            System.out.println("path: " + fileStatus.getPath());
            System.out.println("group: " + fileStatus.getGroup());
            System.out.println("owner: " + fileStatus.getOwner());
            System.out.println("access time: " + fileStatus.getAccessTime());
            System.out.println("block size: " + fileStatus.getBlockSize());
            System.out.println("length: " + fileStatus.getLen());
            System.out.println("modify time: " + fileStatus.getModificationTime());
            System.out.println("modify time: " + fileStatus.getModificationTime());
            System.out.println("permission: " + fileStatus.getPermission());
            System.out.println("replicate: " + fileStatus.getReplication());
//            System.out.println("symlink: " + fileStatus.getSymlink());

            System.out.println("This file blocks info:");
            BlockLocation[] blockLocations = fileStatus.getBlockLocations();
            for (BlockLocation blockLocation:blockLocations) {
                System.out.println("block length:" + blockLocation.getLength());
                System.out.println("block offsets:" + blockLocation.getOffset());

                System.out.println("block hosts:");
                for (String host : blockLocation.getHosts()) {
                    System.out.println(host);
                }


            }

        }

        System.out.println("-------------");
        System.out.println("print end.");
    }
```

输出结果:
```
path: hdfs://h133:8020/user/hongqun/前尘如梦.txt
group: supergroup
owner: root
access time: 1546474991076
block size: 134217728
length: 20
modify time: 1546474991244
modify time: 1546474991244
permission: rw-r--r--
replicate: 3
This file blocks info:
block length:20
block offsets:0
block hosts:
h133
h135
h134
------------------
path: hdfs://h133:8020/user/hongqun/test/new.file
group: supergroup
owner: root
access time: 1546465187927
block size: 134217728
length: 21
modify time: 1546465174342
modify time: 1546465174342
permission: rw-r--r--
replicate: 3
This file blocks info:
block length:21
block offsets:0
block hosts:
h135
h134
h133
------------------
path: hdfs://h133:8020/user/new.file
group: supergroup
owner: root
access time: 1546477521786
block size: 134217728
length: 21
modify time: 1546465709803
modify time: 1546465709803
permission: rw-r--r--
replicate: 3
This file blocks info:
block length:21
block offsets:0
block hosts:
h133
h134
h135
```
> 从输出结果我们可以了解到listFiles方法只会列出所有的文件（而非文件夹）信息。

## 3.8、获取所有文件（夹）详情
前面我们通过listFiles获取了文件的信息，接下来我们获取某个路径下文件的信息，并输出其中的文件和文件夹类型文件。
``` java
 @Test
    public void getAllFileInfoInHDFS() throws Exception {
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);

        // get dir "/user"'s file.
        FileStatus[] listFiles = fileSystem.listStatus(new Path("/user"));
        for (FileStatus fileStatus:listFiles) {
            if(fileStatus.isDirectory()){
                System.out.println("dir:" + fileStatus.getPath().getName());
            }else if(fileStatus.isFile()){
                System.out.println("file:" + fileStatus.getPath().getName());
            }else if(fileStatus.isEncrypted()){
                System.out.println("cry:" + fileStatus.getPath().getName());
            }else if(fileStatus.isSymlink()){
                System.out.println("symlink:" + fileStatus.getPath().getName());
            }

        }

        System.out.println("-------------");
        System.out.println("print end.");
    }  System.out.println("print end.");
    }
```
输出如下：
```
dir:hongqun
file:new.file
dir:zhaoyi
-------------
print end.
```

> HDFS中可能存在4种类型的文件。

## 3.9、总结
总结一下我们以上的操作共性：
``` java
// 1. 创建配置对象
Configuration configuration = new Configuration();
// 2. 创建文件系统操作对象：设置文件系统URI、配置信息以及HDFS用户名
FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL), configuration, HADOOP_USER);
// 3. 执行操作
fileSystem.xxxx(parameter);
```

# 4、通过IO流的方式操作文件
接下来我们通过IO流方式完成文件的一些常规上传下载操作。重新创建一个客户端类。
## 4.1、上传文件
``` java
package com.zhaoyi;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;
import org.junit.Test;

import java.io.FileInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.net.URI;

public class HDFSIOClient {
    private final static String HADOOP_USER = "root";
    private final static String HDFS_URL = "hdfs://h133:8020";

    @Test
    public void uploadFile() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration, HADOOP_USER);
        // 1. 获取输入流
        FileInputStream fis = new FileInputStream(new File("D:/hadoop/天净沙.txt"));
        // 2. 获取输出流
        FSDataOutputStream fos = fileSystem.create(new Path("/user/天净沙.txt"));
        // 3. 流对接 & 关闭流
        try {
            IOUtils.copyBytes(fis, fos,configuration);
            System.out.println("upload file success.");
        } catch (IOException e) {
            e.printStackTrace();
        }finally {
            fis.close();
            fos.close();
            fileSystem.close();
        }
    }    
}

```
> 输出与输入的参考系是相对于当前内存系统（也可以理解为我们的客户端）而言的。本地文件系统属于输入流，上传的目的地HDFS文件系统则属于输出流。

## 4.2、下载文件
``` java
    @Test
    public void downloadFile() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration, HADOOP_USER);
        // 1. 获取输入流
        FSDataInputStream fis = fileSystem.open(new Path("/user/奥丁的子女.txt"));
        // 2. 获取输出流
        FileOutputStream fos = new FileOutputStream(new File("D:/hadoop/奥丁的子女.txt"));

        // 3. 流对接&关闭流
        try {
            IOUtils.copyBytes(fis, fos,configuration);
            System.out.println("download file success.");
        } catch (IOException e) {
            e.printStackTrace();
        }finally {
            fis.close();
            fos.close();
            fileSystem.close();
        }
    }
```
从这里我们要明白：相对于本地客户端来说，本地文件系统在下载模式下属于输出的对象，因此使用输出流对应；HDFS文件系统属于输入的对象，因此使用输入流，FileSystem的create创建输出流，open方法创建输入流。

## 4.3、定位方式读取文件
还记得我们之前的很大的hadoop安装文件夹吗，接下来我们来定位方式下载该文件。您也可以重新上传一次：
```shell
[root@h133 ~]# hadoop fs -put /opt/software/hadoop-2.7.2.tar.gz /user/
[root@h133 ~]# hadoop fs -ls /user/
Found 6 items
-rw-r--r--   3 root supergroup  212046774 2019-01-03 11:06 /user/hadoop-2.7.2.tar.gz
drwxr-xr-x   - root supergroup          0 2019-01-03 08:23 /user/hongqun
-rw-r--r--   3 root supergroup         21 2019-01-03 05:48 /user/new.file
drwxr-xr-x   - root supergroup          0 2019-01-03 06:11 /user/zhaoyi
-rw-r--r--   3 root supergroup         28 2019-01-03 10:39 /user/天净沙.txt
-rw-r--r--   3 root supergroup        167 2019-01-03 10:50 /user/奥丁的子女.txt
```

接下来我们下载hadoop-2.7.2.tar.gz，分成两部分:第一次下载128M，剩余的放到第二次进行下载。


``` java
    // 进行第一次下载
    @Test
    public void downloadFileBySeek1() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration, HADOOP_USER);
        // part 1. 128M
        // 1. 获取输入流
        FSDataInputStream inputStream = fileSystem.open(new Path("/user/hadoop-2.7.2.tar.gz"));
        // 2. 获取输出流
        FileOutputStream outputStream = new FileOutputStream(new File("D:/hadoop/hadoop-2.7.2.tar.gz.part1"));
        // 3. 流对接(第一部分只需读取128M即可)
        byte[] buff = new byte[1024];
        try {
            for (int i = 0; i < 1024 * 128; i++) {
                inputStream.read(buff);
                outputStream.write(buff);
            }
        } finally {
            IOUtils.closeStream(inputStream);
            IOUtils.closeStream(outputStream);
            IOUtils.closeStream(fileSystem);
        }

    }

        // 进行第一次下载
    @Test
    public void downloadFileBySeek1() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration, HADOOP_USER);
        // part 1. 128M
        // 1. 获取输入流
        FSDataInputStream inputStream = fileSystem.open(new Path("/user/hadoop-2.7.2.tar.gz"));
        // 2. 获取输出流
        FileOutputStream outputStream = new FileOutputStream(new File("D:/hadoop/hadoop-2.7.2.tar.gz.part1"));
        // 3. 流对接(第一部分只需读取128M即可)
        byte[] buff = new byte[1024];
        try {
            for (int i = 0; i < 1024 * 128; i++) {
                inputStream.read(buff);
                outputStream.write(buff);
            }
        } finally {
            IOUtils.closeStream(inputStream);
            IOUtils.closeStream(outputStream);
            IOUtils.closeStream(fileSystem);
        }

    }

    
    // 第二次寻址下载
    @Test
    public void downloadFileBySeek2() throws Exception{
        Configuration configuration = new Configuration();
        FileSystem fileSystem = FileSystem.get(new URI(HDFS_URL),configuration, HADOOP_USER);
        // part 1. 128M
        // 1. 获取输入流
        FSDataInputStream inputStream = fileSystem.open(new Path("/user/hadoop-2.7.2.tar.gz"));
        // 2. 获取输出流
        FileOutputStream outputStream = new FileOutputStream(new File("D:/hadoop/hadoop-2.7.2.tar.gz.part2"));
        // 3. 指向第二块数据地址
        inputStream.seek(1024 * 1024 * 128);
        try {
            IOUtils.copyBytes(inputStream,outputStream,configuration);
        } finally {
            IOUtils.closeStream(inputStream);
            IOUtils.closeStream(outputStream);
            IOUtils.closeStream(fileSystem);
        }

    }

```
分别运行两个测试方法之后，在目录D:/hadoop/下就会生成两个tar.gz.part1和part2的分块文件。接下来运行windows命令行执行追加重定向操作，将两个文件合并为1个。
```shell
type hadoop-2.7.2.tar.gz* > hadoop-2.7.2.tar.gz
```
即可合并我们最初的hadoop压缩包文件，可以通过解压缩或者md5计算验证是否一致。

# 参考
本系列的文章参考资料来源有3个地方：
1. 尚硅谷官方大数据教学视频。
2. 书籍《hadoop权威指南 第四版》
3. 官方文档。

