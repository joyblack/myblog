# 简介
前面我们已经介绍了DStream的输入、转换，本章节我们来学习DStream的输出。其实他和RDD的输出、Dataset的输出都是差不多的。

输出操作指定了对流数据经转化操作得到的数据所要执行的操作(例如把结果推入外部数据库或输出到屏幕上)。

与RDD中的惰性求值类似，如果一个DStream及其派生出的DStream（血缘关系图）都没有被执行输出操作，那么这些 DStream 就都不会被求值。

如果StreamingContext中没有设定输出操作，整个context就都不会启动。 

# 1、常见输出操作
下标是使用的比较多的输出操作。
|输出操作|说明|
|-|-|
|print()|在运行流程序的驱动结点上打印DStream中**每一批次数据**的最开始**10**个元素。这个方法在调试程序中比较常用|
|saveAsTextFiles(prefix, [suffix])|以text文件形式存储这个DStream的内容。|
|saveAsObjectFiles(prefix, [suffix])|以Java对象序列化的方式将Stream中的数据保存为 SequenceFiles。|
|saveAsHadoopFiles(prefix, [suffix])|将Stream中的数据保存为Hadoop文件。|
|foreachRDD(func)|这是最通用的输出操作，即将函数func用于产生于stream的每一个RDD。其中func应该实现将每一个RDD中数据推送到外部系统，如将RDD存入文件或者通过网络将其写入数据库。**函数func在运行流应用的驱动中被执行，通常情况下func包含一些RDD操作，从而强制其进行基于Streaing RDD的运算。**|

> 输出方法参数中的prefix以及suffix是用于指定输出文件的命名规则的：每一批次的存储文件名基于参数中的为"prefix-TIME_IN_MS[.suffix]。

# 2、foreachRDD编程规范
通用的输出操作 foreachRDD()，它用来对 DStream 中的 RDD 运行任意计算。这和transform() 有些类似，都可以让我们访问任意RDD。在foreachRDD()中，可以重用我们在Spark中实现的所有行动操作。常见的用例之一是把数据写到包括MySQL数据库在内的外部数据库中。 

需要注意的是：
1. 连接不能写在driver层面
2. 如果写在foreach则每个RDD都创建，得不偿失

最佳的解决方案是增加foreachPartition，在分区创建连接信息。同时考虑使用连接池优化程序。

例如，下面是一段常见的foreachRDD的操作代码：
```java
// example: error way
dstream.foreachRDD(rdd -> {
  Connection connection = createNewConnection(); // executed at the driver
  rdd.foreach(record -> {
    connection.send(record); // executed at the worker
  });
});
```
可以看到，这犯了一个最基本的错误：连接对象序列化会从驱动程序(Driver)发送到工作程序（Worker）。这样的连接对象很少可以跨机器进行传输。这常常会出现序列化错误（连接对象不可序列化）、初始化错误（连接对象需要在工作区初始化）等问题。

正确的解决方案是在工作区创建连接对象，如下面的例子
```java
// example: not good way
dstream.foreachRDD(rdd -> {
  rdd.foreach(record -> {
    // in worker create connection.
    Connection connection = createNewConnection();
    connection.send(record);
    connection.close();
  });
});
```
对于这个例子，我们在工作区创建了连接。但是这种方式是更不可取的方式，即便他可以正常运行，这相当于针对每一个元素都进行一次创建连接对象，可想而知对于连接对象的创建和销毁将会产生多大的开销（最主要是时间）。

那么，最好的处理办法是什么呢？是使用`rdd.foreachPartition`方法，在每一个分区中创建连接，那么显然，只需创建当前分区数的连接，就可以完成我们的需求了。如下所示：
``` java
// exaple: best way
dstream.foreachRDD(rdd -> {
  rdd.foreachPartition(partitionOfRecords -> {
    // In partition create connection.
    Connection connection = createNewConnection();
    while (partitionOfRecords.hasNext()) {
      connection.send(partitionOfRecords.next());
    }
    connection.close();
  });
});
```