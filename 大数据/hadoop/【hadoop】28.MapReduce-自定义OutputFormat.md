# 简介
同样的，对应于InputFormat，也可以自定OutFormat。这一节，我们练习自定义的OutputFormat。

## 1、案例
## 1.1、需求
要在一个mapreduce程序中根据数据的不同输出两类结果到不同目录，这类灵活的输出需求可以通过自定义outputformat来实现。
* 自定义outputformat，
* 改写recordwriter，具体改写输出数据的方法write()

见子模块log-filter
## 1.1、输入数据

我们有一个日志文件log.txt
```
灰与幻想的格林姆迦尔
FGO
从零开始的异世界生活
刀剑神域
漫画家的助手
来自风平浪静的明天
来自多彩世界的明天
秦时明月
灰与幻想的格林姆迦尔2
FGO2
从零开始的异世界生活2
刀剑神域2
漫画家的助手2
来自风平浪静的明天2
来自多彩世界的明天2
秦时明月2
愿你的一生风平浪静
```

刷出文件包括两个，一个为包含“风平浪静”的include，另一个则为不包含的exclude文件。



## 2、编写代码
0、写一个静态配置信息类
```java
package com.zhaoyi.logfilter;

public class LogFilterConfig {
    public static final String INPUT_PATH;
    public static final String OUTPUT_PATH;
    // 需要过滤的字符串
    public static final String FILTER_STRING;
    // 包含字符串的日志行存储路径
    public static final String OUTPUTPATH_INC;
    // 不包含字符串的日志行存储路径
    public static final String OUTPUTPATH_EXC;


    static {
        INPUT_PATH = "D:/input";
        OUTPUT_PATH = "D:/output";
        FILTER_STRING = "风平浪静";
        OUTPUTPATH_INC = "D:/output/include";
        OUTPUTPATH_EXC = "D:/output/exclude";

    }
}
```
1、自定义OutputFormat，该Format需要一个writer，我们紧接着定义。
```java
package com.zhaoyi.logfilter;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.JobContext;
import org.apache.hadoop.mapreduce.OutputFormat;
import org.apache.hadoop.mapreduce.RecordWriter;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.Progressable;

import java.io.IOException;

public class MyOutputFormat extends FileOutputFormat<Text, NullWritable> {
    @Override
    public RecordWriter<Text, NullWritable> getRecordWriter(TaskAttemptContext taskAttemptContext) throws IOException, InterruptedException {
        return new MyRecordWriter(taskAttemptContext);

    }
}
```

2、自定义RecordWriter类
```java
package com.zhaoyi.logfilter;

import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.RecordWriter;
import org.apache.hadoop.mapreduce.TaskAttemptContext;

import java.io.IOException;
import java.nio.charset.Charset;

public class MyRecordWriter extends RecordWriter<Text, NullWritable> {
    FSDataOutputStream outputStreamInc = null;
    FSDataOutputStream outputStreamExc = null;
    public MyRecordWriter() {
        super();
    }

    public MyRecordWriter(TaskAttemptContext taskAttemptContext) {
        FileSystem fs = null;
        try {
            fs = FileSystem.get(taskAttemptContext.getConfiguration());
        } catch (IOException e) {
            e.printStackTrace();
        }
        // 设置两个输出路径，分别用输入包含指定信息的文件内容以及其他的内容
        try {
            outputStreamInc = fs.create(new Path(LogFilterConfig.OUTPUTPATH_INC));
            outputStreamExc = fs.create(new Path(LogFilterConfig.OUTPUTPATH_EXC));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }



    @Override
    public void write(Text text, NullWritable nullWritable) throws IOException, InterruptedException {
        String line = text.toString() + "\r\n";
        if(text.toString().contains(LogFilterConfig.FILTER_STRING)){
            outputStreamInc.write(line.getBytes());
        }else{// put in exclude path.
            outputStreamExc.write(line.getBytes());
        }
    }

    @Override
    public void close(TaskAttemptContext taskAttemptContext) throws IOException, InterruptedException {
        try {
            outputStreamInc.close();
            outputStreamExc.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

```
此处输入到文件的时候加了换行符，避免全部挤在一行。还有一点需要注意的是，hadoop Text只以UTF-8的编码方式处理信息，因此，如果需要显示或者用其他编码格式改写字符串相关的参数，请参考相应的处理方式。例如字符串编码转换等。

3、Mapper
```java
package com.zhaoyi.logfilter;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class LogFilterMapper extends Mapper<LongWritable, Text, Text, NullWritable> {
    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        context.write(value, NullWritable.get());
    }
}

```

4、Driver
``` java
package com.zhaoyi.logfilter;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;

import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;
import java.util.UUID;

public class LogFilterDriver {
    public static void main(String[] args) throws Exception {
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(LogFilterDriver.class);
        job.setMapperClass(LogFilterMapper.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NullWritable.class);

        // 设置自定义输出类
        job.setOutputFormatClass(MyOutputFormat.class);

        FileInputFormat.setInputPaths(job, new Path(LogFilterConfig.INPUT_PATH));
        FileOutputFormat.setOutputPath(job, new Path(LogFilterConfig.OUTPUT_PATH + "_" +UUID.randomUUID()));


        System.exit(job.waitForCompletion(true)? 1:0);
    }
}


```

如果输入文件是中文的话，请注意，要对中文进行特别关注，如果是GBK编码的文件，我们需要进行编码转换处理。如果是UTF-8可以不用在意，因为hadoop的框架中使用的就是UTF-8。但是我们中国大部分都是使用的是GBK编码文件，毕竟节省了一个字节的存储空间。下面是用于GBK转换的代码：
```java
String line = new String(text.getBytes(),0,text.getLength(),"GBK");
```
