# 简介
RDD的转换操作是非侵入式的，前面我们讲到RDD是不可修改的，因此转换是一个没有对操作的RDD做任何修改，同时生成新的RDD的过程。RDD中转换操作主要分为两种：
1. 转换(transfermation)
2. 行动(action)

本章节我们主要探讨转换操作。

# 1、转换操作
以下列出一些较为简单的转换操作。

|操作名称|用途|
|-|-|
|map|返回一个新的RDD，该RDD由每一个输入元素经过func函数转换后组成|
|filter|返回一个新的RDD，该RDD由经过func函数计算后返回值为true的输入元素组成|
|flatMap|类似于map，但是每一个输入元素可以被映射为0或多个输出元素（所以func应该返回一个序列，而不是单一元素），最后将返回的迭代器的所有内容“压扁”之后组成新的RDD|
|sample(withReplacement, fraction, seed)|以指定的随机种子随机抽样出数量为fraction的数据，withReplacement表示是抽出的数据是否放回，true为有放回的抽样，false为无放回的抽样，seed用于指定随机数生成器种子。例子从RDD中随机且有放回的抽出50%的数据，随机种子值为3（即可能以1 2 3的其中一个起始值）|
|partitionBy|根据指定的分区器重新对RDD进行分区|
|mapPartitionsWithIndex(func)|类似于mapPartitions，但func带有一个整数参数表示分片的索引值，因此在类型为T的RDD上运行时，func的函数类型必须是(Int, Interator[T]) => Iterator[U]|
|combineByKey|对相同K，把V合并成一个集合|
|union(otherDataset)|对源RDD和参数RDD求并集后返回一个新的RDD|
|intersection(otherDataset)|对源RDD和参数RDD求交集后返回一个新的RDD|
|distince|对源RDD进行去重后返回一个新的RDD. 默认情况下，只有8个并行任务来操作，但是可以传入一个可选的numTasks参数改变它。|
|reduceByKey(func, [numTasks])|在一个(K,V)的RDD上调用，返回一个(K,V)的RDD，使用指定的reduce函数，将相同key的值聚合到一起，reduce任务的个数可以通过第二个可选的参数来设置|
|groupByKey|groupByKey也是对每个key进行操作，但只生成一个sequence|
|pipe(command, [envVars])|对于每个分区，都执行一个perl或者shell脚本，返回输出的RDD。|
|coalesce(numPartitions)|缩减分区数，用于大数据集过滤后，提高小数据集的执行效率|
|repartition(numPartitions)|根据分区数，从新通过网络随机洗牌所有数据。|
|glom|将每一个分区形成一个数组，形成新的RDD类型时RDD[Array[T]]|
|mapValues|针对于(K,V)形式的类型只对V进行操作|
|subtract|计算差：去除两个RDD中相同的元素，不同的RDD将保留下来 |

> flatMap返回的一般是一个迭代器，例如单词切分我们经常用到。

## 1.1、combineByKey
顾名思义：对相同K，把V合并成一个集合.该方法的原型如下：
```scala
combineByKey[C](  
createCombiner: V => C,  
mergeValue: (C, V) => C,  
mergeCombiners: (C, C) => C) 
```
Java原型
```java
public <C> JavaPairRDD<K, C> combineByKey(final Function<V, C> createCombiner, final Function2<C, V, C> mergeValue, final Function2<C, C, C> mergeCombiners, final Partitioner partitioner, final boolean mapSideCombine, final Serializer serializer)   
```
`combineByKey()` 会遍历分区中的所有元素，因此每个元素的键要么还没有遇到过，要么就和之前的某个元素的键相同。此时：
* 如果这是一个新的键，则使用createCombiner() 的函数来创建那个键对应的累加器的初始值；
* 如果这是一个在处理当前分区之前已经遇到的键，则使用mergeValue()方法将该键的累加器对应的当前值与这个新的值进行合并；

由于每个分区都是独立处理的，因此对于同一个键可以有多个累加器。如果有两个或者更多的分区都有对应同一个键的累加器，就需要使用用户提供的mergeCombiners()方法将各个分区的结果进行合并。以下是计算平均分的一个例子：
```java
package com.spark;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;

import javax.xml.bind.SchemaOutputResolver;
import java.util.Arrays;

public class AverageTest {
    public static void main(String[] args) {
        Logger logger = LoggerFactory.getLogger(AverageTest.class);

        SparkConf sparkConf = new SparkConf().setAppName("wordCount").set("spark.testing.memory", "2147480000").setMaster("local");

        JavaSparkContext sc = new JavaSparkContext(sparkConf);

        JavaPairRDD<String, Double> scoreRDD = sc.parallelizePairs(Arrays.asList(new Tuple2<>("zhaoyi", 90.0),
                new Tuple2<>("huangwei", 95.0),
                new Tuple2<>("yuanyong", 97.0),
                new Tuple2<>("zhaoyi", 100.0),
                new Tuple2<>("huangwei", 100.0),
                new Tuple2<>("yuanyong", 70.0),
                new Tuple2<>("xiaozhou", 96.0)));

        JavaPairRDD<String, Tuple2<Double, Integer>> combineRDD = scoreRDD.combineByKey(score -> new Tuple2<>(score, 1),
                (t, score) -> new Tuple2<>(t._1 + score, t._2 + 1),
                (t1, t2) -> new Tuple2<>(t1._1 + t2._1, t1._2 + t2._2)
        );
        // 计算平均分
        JavaRDD<Tuple2> map = combineRDD.map(t -> new Tuple2(t._1, t._2._1 / t._2._2));

        map.collect().forEach(System.out::println);
        logger.info("success");
        sc.close();
    }
}
```
我们关注核心代码部分：
```java
JavaPairRDD<String, Tuple2<Double, Integer>> combineRDD = scoreRDD.combineByKey(score -> new Tuple2<>(score, 1),
                (t, score) -> new Tuple2<>(t._1 + score, t._2 + 1),
                (t1, t2) -> new Tuple2<>(t1._1 + t2._1, t1._2 + t2._2)
        );
```
* `score -> new Tuple2<>(score, 1)` 我们为了求得平均分数，第一次遇到新的键时，返回的是元组（分数，1），代表当前学生的分数以及出现了1次，需要注意的是，该方法的输入参数，一定是操作RDD的V；

* `(t, score) -> new Tuple2<>(t._1 + score, t._2 + 1),` 当遇到了相同的元组时候调用该方法，传入的第一个参数是我们之前的第一个方法的返回值，也就是组合出的（分数，次数）这样的元组，第二个参数同理，是RDD的V，这时候，我们需要将结果进行累加。

* ` (t1, t2) -> new Tuple2<>(t1._1 + t2._1, t1._2 + t2._2)` 该方法，就是将各个分区的累加器的结果进行累加，传入的参数为我们第一个方法中返回的数据类型。返回一个新的元组，从而得到最终的结果。

最后返回的显然是（学生名,（分数，次数））这样的元组类型，最终使用map统计结果，得到的输出如下所示：
```
(xiaozhou,96.0)
(huangwei,97.5)
(yuanyong,83.5)
(zhaoyi,95.0)
```

## 1.2、aggregateByKey
> aggregate 合集；总数；聚集；

该函数的原型如下：
```
aggregateByKey(zeroValue:U,[partitioner: Partitioner]) 
(seqOp: (U, V) => U,
combOp: (U, U) => U)
```
在K-V对的RDD中，按key将value进行分组合并。合并时，将每个value和初始值作为seq函数的参数进行计算，返回的结果作为一个新的K-V。

然后再将结果按照key进行合并，最后将每个分组的value传递给combine函数进行计算（先将前两个value进行计算，将返回结果和下一个value传给combine函数，以此类推），将key与计算结果作为一个新的kv对输出。

seqOp函数用于在每一个分区中用初始值逐步迭代value，combOp函数用于合并每个分区中的结果。


同理，我们接下来写一个用例，计算每位同学获得的最高分，也就是我们常见的分组并排序的例子。
```java
package com.spark;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;

import java.util.Arrays;

public class AggregateTest {
    public static void main(String[] args) {
        Logger logger = LoggerFactory.getLogger(AggregateTest.class);

        SparkConf sparkConf = new SparkConf().setAppName("AggregateTest").set("spark.testing.memory", "2147480000").setMaster("local");

        JavaSparkContext sc = new JavaSparkContext(sparkConf);

        JavaPairRDD<String, Double> scoreRDD = sc.parallelizePairs(Arrays.asList(new Tuple2<>("zhaoyi", 90.0),
                new Tuple2<>("huangwei", 95.0),
                new Tuple2<>("yuanyong", 97.0),
                new Tuple2<>("zhaoyi", 100.0),
                new Tuple2<>("huangwei", 100.0),
                new Tuple2<>("yuanyong", 70.0),
                new Tuple2<>("xiaozhou", 96.0)));

        JavaPairRDD<String, Double> stringDoubleJavaPairRDD = scoreRDD.aggregateByKey(0D,
                (a, b) -> Math.max(a, b),
                (a, b) -> Math.max(a, b));
        stringDoubleJavaPairRDD.collect().forEach(System.out::println);
        sc.close();
    }
}
```
得到输出：
```
(xiaozhou,96.0)
(huangwei,100.0)
(yuanyong,97.0)
(zhaoyi,100.0)
```
看核心代码部分
```java
JavaPairRDD<String, Double> stringDoubleJavaPairRDD = scoreRDD.aggregateByKey(0D,
                (a, b) -> Math.max(a, b),
                (a, b) -> Math.max(a, b));
```
* `0D` 指明了我们的初始比较器，用于第一次时处理；
* `(a, b) -> Math.max(a, b)` 针对各个值进行处理，最终返回一个最大值；
* `(a, b) -> Math.max(a, b)` 根据第二个方法返回的值，确定了该方法的两个参数的类型，即同样为Double，合并各个分区的计算结果；

## 1.3、foldByKey
```
foldByKey(zeroValue: V)(func: (V, V) => V): RDD[(K, V)]
```
aggregateByKey的简化操作，seqop和combop相同。例如前面我们用于计算最高分的例子，去掉第三个函数即combop，然后替换为foldByKey方法，也可以得到同样的结果。
```java
JavaPairRDD<String, Double> stringDoubleJavaPairRDD = scoreRDD.foldByKey(0D,(a, b) -> Math.max(a, b));
```
得到输出
```
(xiaozhou,96.0)
(huangwei,100.0)
(yuanyong,97.0)
(zhaoyi,100.0)
```

## 1.4、sortByKey
```
sortByKey(final Comparator<K> comp, final boolean ascending, final int numPartitions)
sortByKey(final Comparator<K> comp, final boolean ascending)
sortByKey(final Comparator<K> comp)
sortByKey(final boolean ascending, final int numPartitions)
sortByKey(final boolean ascending)
sortByKey()
```
在java这里都是一个sortByKey，scala应该是分为两种方法（sortByKey以及sortBy），这里多个重载方法，可以直接传入一个bool值决定是否升序排序，以及传入一个比较器，自定义比较逻辑。

```java
package com.spark;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;

import java.util.Arrays;

public class sortByKeyTest {
    public static void main(String[] args) {
        Logger logger = LoggerFactory.getLogger(sortByKeyTest.class);

        SparkConf sparkConf = new SparkConf().setAppName("AggregateTest").set("spark.testing.memory", "2147480000").setMaster("local");

        JavaSparkContext sc = new JavaSparkContext(sparkConf);

        JavaPairRDD<String, Double> scoreRDD = sc.parallelizePairs(Arrays.asList(new Tuple2<>("zhaoyi", 90.0),
                new Tuple2<>("huangwei", 95.0),
                new Tuple2<>("yuanyong", 97.0),
                new Tuple2<>("zhaoyi", 100.0),
                new Tuple2<>("huangwei", 100.0),
                new Tuple2<>("yuanyong", 70.0),
                new Tuple2<>("xiaozhou", 96.0)));
        JavaPairRDD<String, Double> stringDoubleJavaPairRDD = scoreRDD.sortByKey(true);
        stringDoubleJavaPairRDD.collect().forEach(System.out::println);
        sc.close();
    }
}
```
输出如下，可以看到，按照字典序对key进行了排序:
```
(huangwei,95.0)
(huangwei,100.0)
(xiaozhou,96.0)
(yuanyong,97.0)
(yuanyong,70.0)
(zhaoyi,90.0)
(zhaoyi,100.0)
```

## 1.5、join
```
join(otherDataset, [numTasks])
```
在类型为(K,V)和(K,W)的RDD上调用，返回一个相同key对应的所有元素对在一起的(K,(V,W))的RDD。
```java
        JavaPairRDD<String, String> lessonRDD = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "语文"),
                new Tuple2<>("yuanyong", "数学"),
                new Tuple2<>("zhaoyi", "英语"),
                new Tuple2<>("huangwei", "英语"),
                new Tuple2<>("yuanyong", "法语"),
                new Tuple2<>("xiaozhou", "物理")));
        JavaPairRDD<String, String> lessonRDD2 = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "日语")));
        final JavaPairRDD<String, Tuple2<String, String>> result = lessonRDD.join(lessonRDD2);
        result.collect().forEach(System.out::println);
```
输出为：
```
(zhaoyi,(语文,日语))
(zhaoyi,(英语,日语))
```
可以看到join是一种内连接的方式，即如果连接对象没有对应键的记录，则该键被去除，即只返回两个RDD中都存在的key的记录。

## 1.6、cogroup
```
cogroup(otherDataset, [numTasks])
```
在类型为(K,V)和(K,W)的RDD上调用，返回一个(K,(Iterable<V>,Iterable<W>))类型的RDD。
```java
        JavaPairRDD<String, String> lessonRDD = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "语文"),
                new Tuple2<>("yuanyong", "数学"),
                new Tuple2<>("zhaoyi", "英语"),
                new Tuple2<>("huangwei", "英语"),
                new Tuple2<>("yuanyong", "法语"),
                new Tuple2<>("xiaozhou", "物理")));
        JavaPairRDD<String, String> lessonRDD2 = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "日语"),
                new Tuple2<>("zhaoyi", "国语"),
                new Tuple2<>("zhangxuan","斯威士语")));
        JavaPairRDD<String, Tuple2<Iterable<String>, Iterable<String>>> result = lessonRDD.cogroup(lessonRDD2);
        result.collect().forEach(System.out::println);
```
输出结果：
```
(xiaozhou,([物理],[]))
(huangwei,([英语],[]))
(yuanyong,([数学, 法语],[]))
(zhaoyi,([语文, 英语],[日语, 国语]))
(zhangxuan,([],[斯威士语]))
```
从结果不难看出，该方法会收集所有的key值。同时，将各个RDD中相同键值的数据的V分别放入两个可迭代的数组中，以元组的形式作为V返回。

## 1.7、笛卡尔积
```
<U> JavaPairRDD<T, U> cartesian(final JavaRDDLike<U, ?> other)
```
笛卡尔积乘积，通常用在相似度算法中，这里我们举最原始的例子，平面坐标点的笛卡尔积。
```java
        JavaRDD<Integer> rdd1 = sc.parallelize(Arrays.asList(1, 2, 3));
        JavaRDD<Integer> rdd2 = sc.parallelize(Arrays.asList(4, 5, 6));
        JavaPairRDD<Integer, Integer> result = rdd1.cartesian(rdd2);
        result.collect().forEach(System.out::println);
```
输出结果：
```
(1,4)
(1,5)
(1,6)
(2,4)
(2,5)
(2,6)
(3,4)
(3,5)
(3,6)
```
结果即为RDD1中的元素分别将自己的元素与RDD2中的两两配对，最终输出一个a*b大小的元组RDD。

## 1.8、mapValues
针对于(K,V)形式的类型，且只对V进行操作。
```java
        JavaPairRDD<String, String> lessonRDD = sc.parallelizePairs(Arrays.asList(
                new Tuple2<>("zhaoyi", "语文"),
                new Tuple2<>("yuanyong", "数学"),
                new Tuple2<>("zhaoyi", "英语"),
                new Tuple2<>("huangwei", "英语"),
                new Tuple2<>("yuanyong", "法语"),
                new Tuple2<>("xiaozhou", "物理")));
        JavaPairRDD<String, String> result = lessonRDD.mapValues(lession -> "_" + lession + "_");
        result.collect().forEach(System.out::println);
```
返回结果：
```
(zhaoyi,_语文_)
(yuanyong,_数学_)
(zhaoyi,_英语_)
(huangwei,_英语_)
(yuanyong,_法语_)
(xiaozhou,_物理_)
```