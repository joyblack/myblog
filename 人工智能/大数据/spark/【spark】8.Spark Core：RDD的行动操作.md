# 简介
本章节我们主要探讨行动操作。行动操作和转换操作最大的不同在于，其输出结果一般为最终结果，并且输出到外部存储设备。

# 1、行动操作
以下列出一些较为简单的转换操作。

|操作名称|用途|
|-|-|
|reduce(func)|通过func函数聚集RDD中的所有元素，这个功能必须是可交换且可并联的|
|collect()|在驱动程序中，以数组的形式返回数据集的所有元素|
|count()|返回RDD的元素个数|
|first()|返回RDD的第一个元素（类似于take(1)）|
|take(n)|返回一个由数据集的前n个元素组成的数组|
|takeOrdered(n)|返回前几个并排序|
|takeSample(withReplacement,num, [seed])|返回一个数组，该数组由从数据集中随机采样的num个元素组成，可以选择是否用随机数替换不足的部分，seed用于指定随机数生成器种子|
|aggregate (zeroValue: U)(seqOp: (U, T) ⇒ U, combOp: (U, U) ⇒ U)|aggregate函数将每个分区里面的元素通过seqOp和初始值进行聚合，然后用combine函数将每个分区的结果和初始值(zeroValue)进行combine操作。这个函数最终返回的类型不需要和RDD中元素类型一致。|
|fold(num)(func)|折叠操作，aggregate的简化操作，seqop和combop一样。|
|saveAsTextFile(path)|将数据集的元素以textfile的形式保存到HDFS文件系统或者其他支持的文件系统，对于每个元素，Spark将会调用toString方法，将它装换为文件中的文本|
|saveAsSequenceFile(path)|将数据集中的元素以Hadoop sequencefile的格式保存到指定的目录下，可以使HDFS或者其他Hadoop支持的文件系统。|
|saveAsObjectFile(path) |用于将RDD中的元素序列化成对象，存储到文件中。|
|countByKey()|针对(K,V)类型的RDD，返回一个(K,Int)的map，表示每一个key对应的元素个数。|
|foreach(func)|在数据集的每一个元素上，运行函数func进行操作。|


## 1.1、reduce
```
public T reduce(final Function2<T, T, T> f)
```
可以看到，reduce对每个RDD的元素进行操作，返回一个汇总结果，返回类型和RDD元素的类型一致。显然，这是一个聚类操作。
```java
        JavaPairRDD<String, Double> scoreRDD = sc.parallelizePairs(Arrays.asList(new Tuple2<>("zhaoyi", 90.0),
                new Tuple2<>("huangwei", 95.0),
                new Tuple2<>("yuanyong", 97.0),
                new Tuple2<>("zhaoyi", 100.0),
                new Tuple2<>("huangwei", 100.0),
                new Tuple2<>("yuanyong", 70.0),
                new Tuple2<>("xiaozhou", 96.0)));
        Tuple2<String, Double> result = scoreRDD.reduce((lession1, lesstion2) -> new Tuple2<>("result", lession1._2 + lesstion2._2));
        System.out.println(result);
```
输出结果:
```
(result,648.0)
```

## 1.2、coolect、count、first、take以及takeOrdered
```java
        JavaRDD<Integer> rdd = sc.parallelize(Arrays.asList(90, 20, 10, 50, 60, 70, 80, 30, 100, 40));

        System.out.println("*** The rdd elements: " + rdd.collect());
        System.out.println("*** The rdd elements count: " + rdd.count());
        System.out.println("*** The rdd elementst first ele is: " + rdd.first());
        System.out.println("*** The rdd elements take 1 is: " + rdd.take(1));
        System.out.println("*** The rdd elements take 9 is: " + rdd.take(9));
        System.out.println("*** The rdd elements take 9 and sort is: " + rdd.takeOrdered(9));
        sc.close();
```
输出结果：
```
*** The rdd elements: [90, 20, 10, 50, 60, 70, 80, 30, 100, 40]
*** The rdd elements count: 10
*** The rdd elementst first ele is: 90
*** The rdd elements take 1 is: [90]
*** The rdd elements take 9 is: [90, 20, 10, 50, 60, 70, 80, 30, 100]
*** The rdd elements take 9 and sort is: [10, 20, 30, 40, 50, 60, 70, 80, 90]
```
> takeOrdered也有一个重载方法:` takeOrdered(final int num, final Comparator<T> comp)`，支持自定义排序。

## 1.3、takeSample
该方法仅在预期结果数组很小的情况下使用，因为所有数据都被加载到driver的内存中。
```
List<T> takeSample(final boolean withReplacement, final int num)
List<T> takeSample(final boolean withReplacement, final int num, final long seed)
```
返回一个数组，该数组由从数据集中随机采样的num个元素组成，可以选择是否用随机数替换不足的部分，seed用于指定随机数生成器种子。
* withReplacement：元素是否可以多次抽样(在抽样时替换)
* num：返回的样本的大小
* seed：随机数生成器的种子

```java
JavaRDD<Integer> rdd = sc.parallelize(Arrays.asList(90, 20, 10, 50, 60, 70, 80, 30, 100, 40));
        System.out.println("1.(withReplacement = false)The rdd takeSample result is :" + rdd.takeSample(false, 20));
        System.out.println("2.(withReplacement = true) The rdd takeSample result is :" + rdd.takeSample(true, 20));
```
返回结果
```
1.(withReplacement = false)The rdd takeSample result is :[90, 80, 70, 20, 10, 30, 40, 60, 50, 100]
2.(withReplacement = true) The rdd takeSample result is :[40, 10, 60, 60, 70, 100, 10, 70, 90, 20, 40, 80, 100, 90, 40, 40, 50, 70, 70, 90]
```
允许多次采样之后，最终结果都为样本的个数，但是如果不允许，即第一个参数设置为false，那么每次返回的结果最多为源数组个数（显而易见的）。

## 1.4、agreegate
```
<U> U aggregate(final U zeroValue, final Function2<U, T, U> seqOp, final Function2<U, U, U> combOp)
```
```java
 JavaRDD<Integer> rdd = sc.parallelize(Arrays.asList(1,2,3,4),2);
        System.out.println(rdd.getNumPartitions());
        rdd.foreachPartition(s -> System.out.println("partition: " + IteratorUtils.toList(s)));
        System.out.println("result is :" + rdd.aggregate(0, (a, b) -> a + b, (a, b) -> a + b));
        sc.close();
```
输出结果：
```
2
partition: [1, 2]
partition: [3, 4]
result is :10
```
这里只是简单的举例，可以看到，只要我们指定了初始值，seqop以及combop的返回值类型也应该和该初始值保持一致。
> 编写这类代码最主要的就搞清楚输入输出的类型。

并且要明白的是，最终的combop也是需要初始值的，这个值也是我们的第一个参数所指的值。

## 1.5、fold
同样，联系之前学习foldByKey，fold也是aggregate的简化操作，即sepOp和combOp是一样的。对照之前的例子，我们可以这样写:
```java
        JavaRDD<Integer> rdd = sc.parallelize(Arrays.asList(1,2,3,4),2);
        System.out.println("result is :" + rdd.aggregate(0, (a, b) -> a + b, (a, b) -> a + b));
        System.out.println("result is (use fold):" + rdd.fold(0, (a, b) -> a + b));
```
输出结果一致：
```
result is :10
result is (use fold):10
```

## 1.6、countByKey
针对(K,V)类型的RDD，返回一个(K,Int)的map，表示每一个key对应的元素个数。使用我们之前用到过的选课数据集，计算一下每一位同学各自选择了多少门课程。
``` java
        JavaPairRDD<String, String> lessonRDD = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "语文"),
                new Tuple2<>("yuanyong", "数学"),
                new Tuple2<>("zhaoyi", "英语"),
                new Tuple2<>("huangwei", "英语"),
                new Tuple2<>("yuanyong", "法语"),
                new Tuple2<>("xiaozhou", "物理")));
        Map<String, Long> result = lessonRDD.countByKey();
        System.out.println(result);
```
输出结果
```
{xiaozhou=1, huangwei=1, yuanyong=2, zhaoyi=2}
```

# 3、数值操作
行动操作中比较有意思的一类是专门针对数值的操作。Spark 对包含数值数据的 RDD 提供了一些特别的统计操作。 Spark的数值操作是通过流式算法实现的，允许以每次一个元素的方式构建出模型。这些统计数据都会在调用stats()时通过一次遍历数据计算出来，并以StatsCounter对象返回。 他们主要包括如下操作方法：
|||
|-|-|
|count()|RDD中元素的个数|
|mean|RDD中元素的平均数|
|sum|求和|
|max|最大值|
|min|最小值|
|variance|元素的方差|
|sampleVariance|从采用出的数据中计算方差|
|stdev|标准差|
|sampleStdev|从采用出的数据中计算标准差|

需要注意的是，在java中要使用这些便利，需要声明RDD的类型为`JavaDoubleRDD`.
```java
        JavaDoubleRDD rdd = sc.parallelizeDoubles(Arrays.asList(90D, 20D, 10D, 50D, 60D, 70D, 80D, 30D, 100D, 40D));
        System.out.println("*** count: " + rdd.count());
        System.out.println("*** mean: " + rdd.mean());
        System.out.println("*** sum: " + rdd.sum());
        System.out.println("*** min: " + rdd.min());
        System.out.println("*** max: " + rdd.max());
        System.out.println("*** variance: " + rdd.variance());
        System.out.println("*** sampleVariance: " + rdd.sampleVariance());
        System.out.println("*** stdev: " + rdd.stdev());
        System.out.println("*** sampleStdev: " + rdd.sampleStdev());
```
输出结果
```
*** count: 10
*** mean: 55.0
*** sum: 550.0
*** min: 10.0
*** max: 100.0
*** variance: 825.0
*** sampleVariance: 916.6666666666666
*** stdev: 28.722813232690143
*** sampleStdev: 30.276503540974915
```
> 有些函数只能用于特定类型的 RDD，比如 mean() 和 variance() 只能用在数值 RDD 上，而join()只能用在键值对 RDD 上。在 Scala 和 Java 中，这些函数都没有定义在标准的 RDD 类中，所以要访问这些附加功能，必须要确保获得了正确的专用RDD类型。



