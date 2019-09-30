# 简介
从本章节您可以学习到：wordcount案例。

# 1、简单实现
## 1.1、Mapper类
``` java
package com.zhaoyi.wordcount;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;
/**
 * 4个参数分别对应指定输入k-v类型以及输出k-v类型
 */
public class WordCountMapper extends Mapper<LongWritable, Text, Text, IntWritable> {

    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        super.map(key, value, context);
        // 1. transport the Text to Java String, this is a line.
        String line = value.toString();
        // 2. split to the line by " "
        String[] words = line.split(" ");
        // 3. output the word-1 key-val to context.
        for (String word:words) {
            // set word as key，number 1 as value
            // 根据单词分发，以便于相同单词会到相同的reducetask中
            context.write(new Text(word), new IntWritable(1));
        }
    }
}
```
Mapper类需要通过继承Mapper类来编写。我们可以查看Mapper的源码：
```java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package org.apache.hadoop.mapreduce;

import java.io.IOException;
import org.apache.hadoop.classification.InterfaceAudience.Public;
import org.apache.hadoop.classification.InterfaceStability.Stable;

@Public
@Stable
public class Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT> {
    public Mapper() {
    }

    protected void setup(Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>.Context context) throws IOException, InterruptedException {
    }

    protected void map(KEYIN key, VALUEIN value, Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>.Context context) throws IOException, InterruptedException {
        context.write(key, value);
    }

    protected void cleanup(Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>.Context context) throws IOException, InterruptedException {
    }

    public void run(Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>.Context context) throws IOException, InterruptedException {
        this.setup(context);

        try {
            while(context.nextKeyValue()) {
                this.map(context.getCurrentKey(), context.getCurrentValue(), context);
            }
        } finally {
            this.cleanup(context);
        }

    }

    public abstract class Context implements MapContext<KEYIN, VALUEIN, KEYOUT, VALUEOUT> {
        public Context() {
        }
    }
}
```

可以看到，他需要我们指定四个形参类型，分别对应Mapper的输入key-val类型以及输出key-val类型。

我们处理的逻辑很简单，单纯的根据空格进行单词划分。当然，严格意义下来说，需要考虑到多个空格的情况，这些逻辑如果您需要的话可以在这里封装实现。

## 1.2、Reducer类
Reducer类和Mapper的模式大致相同，他也需要指定四个形参类型，输入的key-val类型对应Mapper的输出key-val类型。而输出则是Text、IntWritable类型。至于为什么不用我们java自己的封装类型，我们以后会提到，现在有个大致印象即可。
```java
package com.zhaoyi.wordcount;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

/**
 * 输入K-V即为mapper的输出K-V类型，我们要的结果是word-count，因此输出K-V类型是Text-IntWritable
 */
public class WordCountReducer extends Reducer<Text, IntWritable, Text, IntWritable> {
    @Override
    protected void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
        int count = 0;

        // 1.汇总各个key的总数
        for (IntWritable value : values) {
            count += value.get();
        }

        // 2.输出该key的总数
        context.write(key, new IntWritable(count));

    }
}
```
## 1.3、驱动类
该类负责加载Mapper、reducer执行任务。
```java
package com.zhaoyi.wordcount;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class WordCountDriver {
    public static void  main(String[] args) throws Exception {
        // 0.检测参数
        if(args.length != 2){
            System.out.println("Please enter the parameter: data input and output paths...");
            System.exit(-1);
        }
        // 1.根据配置信息创建任务
        Configuration configuration = new Configuration();
        Job job = Job.getInstance(configuration);

        // 2.设置驱动类
        job.setJarByClass(WordCountDriver.class);

        // 3.指定mapper和reducer类
        job.setMapperClass(WordCountMapper.class);
        job.setReducerClass(WordCountReducer.class);

        // 4.设置输出结果的类型(reducer output)
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        // 5.设置输入数据路径和输出数据路径，由程序执行参数指定
        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job,  new Path(args[1]));

        // 6.提交工作
        //job.submit();
        boolean result = job.waitForCompletion(true);

        System.exit(result? 1:0);

    }
}
```

## 1.4、打包
1、进入我们的项目目录，使用maven打包
```
cd word-count
mvn install
```
执行完成后，将会在输出目录得到一个wordcount-1.0-SNAPSHOT.jar文件，将其拷贝到我们的Hadoop服务器上用户目录下。

## 1.5、测试
现在我们在/input目录下（HDFS目录）上传了一个文件，文件内容如下，该文件将会是我们分析的输入对象：
```
this is a test
just a test
Alice was beginning to get very tired of sitting by her sister on the bank
and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' 
So she was considering in her own mind
```
接下来，直接运行我们的任务：
```
[root@h133 ~]# hadoop jar wordcount-1.0-SNAPSHOT.jar com.zhaoyi.wordcount.WordCountDriver /input /output
...
19/01/07 10:21:20 INFO client.RMProxy: Connecting to ResourceManager at h134/192.168.102.134:8032
19/01/07 10:21:22 WARN mapreduce.JobResourceUploader: Hadoop command-line option parsing not performed. Implement the Tool interface and execute your application with ToolRunner to remedy this.
19/01/07 10:21:23 INFO input.FileInputFormat: Total input paths to process : 1
19/01/07 10:21:25 INFO mapreduce.JobSubmitter: number of splits:1
19/01/07 10:21:26 INFO mapreduce.JobSubmitter: Submitting tokens for job: job_1546821218045_0001
19/01/07 10:21:27 INFO impl.YarnClientImpl: Submitted application application_1546821218045_0001
19/01/07 10:21:27 INFO mapreduce.Job: The url to track the job: http://h134:8088/proxy/application_1546821218045_0001/
19/01/07 10:21:27 INFO mapreduce.Job: Running job: job_1546821218045_0001
...

```
> com.zhaoyi.wordcount.WordCountDriver 是我们的驱动类的全路径名，请根据您的实际环境填写。后面的两个参数分别是输入路径和输出路径。

等待执行完成，任务进行的过程也可以通过web界面http://resource_manager:8088查看执行流程。

最后得到我们想要的输出结果：
```
[root@h133 ~]# hadoop fs -cat /output/part-r-00000
Alice	2
So	1
`and	1
`without	1
a	3
and	1
and	1
bank	1
beginning	1
book	1
book,'	1
but	1
by	1
considering	1
conversation?'	1
conversations	1
...
```



