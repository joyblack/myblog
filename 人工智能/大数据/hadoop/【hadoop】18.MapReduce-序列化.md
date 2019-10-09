# 简介
序列化就是把内存中的对象，转换成字节序列（或其他数据传输协议）以便于存储（持久化）和网络传输。 

反序列化就是将收到字节序列（或其他数据传输协议）或者是硬盘的持久化数据，转换成内存中的对象。

Hadoop拥有一套自己的序列化机制。

# 1、为什么不用Java Serialization
Java的序列化是一个重量级序列化框架（Serializable），一个对象被序列化后，会附带很多额外的信息（各种校验信息，header，继承体系等），不便于在网络中高效传输。所以，hadoop自己开发了一套序列化机制（Writable），他具有精简、高效的特点。

> Hadoop之父Doug Cutting（道格卡丁）解释道：“因为Java的序列化机制太过复杂了，而我认为需要有一个精简的机制，可以用于精确控制对象的读和写，这个机制将是Hadoop的核心。使用Java序列化虽然可以获得一些控制权，但用起来非常纠结。不用RMI（远程方法调用）也是出于类似的考虑。”

# 2、Hadoop常用序列化类型
我们通过常用的Java数据类型对应的hadoop数据序列化类型
|Java类型|Hadoop Writable类型|
|-|-|
|boolean	|BooleanWritable|
|byte	|ByteWritable|
|int	|IntWritable|
|float	|FloatWritable|
|long	|LongWritable|
|double	|DoubleWritable|
|string	|Text|
|map	|MapWritable|
|array|	ArrayWritable|

在具体案例中，我们可以根据实际需求，如果类型可以用简单类型胜任的话，在此表中寻找到对应的参考。

# 3、自定义bean对象实现序列化接口

很多情况下，基础类型是无法满足我们的业务需求的，通常我们的输入输出很可能都是一些实体化的类型映射。基于这种情况，我们就需要自定义writable类型。

自定义bean对象要想序列化传输，必须实现序列化接口，需要参考如下规则：
1. 必须实现Writable接口
   * 重写序列化方法
   * 重写反序列化方法，反序列化时，需要反射调用空参构造函数，所以必须有空参构造，注意反序列化的顺序和序列化的顺序完全一致
2. 要想把结果显示在文件中，需要重写toString()，且用”\t”分开，方便后续用；
3. 如果需要将自定义的bean放在key中传输，则还需要实现comparable接口，因为mapreduce框中的shuffle过程一定会对key进行排序。

> setter方法中，推荐再增加一个set方法，用于一次性设置所有的合并字段。

如下是一个简单的自定义Writable类型
``` java
package com.zhaoyi.phoneflow;

import org.apache.hadoop.io.Writable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class FlowBean implements Writable {

    private long upFlow;// 上行流量
    private long downFlow;// 下行流量
    private long totalFlow;// 总流量

    // 无参构造
    public FlowBean() {
    }

    public FlowBean(long upFlow, long downFlow) {
        this.upFlow = upFlow;
        this.downFlow = downFlow;
        this.totalFlow = upFlow + downFlow;
    }

    // 序列化
    public void write(DataOutput out) throws IOException {
        out.writeLong(upFlow);
        out.writeLong(downFlow);
        out.writeLong(totalFlow);
    }

    // set方法，一次性设置属性
    public void set(long upFlow, long downFlow){
        this.upFlow = upFlow;
        this.downFlow = downFlow;
        this.totalFlow = upFlow + downFlow;
    }

    // 反序列化 - 顺序和序列化保持一致
    public void readFields(DataInput in) throws IOException {
        this.upFlow = in.readLong();
        this.downFlow = in.readLong();
        this.totalFlow = in.readLong();
    }

    public long getUpFlow() {
        return upFlow;
    }

    public long getDownFlow() {
        return downFlow;
    }

    public long getTotalFlow() {
        return totalFlow;
    }

    public void setUpFlow(long upFlow) {
        this.upFlow = upFlow;
    }

    public void setDownFlow(long downFlow) {
        this.downFlow = downFlow;
    }

    public void setTotalFlow(long totalFlow) {
        this.totalFlow = totalFlow;
    }

    // 使用制表符分隔
    @Override
    public String toString() {
        return "upFlow=" + upFlow +
                "\t" + downFlow +
                "\t" + totalFlow;
    }
}
```