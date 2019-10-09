# 简介
排序是MapReduce框架中最重要的操作之一。

在Mapper和Reducer阶段都有涉及，Map Task和Reduce Task均会对数据（按照key）进行排序。该操作属于Hadoop的默认行为。任何应用程序中的数据均会被排序，而不管逻辑上是否需要。

对于Map Task，它会将处理的结果暂时放到一个缓冲区中，当缓冲区使用率达到一定阈值后，再对缓冲区中的数据进行一次排序，并将这些有序数据写到磁盘上，而当数据处理完毕后，它会对磁盘上所有文件进行一次合并，以将这些文件合并成一个大的有序文件。

对于Reduce Task，它从每个Map Task上**远程拷贝**相应的数据文件，如果文件大小超过一定阈值，则放到磁盘上，否则放到内存中。

如果磁盘上文件数目达到一定阈值，则进行一次合并以生成一个更大文件；如果内存中文件大小或者数目超过一定阈值，则进行一次合并后将数据写到磁盘上。当所有数据拷贝完毕后，Reduce Task统一对内存和磁盘上的所有数据进行一次合并。
# 1、排序分类
1、部分排序

MapReduce根据输入记录的键对数据集排序，保证输出的每个文件内部排序。

2、全排序

如何用Hadoop产生一个全局排序的文件？最简单的方法是使用一个分区。但该方法在处理大型文件时效率极低，因为一台机器必须处理所有输出文件，从而完全丧失了MapReduce所提供的并行架构。

全排序的解决方案：
* 首先创建一系列排好序的文件；
* 其次，串联这些文件；
* 最后，生成一个全局排序的文件。

主要思路是使用一个分区来描述输出的全局排序。例如：可以为上述文件创建3个分区，在第一分区中，记录的单词首字母a-g，第二分区记录单词首字母h-n, 第三分区记录单词首字母o-z。

3、辅助排序：（GroupingComparator分组）

Mapreduce框架在记录到达reducer之前按键对记录排序，但键所对应的值并没有被排序。甚至在不同的执行轮次中，这些值的排序也不固定，因为它们来自不同的map任务且这些map任务在不同轮次中完成时间各不相同。

一般来说，大多数MapReduce程序会避免让reduce函数依赖于值的排序。但是，有时也需要通过特定的方法对键进行排序和分组等以实现对值的排序。

# 2、自定义排序
很多时候，默认的排序逻辑并不能满足我们的需求，例如流量Bean的排序。我们需要自定义排序逻辑。

原理很简单:对象实现WritableComparable接口重写compareTo方法，就可以实现排序。
```java
public int compareTo(FlowBean o) {
	// 倒序排列，从大到小
	return this.sumFlow > o.getSumFlow() ? -1 : 1;
}
```

# 3、排序案例：汇总流量排序输出
我们现在有了这样的需求，需要将手机流量的输出结果集不按默认的手机号码序输出，而是按照汇总流量从高到低输出。

1、分析

首先要明确的是，排序只能针对key进行，而我们的汇总流量属于Val，因此，我们需要将FlowBean作为key进行中间排序。需要重新定义一个MapReducer任务。

2、编写代码

（1）创建一个新的模块，phone-flow-sort。

（2）编写流量Bean，和之前的Bean差不多，只不过实现了排序接口
```java
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.io.WritableComparable;
import org.apache.hadoop.yarn.webapp.hamlet.HamletSpec;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class FlowBean implements Writable, WritableComparable<FlowBean> {
    ...
    // desc sort.
    public int compareTo(FlowBean other) {
        return this.getTotalFlow()>other.getTotalFlow()? -1:1;
    }
    ...
}
```
（3）Mapper
```java
package com.zhaoyi.flowbeansort;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.IOException;

public class FlowSortMapper extends Mapper<LongWritable, Text, FlowBean, Text> {
    FlowBean bean = new FlowBean();
    Text phone = new Text();

    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        String line = value.toString();
        String[] strings = line.split("\t");
        // Key-FlowBean: get the up and downFlow.
        bean.set(Long.parseLong(strings[1]), Long.parseLong(strings[2]));
        // Val-Phone
        phone.set(value);
        context.write(bean, phone);
    }
}
```
需要明确的是，我们当前的输入文件即为phoneflow项目的输出结果，其结构如下
```
13480253104	180	180	360
13502468823	7335	110349	117684
13560436666	1116	954	2070
13560439658	2034	5892	7926
13602846565	1938	2910	4848
13660577991	6960	690	7650
13719199419	240	0	240
13726230503	2481	24681	27162
13726238888	2481	24681	27162
13760778710	120	120	240
13826544101	264	0	264
13922314466	3008	3720	6728
13925057413	11058	48243	59301
13926251106	240	0	240
13926435656	132	1512	1644
15013685858	3659	3538	7197
15920133257	3156	2936	6092
15989002119	1938	180	2118
18211575961	1527	2106	3633
18320173382	9531	2412	11943
84138413	4116	1432	5548
```
因此，相对于当前的Mapper，输入类型为行号，Val为Text，即一行数据。现在，我们只需将FlowBean作为Mapper的key输出，电话号码作为val。

然后在reducer中将他们颠倒，即可完成我们的需求。

（4）Reducer
```java
package com.zhaoyi.flowbeansort;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;

public class FlowSortReducer extends Reducer<FlowBean, Text, Text, FlowBean> {
    @Override
    protected void reduce(FlowBean key, Iterable<Text> values, Context context) throws IOException, InterruptedException {
        // the values must be only one, and we just need upside down key-val.
        context.write(values.iterator().next(), key);
    }
}
```

（5）Driver
```java
package com.zhaoyi.flowbeansort;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;

public class FlowSortDriver {
    public static void main(String[] args) throws Exception {
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(FlowSortDriver.class);

        job.setMapperClass(FlowSortMapper.class);
        job.setReducerClass(FlowSortReducer.class);
       
        job.setMapOutputKeyClass(FlowBean.class);
        job.setMapOutputValueClass(Text.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(FlowBean.class);


        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true)? 1:0);

    }
}

```
由于Mapper与Reducer的输出类型不一样，因此需要指定Map的输出k-v类型，不能像之前的那样省略这里的代码了。

配置参数program arg，以之前的项目的输出作为输入。运行项目，将输出结果生成到output2中。
```
D:\hadoop\output D:\hadoop\output2
```

查看结果分区文件
```
13502468823	7335	110349	117684	7335	110349	117684
13925057413	11058	48243	59301	11058	48243	59301
13726238888	2481	24681	27162	2481	24681	27162
13726230503	2481	24681	27162	2481	24681	27162
18320173382	9531	2412	11943	9531	2412	11943
13560439658	2034	5892	7926	2034	5892	7926
13660577991	6960	690	7650	6960	690	7650
15013685858	3659	3538	7197	3659	3538	7197
13922314466	3008	3720	6728	3008	3720	6728
15920133257	3156	2936	6092	3156	2936	6092
84138413	4116	1432	5548	4116	1432	5548
13602846565	1938	2910	4848	1938	2910	4848
18211575961	1527	2106	3633	1527	2106	3633
15989002119	1938	180	2118	1938	180	2118
13560436666	1116	954	2070	1116	954	2070
13926435656	132	1512	1644	132	1512	1644
13480253104	180	180	360	180	180	360
13826544101	264	0	264	264	0	264
13926251106	240	0	240	240	0	240
13760778710	120	120	240	120	120	240
13719199419	240	0	240	240	0	240
```
实现了我们最终的需求。

可以看到，整个过程我们其实只是定义了FlowBean的排序逻辑，同时将其作为key而已（具体来说，是Mapper的输出key）。