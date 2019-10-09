# 简介
分区（partition），属于Mapper阶段的流程。前面提到，线程首先根据数据最终要传的reducer把数据分成相应的分区(partition)。

默认情况下，采取的分区类是HashPartitioner
``` java
public class HashPartitioner<K, V> extends Partitioner<K, V> {
  /** Use {@link Object#hashCode()} to partition. */
  public int getPartition(K key, V value, int numReduceTasks) {
    return (key.hashCode() & Integer.MAX_VALUE) % numReduceTasks;
  }
}
```
显然，默认分区是根据key的hashCode对reduceTasks个数取模得到的。用户没法控制哪个key存储到哪个分区，因此我们常常需要自定义分区类。

编写自定义分区并应用的流程大致分为3步。

1. 自定义类继承Partitioner，重写getPartition()方法；
2. 在job驱动类中，设置自定义partitioner；
3. 自定义partition后，要根据自定义partitioner的逻辑设置相应数量的reduce task。

为什么需要设置reduce task的数量？
* 如果`reduceTask的数量 > getPartition的结果数`，则会多产生几个空的输出文件part-r-000xx；
* 如果`1 < reduceTask的数量 < getPartition的结果数`，则有一部分分区数据无处安放，会Exception；
* 如果`reduceTask的数量 = 1`，则不管mapTask端输出多少个分区文件，最终结果都交给这一个reduceTask，最终也就只会产生一个结果文件 part-r-00000；

例如：假设自定义分区数为5，则
* job.setNumReduceTasks(1);会正常运行，只不过会产生一个输出文件
* job.setNumReduceTasks(2);会报错
* job.setNumReduceTasks(6);大于5，程序会正常运行，会产生空文件；

# 1、分区案例——归属地分区电话号码流量统计
接下来我们完善之前的电话号码手机流量统计项目。

完善需求：将统计结果按照手机归属地不同省份输出到不同文件。

> 根据手机号的前三位可以区分不同归宿地的电话号码。

1、数据准备：依然是之前的输入文件phone_data.txt;

2、分析

Mapreduce中会将map输出的kv对，按照相同key分组，然后分发给不同的reducetask。默认的分发规则为：根据key的hashcode%reducetask数来分发。

如果要按照我们自己的需求进行分组，则需要改写数据分发（分组）组件Partitioner
自定义一个CustomPartitioner继承抽象类：Partitioner

最后再从job驱动中，设置自定义partitioner（之前我们使用默认的）： job.setPartitionerClass(CustomPartitioner.class)

3、编写代码

（1）、在之前的项目中添加分区类
```java
package com.zhaoyi.phoneflow;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Partitioner;

public class FlowPartition extends Partitioner<Text, FlowBean> {
    public static final String PARTITION_136 = "136";
    public static final String PARTITION_137 = "137";
    public static final String PARTITION_138 = "138";
    public static final String PARTITION_139 = "139";
    @Override
    public int getPartition(Text text, FlowBean flowBean, int i) {
        // default partition is 0.
        int partition = 0;

        // get the phone left 3 number.
        String phonePrefix = text.toString().substring(0,3);

        // get partition.
        if(PARTITION_136.equals(phonePrefix)){
            partition = 1;
        }else if(PARTITION_137.equals(phonePrefix)){
            partition = 2;
        }else if(PARTITION_138.equals(phonePrefix)) {
            partition = 3;
        }else if(PARTITION_139.equals(phonePrefix)) {
            partition = 4;
        }
        return partition;
    }
}
```
（2）、在驱动类中指定自定义分区类
```java
package com.zhaoyi.phoneflow;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class FlowDriver {
    public static void main(String[] args) throws Exception {
        if(args.length != 2){
            System.out.println("Please enter the parameter: data input and output paths...");
            System.exit(-1);
        }
        Job job = Job.getInstance(new Configuration());
        job.setJarByClass(FlowDriver.class);

        job.setMapperClass(FlowMapper.class);
        job.setReducerClass(FlowReducer.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(FlowBean.class);

        // 设置分区类
        job.setPartitionerClass(FlowPartition.class);
        // 我们设置了5个分区，对应上。
        job.setNumReduceTasks(5);

        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job,new Path(args[1]));

        System.exit(job.waitForCompletion(true)? 1:0);
    }
}

```

> 注意分区返回数字是从0开始计数。而且必须指定分区数大于1，否则新版本api不会执行我们所指定的自定义分区器，反正只有一个分区。

之前我们未指定分区类的时候，生成一个分区结果文件。这一次就会生成5个分区文件了，分别对应不同地区的电话号码记录。


> 本案例的具体代码参见github项目phoneflow模块。

# 2、分区案例 —— wordcount大小写分区
既然改造了电话号码案例，我们也来改造一下wordcount案例，将单词统计根据首字母大小写不同输出为2个文件。即大写字母开头的输出为一个文件，小写字母开头的输出为1个文件。

1、分析

只需在原有项目的基础上，添加分区类：获取每个单词的首字母，直接使用JAVA Character类API判断是不是小写字母，若不是，则统一判定为大写字母。

2、编写代码，添加分区类
``` java
package com.zhaoyi.wordcount;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Partitioner;

public class WordCountPartition extends Partitioner<Text, IntWritable> {
    @Override
    public int getPartition(Text text, IntWritable intWritable, int i) {
        char firstLetter = text.toString().charAt(0);
        if(Character.isLowerCase(firstLetter)){
            return 1;
        }
        return 0;
    }
}
```
> 别忘了在驱动类中设置自定义分区类。

3、查看输出结果

分区文件有2个，分别代表大小写字母的统计结果
```
#### part-r-00000
Alice	2
So	1
`and	1
`without	1

#### part-r-00001
a	3
and	1
bank	1
......
......
the	3
this	1
......
......
was	3
what	1
```
注意省略号代表我删除掉的一些记录，只是为了限制篇幅，不属于文件内容。

> 本案例见github项目的word-count模块。