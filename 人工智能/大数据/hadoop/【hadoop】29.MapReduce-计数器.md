# 简介
在许多情况下，用户需要了解待分析的数据，尽管这并非所要执行的分析人物的核心内容，以统计数据集中无效集合记录数目的任务为例，如果发现无效记录的比例相当高，那么就要思考为何存在如此多的无效记录。例如，可能是以下问题的原因：
* 程序缺陷？
* 数据集质量有问题？

如果是问题1，则我们需要改善程序逻辑；如果是问题二，我们要么更换数据集，要么增加数据集的比重，从而使分析更具参考意义。

计数器是收集作业统计信息的有效手段之一。用于质量控制或应用统计、诊断系统故障等等。

## 1、计数器
## 1.1、内置计数器
Hadoop为每隔作业维护了若干内置计数器，以描述多项指标。例如，某些计数器记录已处理的字节和记录数，使用户课间空已处理的输入数据量和已产生的输出数据量。

这些内置的计数器被划分为若干组，参见下表

|组别|名称/类别|
|-|-|
|MapReduce任务计数器|TaskCounter|
|文件系统计数器|FileSystemCounter|
|FileInputFormat计数器|FileInputFormatCounter|
|FileOutFormat计数器|FileOutPutFormatCounter|
|作业计数器|JobCounter|
|||

这些计数器大多可以在开启了INFO级别的输出日志中查看到。

## 1.2、用户自定义的Java计数器
MapReduce允许我们自己定义计数器。

计数器的值可以在Mapper或Reducer中增加。定义方式有两种。

* 计数器由一个Java枚举类型来定义，以便对有关的计数器进行分组。
```JAVA
enum MyCounter{MALFORORMED,NORMAL}
// 对枚举定义的自定义计数器加1
context.getCounter(MyCounter.MALFORORMED).increment(1);
```
* 使用上下文对象的API进行添加。
```java
context.getCounter("counterGroup", "countera").increment(1);
```
其中组名和计数器名称随便起，但最好具有代表意义。

计数结果在程序运行后的控制台上查看。


