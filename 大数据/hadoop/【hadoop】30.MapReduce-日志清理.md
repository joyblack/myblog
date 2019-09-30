# 简介
上一节我们讲述了计数器的使用，这一节我们也会运用到相关知识来编写一个应用，他的需求如下：
1. 给定任意的日志文件
2. 筛选日志中自己关心的记录，其他的则全部踢出掉。

代码见log-access模块，统计文件见根目录access.log.

通过本章节您可以学习到：
* MapReduce高级特性：计数器
* 如何自定义计数器
* 日志清理的重要性

## 1、日志清理

## 1、需求分析
大数据项目很多情况下都是针对性的开发，因此我们需要将所谓的"关心记录"进行指定，我们选定一份日志文件，他是一份nginx的访问日志记录，我们查看他的部分内容：
```
...
10.21.21.230 - - [11/Jan/2019:15:31:16 +0800] "POST /japi/v3.0/dfs/fileList/getRootList HTTP/1.1" 200 259 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.1.220 - - [11/Jan/2019:15:37:16 +0800] "POST /japi/v3.0/dfs/user/getHeartForFaith HTTP/1.1" 200 112 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:16 +0800] "POST /japi/v3.0/dfs/preview/getSupportFileExtension HTTP/1.1" 200 201 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/user/getLoginUrl HTTP/1.1" 200 102 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/fileList/getUserFolderFile HTTP/1.1" 200 517 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/fileList/getFilePathArr HTTP/1.1" 200 473 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/webConfig/getWebConfig HTTP/1.1" 200 200 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/webConfig/getWebConfig HTTP/1.1" 200 203 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:17 +0800] "POST /japi/v3.0/dfs/user/getPersonalAvatar HTTP/1.1" 200 13808 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:18 +0800] "POST /japi/v3.0/dfs/user/getHeartForFaith HTTP/1.1" 200 112 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:18 +0800] "POST /japi/v3.0/dfs/preview/getSupportFileExtension HTTP/1.1" 200 201 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:18 +0800] "POST /japi/v3.0/dfs/user/getLoginUrl HTTP/1.1" 200 102 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:18 +0800] "POST /japi/v3.0/dfs/fileList/getChildFileList HTTP/1.1" 200 11730 "-" "-"
10.21.1.220 - - [11/Jan/2019:15:37:18 +0800] "POST /japi/v3.0/dfs/fileList/getFileInfo HTTP/1.1" 200 605 "-" "-"
...
```
该nginx是运行在公司的一台代理服务，进行了反向代理服务。

正常情况下只会接收10.21.1.220发送过来的日志信息，对于其他IP，虽然谈不上非法访问，但是却是我们现在比较关注的对象。现在我们想知道，有没有其他的访问记录存在，访问记录的IP是什么。

基于这个需求，我们需要对该日志进行清理，筛选出我们关心的信息，即除了10.21.1.220之外的其他的访问日志。

> 对日志进行分析可以得到很多意想不到的收获，日志不仅仅只充当排除错误的用途。更多的是进行非法跟踪、业务优化的据点。但一般日志的量都是非常大的，因此，将这些大量的数据转化的过程以及逻辑，是我一项比较重要的必备技能。

# 2、解决方案
我们有两个需求：
1. 找出除了10.21.1.220之外的其他访问日志；
2. 统计正常访问和其他访问的日志数；

针对需求1，我们可以从Mapper阶段进行日志行的过滤，进行字符串检索，满足要求则正常写入，不满足则返回；

而针对需求2，则用到我们之前所讲的计数器知识，在mapper阶段自定义计数器进行技术，最终，从控制台输出日志中，可以得到想要的结果。

# 3、编码
> 为了看到控制台输出，请在类路径下配置log4.properties文件，设置日志级别。

## 3.1、计数器
```java
package com.zhaoyi.logaccess;

// 枚举:正常、不正常
public enum LogCounter {
    NORMAL,ABNORMAL
}
```
## 3.2、应用程序配置
```java
package com.zhaoyi.logaccess;

import java.util.UUID;

public class MyConfig {
    public static final String INPUT_PATH;
    public static final String OUTPUT_PATH;
    // 正常的IP记录
    public static final String NORMAL_IP;

    static {
        INPUT_PATH = "D:/input";
        OUTPUT_PATH = "D:/output" + UUID.randomUUID();
        NORMAL_IP = "10.21.1.220";
    }
}
```

## 3.3、Mapper
```java
package com.zhaoyi.logaccess;

import org.apache.commons.lang.ObjectUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class LogAccessMapper extends Mapper<LongWritable, Text, Text, NullWritable> {
    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        // 判断是否是正常记录，正常记录不予输出，只输出不正常的访问记录
        if(isNormalRecord(value.toString(),context)){
            return;
        }else{
            // 记录下来
            context.write(value, NullWritable.get());
        }
    }

    private boolean isNormalRecord(String record, Context context){
        if(record.startsWith(MyConfig.NORMAL_IP)){
            // 正常记录+1
            context.getCounter(LogCounter.NORMAL).increment(1L);
            return true;
        }else{
            // 不正常记录+1
            context.getCounter(LogCounter.ABNORMAL).increment(1L);
            return false;
        }
    }
}
```
## 3.4、Driver
```java
package com.zhaoyi.logaccess;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.util.UUID;

public class LogAccessDriver {
    public static void main(String[] args) throws Exception {
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(LogAccessDriver.class);
        job.setMapperClass(LogAccessMapper.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NullWritable.class);
        
        FileInputFormat.setInputPaths(job, new Path(MyConfig.INPUT_PATH));
        FileOutputFormat.setOutputPath(job, new Path(MyConfig.OUTPUT_PATH));

        System.exit(job.waitForCompletion(true)? 1:0);
    }
}
```
接下来，我们来查看控制台日志有关计数器的相关记录
``` java
	File System Counters
		FILE: Number of bytes read=162870
		FILE: Number of bytes written=603468
		FILE: Number of read operations=0
		FILE: Number of large read operations=0
		FILE: Number of write operations=0
	Map-Reduce Framework
		Map input records=587
		Map output records=52
		Map output bytes=9642
		Map output materialized bytes=9804
		Input split bytes=90
		Combine input records=0
		Combine output records=0
		Reduce input groups=52
		Reduce shuffle bytes=9804
		Reduce input records=52
		Reduce output records=52
		Spilled Records=104
		Shuffled Maps =1
		Failed Shuffles=0
		Merged Map outputs=1
		GC time elapsed (ms)=6
		Total committed heap usage (bytes)=468713472
	Shuffle Errors
		BAD_ID=0
		CONNECTION=0
		IO_ERROR=0
		WRONG_LENGTH=0
		WRONG_MAP=0
		WRONG_REDUCE=0
    // look here, my friends.
	com.zhaoyi.logaccess.LogCounter
		ABNORMAL=52
		NORMAL=535
	File Input Format Counters 
		Bytes Read=71468
	File Output Format Counters 
		Bytes Written=9674
```
这些都是输出到控制台的计数器信息，其中包括了我们自定义的计数器，见记录中特别注明的部分。可以看到，该计数器的**组名**是我们定义的枚举类型的全路径名，而其中定义的枚举属性，则是具体的计数器的名称。从该信息我们可以了解到：
* 正常的访问记录有535条；
* 不正常的访问记录有52条。

接下来，在查看输出的结果文件，就可以知道到底是那些不正常IP经过了我们的Nginx服务了。例如部分输出如下：
```
...
10.21.21.230 - - [11/Jan/2019:16:30:27 +0800] "POST /japi/v3.0/dfs/fileList/getRootList HTTP/1.1" 200 259 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.21.230 - - [11/Jan/2019:16:30:27 +0800] "POST /japi/v3.0/dfs/storage/getS3ByCondition HTTP/1.1" 200 7714 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.21.230 - - [11/Jan/2019:16:33:25 +0800] "POST /japi/v3.0/dfs/storage/getS3ByCondition HTTP/1.1" 200 7714 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.21.230 - - [11/Jan/2019:16:33:26 +0800] "POST /japi/v3.0/dfs/fileList/getRootList HTTP/1.1" 200 259 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.21.230 - - [11/Jan/2019:16:33:34 +0800] "POST /japi/v3.0/dfs/fileList/getRootList HTTP/1.1" 200 259 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
10.21.21.230 - - [11/Jan/2019:16:33:34 +0800] "POST /japi/v3.0/dfs/storage/getS3ByCondition HTTP/1.1" 200 7714 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
192.168.102.102 - - [11/Jan/2019:14:53:49 +0800] "POST /japi/v3.0/dfs/fileList/getRootList HTTP/1.1" 200 259 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
192.168.102.134 - - [11/Jan/2019:14:53:49 +0800] "POST /japi/v3.0/dfs/storage/getS3ByCondition HTTP/1.1" 200 7714 "-" "Dalvik/2.1.0 (Linux; U; Android 8.0.0; VTR-AL00 Build/HUAWEIVTR-AL00)"
...
```
其中有一个10.21.21.230客户端访问非常频繁，那我们就需要去思考，这个IP是哪里的，合法吗？从而采取更进一步的措施。

这就是筛选日志的重要性。



