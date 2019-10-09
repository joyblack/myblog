# 简介
无论hdfs还是mapreduce，对于小文件都有损效率，实践中，又难免面临处理大量小文件的场景，此时，就需要有相应解决方案。将多个小文件合并成一个文件SequenceFile，SequenceFile里面存储着多个文件，存储的形式为“文件路径+名称”为key，文件内容为value。

小文件的优化无非以下几种方式：
* 在数据采集的时候，就将小文件或小批数据合成大文件再上传HDFS
* 在业务处理之前，在HDFS上使用mapreduce程序对小文件进行合并
* 在mapreduce处理时，可采用CombineTextInputFormat提高效率

本节我们实现使用如下方法：
* 自定义一个InputFormat
* 改写RecordReader，实现一次读取一个完整文件封装为KV
* 在输出时使用SequenceFileOutPutFormat输出合并文件

## 1、案例
## 1.1、输入数据
我们来处理3个文件
D:/a.txt
```
a poor guy.
```

D:/b.txt
```
boss will come here, hurry up.
```

D:/c.txt
```
can I sit there?
```

最终生成一个SequenceFile文件，内容不适合浏览（有乱码）。

## 2、编写代码
代码见模块smallfile。

1、自定义InputFormat，该Format需要一个Reader，我们紧接着定义。
```java
package com.zhaoyi.smallfile;

import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.JobContext;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;


import java.io.IOException;

public class MyInputFormat extends FileInputFormat<NullWritable, BytesWritable> {
    // 任何大小都不分片
    @Override
    protected boolean isSplitable(JobContext context, Path filename) {
        return false;
    }

    @Override
    public RecordReader<NullWritable, BytesWritable> createRecordReader(InputSplit inputSplit, TaskAttemptContext taskAttemptContext) throws IOException, InterruptedException {
        MyRecordReader reader = new MyRecordReader();
        // 初始化reader
        reader.initialize(inputSplit, taskAttemptContext);

        return reader;
    }
}

```

2、自定义RecordReader类
```java
package com.zhaoyi.smallfile;

import javafx.util.converter.DateStringConverter;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.IOUtils;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.mapreduce.InputSplit;
import org.apache.hadoop.mapreduce.RecordReader;
import org.apache.hadoop.mapreduce.TaskAttemptContext;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

import java.io.IOException;
import java.util.Date;
import java.util.UUID;

public class MyRecordReader extends RecordReader<NullWritable, BytesWritable> {
    private UUID uuid = UUID.randomUUID();
    Boolean more = true;// 是否还有更多的数据需要读
    BytesWritable value = new BytesWritable();// 输出值
    FileSplit split;// 分片信息
    private Configuration configuration;// 配置信息
    public MyRecordReader() {
        super();
    }


    // 初始化信息
    @Override
    public void initialize(InputSplit inputSplit, TaskAttemptContext taskAttemptContext) throws IOException, InterruptedException {
        System.out.println("uuid = " + uuid);
        System.out.println("########initialize#######");
        split = (FileSplit)inputSplit;
        configuration = taskAttemptContext.getConfiguration();
    }


    @Override
    public boolean nextKeyValue() throws IOException, InterruptedException {
        System.out.println("#######nextKeyValue###########");
        System.out.println(split.getPath());
        if(more){
            System.out.println("this is more ...");
            // 定义缓存
            byte[] contents = new byte[(int)split.getLength()];
            // 获取文件系统
            FileSystem fs  = FileSystem.get(this.configuration);
            // 读取文件内容
            FSDataInputStream fsDataInputStream = fs.open(split.getPath());
            // 读入缓冲区
            IOUtils.readFully(fsDataInputStream,contents,0,contents.length);
            // 输出到value
            value.set(contents, 0, contents.length);

            more = false;// 已经处理完
            return true; //返回true表示还会迭代该方法（下一次不会进入这里待处理逻辑，more），这在一次没处理完时很有用，虽然我们这里并无意义。
        }
        return  false;
    }

    @Override
    public NullWritable getCurrentKey() throws IOException, InterruptedException {
        return NullWritable.get();
    }

    @Override
    public BytesWritable getCurrentValue() throws IOException, InterruptedException {
        return value;
    }

    @Override
    public float getProgress() throws IOException, InterruptedException {
        return 0;
    }

    @Override
    public void close() throws IOException {

    }
}
```

3、Mapper
```java
package com.zhaoyi.smallfile;

import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

import java.io.IOException;

public class MyMapper extends Mapper<NullWritable, BytesWritable, Text, BytesWritable> {
    Text k = new Text();
    @Override
    protected void setup(Context context) throws IOException, InterruptedException {
        FileSplit inputSplit = (FileSplit) context.getInputSplit();
        // 文件路径作为key
        k.set(inputSplit.getPath().toString());
    }

    @Override
    protected void map(NullWritable key, BytesWritable value, Context context) throws IOException, InterruptedException {
        context.write(k, value);
    }
}
```

4、Driver
``` java
package com.zhaoyi.smallfile;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.SequenceFileOutputFormat;

import java.io.IOException;

public class MyDriver {
    public static void main(String[] args) throws Exception {
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(MyDriver.class);


        job.setOutputValueClass(BytesWritable.class);
        job.setOutputKeyClass(Text.class);

        // 关联的自定义InputFormat
        job.setInputFormatClass(MyInputFormat.class);
        // 设置输出文件的格式为sequenceFile
        job.setOutputFormatClass(SequenceFileOutputFormat.class);

        job.setMapperClass(MyMapper.class);

        FileInputFormat.setInputPaths(job,new Path(args[0]));
        FileOutputFormat.setOutputPath(job,new Path(args[1]));

        System.exit(job.waitForCompletion(true)? 1:0);
    }
}

```

最终输出如下：
```
SEQorg.apache.hadoop.io.Text"org.apache.hadoop.io.BytesWritable      _Y灒?劀叇?>ZE   +   file:/D:/hadoop/input/a.txt   a poor guy.   >   file:/D:/hadoop/input/b.txt   boss will come here, hurry up.   0   file:/D:/hadoop/input/c.txt   can I sit there?
```


