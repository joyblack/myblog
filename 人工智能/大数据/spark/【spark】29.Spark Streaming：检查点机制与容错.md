# 简介
检查点机制是我们在Spark Streaming中用来保障容错性的主要机制。与应用程序逻辑无关的错误（即系统错位，JVM崩溃等）有迅速恢复的能力。

它可以使Spark Streaming阶段性地把应用数据存储到诸如HDFS或Amazon S3这样的可靠存储系统中， 以供恢复时使用。具体来说，检查点机制主要为以下两个目的服务。
1. 控制发生失败时需要重算的状态数。SparkStreaming可以通过转化图的谱系图来重算状态，检查点机制则可以控制需要在转化图中回溯多远。 

2. 提供驱动器程序容错。如果流计算应用中的驱动器程序崩溃了，你可以重启驱动器程序 并让驱动器程序从检查点恢复，这样Spark Streaming就可以读取之前运行的程序处理 数据的进度，并从那里继续。

为了实现这样的需求，Spark Streaming需要为容错存储系统checkpoint足够的信息从而使得其可以从失败中恢复过来。有两种类型的数据设置检查点：
1. Metadata checkpointing：将定义流计算的信息存入容错的系统如HDFS。元数据包括： 
   * 配置 – 用于创建流应用的配置；
   * DStreams操作 – 定义流应用的DStreams操作集合；
   * 不完整批次 – 批次的工作已进行排队但是并未完成。 
2. Data checkpointing： 将产生的RDDs存入可靠的存储空间。这种方式对于在多批次间合并数据的状态转换是很有必要的。在这样的转换中，RDDs的产生基于之前批次的RDDs，这会导致依赖链长度随着时间递增。为了避免在恢复期这种无限的时间增长（和链长度成比例），状态转换中间的RDDs会周期性的写入可靠地存储空间（如HDFS），以此来切短依赖链。 

总而言之，元数据检查点在由驱动故障中恢复是十分必要的。

# 1、适合使用检查点的场景
如果应用程序有以下的需求，则需要开启检查点机制：
1. 在程序中使用了例如`updateStateByKey `或者`reduceByKeyAndWindow `这样的方法，则必须提供检查点目录以允许定期进行RDD检查。

2.从运行应用程序的driver故障中恢复：Metadata checkpointing适合这种情况，用于恢复进度信息。

> 简单流式应用程序可以在不启用检查点的情况下运行。在这种情况下，从驱动程序故障中恢复不是完整的（一些已接收但未处理的数据可能会丢失）。这一般是在可控范围内的，许多应用程序都是以这种方式运行Spark Streaming应用程序。

# 2、如何使用检查点
可以通过向 ssc.checkpoint() 方法传递一个路径参数(HDFS、S3 或者本地路径均可)来配置检查点路径，同时应用应该能够使用检查点的数据。
1. 当程序第一次启动时，它将创建一个新的streamingcontext，设置所有流，然后调用start（）。
2. 当程序在失败后重新启动时，它将从检查点目录中的检查点数据重新创建一个streamingcontext。
   
```java

// Create a factory object that can create and setup a new JavaStreamingContext
JavaStreamingContextFactory contextFactory = new JavaStreamingContextFactory() {
  @Override public JavaStreamingContext create() {
    JavaStreamingContext jssc = new JavaStreamingContext(...);  // new context
    JavaDStream<String> lines = jssc.socketTextStream(...);     // create DStreams
    ...
    jssc.checkpoint(checkpointDirectory);                       // set checkpoint directory
    return jssc;
  }
};

// Get JavaStreamingContext from checkpoint data or create a new one
JavaStreamingContext context = JavaStreamingContext.getOrCreate(checkpointDirectory, contextFactory);

// Do additional setup on context that needs to be done,
// irrespective of whether it is being started or restarted
context. ...

// Start the context
context.start();
context.awaitTermination();
```

如果检查点目录(checkpointDirectory)存在，那么context将会由检查点数据重新创建。如果目录不存在（首次运行），那么函数contextFactory将会被调用来创建一个新的context并设置DStreams。

注意RDDs的检查点引起存入可靠内存的开销。在RDDs需要检查点的批次里，处理的时间会因此而延长。所以，检查点的间隔需要很仔细地设置。如果使用小批次（1秒钟），每一批次检查点会显著减少操作吞吐量。反之，检查点设置的过于频繁导致“血统”和任务尺寸增长，这会有很不好的影响。

对于需要RDD检查点设置的状态转换，默认间隔是批次间隔的倍数，一般至少为10秒钟。可以通过dstream.checkpoint(checkpointInterval)。

通常，检查点设置间隔是5-10个DStream的滑动间隔。

# 3、驱动器程序容错
驱动器程序的容错要求我们以特殊的方式创建 StreamingContext。我们需要把检查点目录提供给StreamingContext。与直接调用new StreamingContext 不同，应该使用StreamingContext.getOrCreate() 函数。
```java
// Create a factory object that can create and setup a new JavaStreamingContext
JavaStreamingContextFactory contextFactory = new JavaStreamingContextFactory() {
  @Override public JavaStreamingContext create() {
    JavaStreamingContext jssc = new JavaStreamingContext(...);  // new context
    JavaDStream<String> lines = jssc.socketTextStream(...);     // create DStreams
    ...
    jssc.checkpoint(checkpointDirectory);                       // set checkpoint directory
    return jssc;
  }
};

// Get JavaStreamingContext from checkpoint data or create a new one
JavaStreamingContext context = JavaStreamingContext.getOrCreate(checkpointDirectory, contextFactory);

// Do additional setup on context that needs to be done,
// irrespective of whether it is being started or restarted
context. ...

// Start the context
context.start();
context.awaitTermination();
```

# 4、工作节点容错
为了应对工作节点失败的问题，Spark Streaming使用与Spark的容错机制相同的方法。所 有从外部数据源中收到的数据都在多个工作节点上备份。所有从备份数据转化操作的过程 中创建出来的 RDD 都能容忍一个工作节点的失败，因为根据 RDD 谱系图，系统可以把丢 失的数据从幸存的输入数据备份中重算出来。

# 5、接收器容错
运行接收器的工作节点的容错也是很重要的。

如果这样的节点发生错误，Spark Streaming会在集群中别的节点上重启失败的接收器。然而，这种情况会不会导致数据的丢失取决于数据源的行为(数据源是否会重发数据)以及接收器的实现(接收器是否会向数据源确认收到数据)。

举个例子，使用Flume作为数据源时，两种接收器的主要区别在于数据丢失 时的保障。在“接收器从数据池中拉取数据”的模型中，Spark只会在数据已经在集群中备份时才会从数据池中移除元素。而在“向接收器推数据”的模型中，如果接收器在数据备份之前失败，一些数据可能就会丢失。

对于任意一个接收器，你必须同时考虑上游数据源的容错性(是否支持事务)来确保零数据丢失。 


总的来说，接收器提供以下保证。
1. 所有从可靠文件系统中读取的数据(比如通过StreamingContext.hadoopFiles读取的) 都是可靠的，因为底层的文件系统是有备份的。Spark Streaming会记住哪些数据存放到了检查点中，并在应用崩溃后从检查点处继续执行。 
2. 对于像Kafka、推式Flume、Twitter这样的不可靠数据源，Spark会把输入数据复制到其他节点上。但是如果接收器任务崩溃，Spark还是会丢失数据。在 Spark 1.1 以及更早的版 本中，收到的数据只被备份到执行器进程的内存中。所以一旦驱动器程序崩溃(此时所有的执行器进程都会丢失连接)，数据也会丢失。在 Spark 1.2 中，收到的数据被记录到诸如HDFS这样的可靠的文件系统中，这样即使驱动器程序重启也不会导致数据丢失。
 
综上所述，确保所有数据都被处理的最佳方式是使用可靠的数据源(例如 HDFS、拉式 Flume 等)。

如果你还要在批处理作业中处理这些数据，使用可靠数据源是最佳方式。因为这种方式确保了你的批处理作业和流计算作业能读取到相同的数据，因而可以得到相同的结果。

# 6、处理保障
由于Spark Streaming工作节点的容错保障，Spark Streaming可以为所有的转化操作提供“精确一次”执行的语义。即使一个工作节点在处理部分数据时发生失败，最终的转化结果(即转化操作得到的RDD)仍然与数据只被处理一次得到的结果一样。 

然而，当把转化操作得到的结果使用输出操作推入外部系统中时，写结果的任务可能因故障而执行多次，一些数据可能也就被写了多次。由于这引入了外部系统，因此我们需要专门针对各系统的代码来处理这样的情况。

我们可以使用事务操作来写入外部系统(即原子化地将一个RDD分区一次写入)，或者设计幂等的更新操作(即多次运行同一个更新操作仍生成相同的结果)。比如 Spark Streaming的saveAs...File操作会在一个文件写完时自动将其原子化地移动到最终位置上，以此确保每个输出文件只存在一份。 
