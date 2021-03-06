# 简介
本章节收录Spark Stream的一些零散知识点。

# 1、Caching/Persistence
和RDDs类似，DStreams同样允许开发者将流数据保存在内存中。

也就是说，在DStream上使用persist()方法将会自动把DStreams中的每个RDD保存在内存中。当DStream中的数据要被多次计算时，这个非常有用（如在同样数据上的多次操作）。对于像reduceByWindowred和reduceByKeyAndWindow以及基于状态的(updateStateByKey)这种操作，保存是隐含默认的。

因此，即使开发者没有调用persist()，由基于窗操作产生的DStreams也会对开发者透明的自动保存在内存中。

# 2、DataFrame ans SQL Operations
可以很容易地在流数据上使用DataFrames和SQL。

当然，必须使用SparkContext来创建StreamingContext要用的SQLContext。此外，这一过程可以在驱动失效后重启。

我们通过创建一个实例化的SQLContext单实例来实现这个工作。如下例所示。我们对前例word count进行修改从而使用DataFrames和SQL来产生word counts。每个RDD被转换为DataFrame，以临时表格配置并用SQL进行查询。
```java
package org.apache.spark.examples.streaming;

import java.util.Arrays;
import java.util.regex.Pattern;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.api.java.StorageLevels;
import org.apache.spark.streaming.Durations;
import org.apache.spark.streaming.api.java.JavaDStream;
import org.apache.spark.streaming.api.java.JavaReceiverInputDStream;
import org.apache.spark.streaming.api.java.JavaStreamingContext;

/**
 * Use DataFrames and SQL to count words in UTF8 encoded, '\n' delimited text received from the
 * network every second.
 *
 * Usage: JavaSqlNetworkWordCount <hostname> <port>
 * <hostname> and <port> describe the TCP server that Spark Streaming would connect to receive data.
 *
 * To run this on your local machine, you need to first run a Netcat server
 *    `$ nc -lk 9999`
 * and then run the example
 *    `$ bin/run-example org.apache.spark.examples.streaming.JavaSqlNetworkWordCount localhost 9999`
 */
public final class JavaSqlNetworkWordCount {
  private static final Pattern SPACE = Pattern.compile(" ");

  public static void main(String[] args) throws Exception {
    if (args.length < 2) {
      System.err.println("Usage: JavaNetworkWordCount <hostname> <port>");
      System.exit(1);
    }

    StreamingExamples.setStreamingLogLevels();

    // Create the context with a 1 second batch size
    SparkConf sparkConf = new SparkConf().setAppName("JavaSqlNetworkWordCount");
    JavaStreamingContext ssc = new JavaStreamingContext(sparkConf, Durations.seconds(1));

    // Create a JavaReceiverInputDStream on target ip:port and count the
    // words in input stream of \n delimited text (eg. generated by 'nc')
    // Note that no duplication in storage level only for running locally.
    // Replication necessary in distributed scenario for fault tolerance.
    JavaReceiverInputDStream<String> lines = ssc.socketTextStream(
        args[0], Integer.parseInt(args[1]), StorageLevels.MEMORY_AND_DISK_SER);
    JavaDStream<String> words = lines.flatMap(x -> Arrays.asList(SPACE.split(x)).iterator());

    // Convert RDDs of the words DStream to DataFrame and run SQL query
    words.foreachRDD((rdd, time) -> {
      // spark is a singleton instance spark session
      SparkSession spark = JavaSparkSessionSingleton.getInstance(rdd.context().getConf());

      // Convert JavaRDD[String] to JavaRDD[bean class] to DataFrame
      JavaRDD<JavaRecord> rowRDD = rdd.map(word -> {
        JavaRecord record = new JavaRecord();
        record.setWord(word);
        return record;
      });
      Dataset<Row> wordsDataFrame = spark.createDataFrame(rowRDD, JavaRecord.class);

      // Creates a temporary view using the DataFrame
      wordsDataFrame.createOrReplaceTempView("words");

      // Do word count on table using SQL and print it
      // spark = JavaSparkSessionSingleton.getInstance(rdd.context().getConf());
      Dataset<Row> wordCountsDataFrame =
          spark.sql("select word, count(*) as total from words group by word");
      System.out.println("========= " + time + "=========");
      wordCountsDataFrame.show();
    });

    ssc.start();
    ssc.awaitTermination();
  }
}

/** Lazily instantiated singleton instance of SparkSession */
class JavaSparkSessionSingleton {
  private static transient SparkSession instance = null;
  public static SparkSession getInstance(SparkConf sparkConf) {
    if (instance == null) {
      instance = SparkSession
        .builder()
        .config(sparkConf)
        .getOrCreate();
    }
    return instance;
  }
}
```



# 3、性能考量
最常见的问题是Spark Streaming可以使用的最小批次间隔是多少。

总的来说，500毫秒已经被证实为对许多应用而言是比较好的最小批次大小。寻找最小批次大小的最佳实践是从一个比较大的批次大小(10 秒左右)开始，不断使用更小的批次大小。

如果Streaming用户界面中显示的处理时间保持不变，你就可以进一步减小批次大小。如果处理时间开始增加，你可能已经达到了应用的极限。 

相似地，对于窗口操作，计算结果的间隔(也就是滑动步长)对于性能也有巨大的影响。当计算代价巨大并成为系统瓶颈时，就应该考虑提高滑动步长了。 
减少批处理所消耗时间的常见方式还有提高并行度。有以下三种方式可以提高并行度：
* 增加接收器数目：有时如果记录太多导致单台机器来不及读入并分发的话，接收器会成为系统瓶颈。这时你就需要通过创建多个输入DStream(这样会创建多个接收器)来增加接收器数目，然后使用union来把数据合并为一个数据源。 
* 将收到的数据显式地重新分区：如果接收器数目无法再增加，你可以通过使用 DStream.repartition 来显式重新分区输入流(或者合并多个流得到的数据流)来重新分配收到的数据。 
* 提高聚合计算的并行度：对于像 reduceByKey() 这样的操作，你可以在第二个参数中指定并行度，我们在介绍RDD时提到过类似的手段。