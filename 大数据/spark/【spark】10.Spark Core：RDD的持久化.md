# 简介
Spark速度非常快的原因之一，就是在不同操作中可以在内存中持久化或缓存个数据集。当持久化某个RDD后，每一个节点都将把计算的分片结果保存在内存中，并在对此RDD或衍生出的RDD进行的其他动作中重用。这使得后续的动作变得更加迅速。

RDD相关的持久化和缓存，是Spark最重要的特征之一。可以说，缓存是Spark构建迭代式算法和快速交互式查询的关键。如果一个有持久化数据的节点发生故障，Spark 会在需要用到缓存的数据时重算丢失的数据分区。如果 希望节点故障的情况不会拖累我们的执行速度，也可以把数据备份到多个节点上。 
# RDD的缓存方式
RDD通过persist方法或cache方法可以将前面的计算结果缓存，默认情况下 persist() 会把数据以序列化的形式缓存在 JVM 的堆空 间中。 
但是并不是这两个方法被调用时立即缓存，而是触发后面的action时，该RDD将会被缓存在计算节点的内存中，并供后面重用。

RDD的缓存可以调用两个方法实现：
```java
JavaRDD<T> persist(final StorageLevel newLevel)
JavaRDD<T> cache() 
```
cache最终也是调用了persist方法，默认的存储级别都是仅在内存存储一份，Spark的存储级别还有好多种。

存储级别在object StorageLevel中定义的，他支持如下几种参数实例
```java
public final class StorageLevel$ implements Serializable {
    public static StorageLevel$ MODULE$;
    private final StorageLevel NONE;
    private final StorageLevel DISK_ONLY;
    private final StorageLevel DISK_ONLY_2;
    private final StorageLevel MEMORY_ONLY;
    private final StorageLevel MEMORY_ONLY_2;
    private final StorageLevel MEMORY_ONLY_SER;
    private final StorageLevel MEMORY_ONLY_SER_2;
    private final StorageLevel MEMORY_AND_DISK;
    private final StorageLevel MEMORY_AND_DISK_2;
    private final StorageLevel MEMORY_AND_DISK_SER;
    private final StorageLevel MEMORY_AND_DISK_SER_2;
    private final StorageLevel OFF_HEAP;
```
常用的具体说明如下所示：
|级别|空间占用|CPU时间|存储在内存|存储在磁盘|备注|
|-|-|-|-|-|-|
|MEMORY_ONLY|高|低|是|否||
|MEMORY_ONLY_SER|低|高|是|否||
|MEMORY_AND_DISK|高|中等|部分|部分|如果内存不够，则溢出的部分使用磁盘存储|
|MEMORY_AND_DISK_SER|低|高|部分|部分|如果内存不够，则溢出的部分写在磁盘上，在内存中存放序列化的数据|
|DISK_ONLY|低|高|否|是||

> 在存储级别的末尾加上“_2”来把持久化数据存为两份。

缓存有可能丢失，或者存储于内存的数据由于内存不足而被删除，RDD的缓存容错机制保证了即使缓存丢失也能保证计算的正确执行。

通过基于RDD的一系列转换，丢失的数据会被重算，由于RDD的各个Partition是相对独立的，因此只需要计算丢失的部分即可，并不需要重算全部Partition。

# 总结
1. RDD的持久化主要通过persist和cache操作来实现。cache操作就相当于storageLevel为MEMORY_ONLY
的persisit操作；
2. 持久化时指定的存储等级大致可以分为：存储的位置（磁盘、内存、非堆内存）、是否序列化、存储的份数（1或2）

