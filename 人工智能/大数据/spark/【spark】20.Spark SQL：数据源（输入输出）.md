# 简介
Spark SQL的DataFrame接口支持多种数据源的操作。

一个DataFrame可以进行RDDs方式的操作，也可以被注册为临时表。把DataFrame注册为临时表之后，就可以对该DataFrame执行SQL查询。

# 1、通用加载/存储方法
## 1.1、手动指定选项
Spark SQL的默认数据源为Parquet格式，当然，我们可以通过修改
```
spark.sql.sources.default
```
配置项来修改默认的数据源格式。

当数据源格式不是parquet格式文件时，需要手动指定数据源的格式。数据源格式需要指定全名（例如：`org.apache.spark.sql.parquet`），如果数据源格式为内置格式，则只需要指定简称定`json, parquet, jdbc, orc, libsvm, csv, text`来指定数据的格式。

可以通过SparkSession提供的read.load方法用于通用加载数据，使用write和save保存数据。
```java
    SparkConf sparkConf = new SparkConf().setAppName("test").set("spark.testing.memory", "2147480000").setMaster("local");
    JavaSparkContext sc = new JavaSparkContext(sparkConf);
    // spark session
    SparkSession spark = SparkSession.builder().appName("sql").config(sparkConf).getOrCreate();

    Dataset<Row> userDF = spark.read().format("json").load("user.json");

    userDF.show();

    // save df as parquet file.
    userDF.write().format("parquet").save("user.parquet");

    // load parquet file.
    Dataset<Row> user2DF = spark.read().format("parquet").load("user.parquet");
    user2DF.show();
```
该用例中，我们从json文件加载数据，最终保存为parquet文件，然后在使用parquet文件的方式录入数据。

输出结果：
```
+---+-------+
| id|   name|
+---+-------+
|  1| zhaoyi|
|  2|hongqun|
+---+-------+

+---+-------+
| id|   name|
+---+-------+
|  1| zhaoyi|
|  2|hongqun|
+---+-------+
```

## 1.2、在文件路径上运行SQL
可以通过在SparkSession的sql方法中传入字符串
```
"select * from fieltype.`<filePath>`"
```
获取数据源。

如下例：
```json
      SparkConf sparkConf = new SparkConf().setAppName("test").set("spark.testing.memory", "2147480000").setMaster("local");
      JavaSparkContext sc = new JavaSparkContext(sparkConf);
      SparkSession spark = SparkSession.builder().appName("sql").config(sparkConf).getOrCreate();

      // sql("select * from parquet.<parquet.path>")
      Dataset<Row> userDF = spark.sql("select * from parquet.`user.parquet`");
      Dataset<Row> userDF2 = spark.sql("select * from json.`user.json`");
      userDF.show();
      userDF2.show();
```
输出结果：
```
+---+-------+
| id|   name|
+---+-------+
|  1| zhaoyi|
|  2|hongqun|
+---+-------+

+---+-------+
| id|   name|
+---+-------+
|  1| zhaoyi|
|  2|hongqun|
+---+-------+
```

## 1.3、通用存储方式
可以采用SaveMode执行存储操作，SaveMode定义了对数据的处理模式。需要注意的是，这些保存模式不使用任何锁定，不是原子操作。此外，当使用Overwrite方式执行时，在输出新数据之前原数据就已经被删除。SaveMode详细介绍如下表：

|Scala/Java|AnyLanguage|Meaning|
|-|-|-|
|SaveMode.ErrorIfExists (default)|"error" or "errorifexists" (default)|如果文件存在，抛出错误|
|SaveMode.Append|"append"|追加|
|SaveMode.Overwrite|"overwrite"|覆写|
|SaveMode.Ignore|"ignore"|数据存在，则忽略|

## 1.4、存储到持久表

## 1.5、分组、排序以及分区之后存储


# 2、Parquet文件

## 2.1、parquet文件简介
Parquet是一种流行的列式存储格式，可以高效地存储具有嵌套字段的记录。

Parquet仅仅是一种存储格式，它是语言、平台无关的，并且不需要和任何一种数据处理框架绑定，目前能够和Parquet适配的组件包括下面这些。

* 查询引擎: Hive, Impala, Pig, Presto, Drill, Tajo, HAWQ, IBM Big SQL
* 计算框架: MapReduce, **Spark**, Cascading, Crunch, Scalding, Kite
* 数据模型: Avro, Thrift, Protocol Buffers, POJOs

可以看出基本上通常使用的查询引擎和计算框架都已适配，并且可以很方便的将其它序列化工具生成的数据转换成Parquet格式。

> parquet文件是二进制格式，因此无法直接使用文本格式查看。有关parquet文件的相关介绍，可以从网上获取相关信息。有时间也会写一篇专门的文章。

## 2.2、Parquet文件的读写
Parquet格式经常在Hadoop生态圈中被使用，它也支持Spark SQL的全部数据类型。Spark SQL 提供了直接读取和存储 Parquet 格式文件的方法。
```java
 userDF.write().format("parquet").save("user.parquet");
 Dataset<Row> user2DF = spark.read().format("parquet").load("user.parquet");
```

> 由于parquet是spark SQL的数据源默认格式，因此format方法可以省略。

## 2.3、解析分区信息
对表进行分区是对数据进行优化的方式之一。在分区的表内，数据通过分区列将数据存储在不同的目录下。Parquet数据源现在能够自动发现并解析分区信息。例如，对人口数据进行分区存储，分区列为gender（性别）和country（国家），使用下面的目录结构：
```
path
└── to
    └── table
        ├── gender=male
        │   ├── ...
        │   │
        │   ├── country=US
        │   │   └── data.parquet
        │   ├── country=CN
        │   │   └── data.parquet
        │   └── ...
        └── gender=female
            ├── ...
            │
            ├── country=US
            │   └── data.parquet
            ├── country=CN
            │   └── data.parquet
            └── ...
```
通过传递path/to/table给`SQLContext.read.parquet`或`SQLContext.read.load`，Spark SQL将自动解析分区信息。返回的DataFrame的Schema如下：
```
root
|-- name: string (nullable = true)
|-- age: long (nullable = true)
|-- gender: string (nullable = true)
|-- country: string (nullable = true)
```
需要注意的是，数据的分区列的数据类型是自动解析的。当前，支持数值类型为`numeric,date,timestamp,string`。

> 应该后面官方还会逐步增加更多的类型解析支持。

自动解析分区类型的参数为：spark.sql.sources.partitionColumnTypeInference.enabled，默认值为true。如果想关闭该功能，直接将该参数设置为disabled。此时，分区列数据格式将被默认设置为string类型，不再进行类型解析。

## 2.4、Schema合并
像ProtocolBuffer、Avro和Thrift那样，Parquet也支持Schema evolution（Schema演变）。

用户可以先定义一个简单的Schema，然后逐渐的向Schema中增加列描述。通过这种方式，用户可以获取多个有不同Schema但相互兼容的Parquet文件。现在Parquet数据源能自动检测这种情况，并合并这些文件的schemas。

因为Schema合并是一个高消耗的操作，在大多数情况下并不需要，所以Spark SQL从1.5.0开始默认关闭了该功能。可以通过下面两种方式开启该功能：
1. 当数据源为Parquet文件时，将数据源选项mergeSchema设置为true
2. 设置全局SQL选项spark.sql.parquet.mergeSchema为true

# 3、Hive数据库
Apache Hive是Hadoop上的SQL引擎，Spark SQL编译时可以包含Hive支持，也可以不包含。包含Hive支持的Spark SQL可以支持Hive表访问、UDF(用户自定义函数)以及 Hive 查询语言(HiveQL/HQL)等。需要强调的 一点是，如果要在Spark SQL中包含Hive的库，并不需要事先安装Hive。一般来说，最好还是在编译Spark SQL时引入Hive支持，这样就可以使用这些特性了。如果你下载的是二进制版本的 Spark，它应该已经在编译时添加了 Hive 支持。

若要把Spark SQL连接到一个部署好的Hive上，必须把hive-site.xml复制到 Spark的配置文件目录中($SPARK_HOME/conf)。

> 即使没有部署好Hive，Spark SQL也可以运行。 需要注意的是，如果你没有部署好Hive，Spark SQL会在当前的工作目录中创建出自己的Hive 元数据仓库，叫作 metastore_db。

此外，如果你尝试使用HiveQL中的 CREATE TABLE (并非 CREATE EXTERNAL TABLE)语句来创建表，这些表会被放在你默认的文件系统中的/user/hive/warehouse目录中(如果你的 classpath 中有配好的 hdfs-site.xml，默认的文件系统就是 HDFS，否则就是本地文件系统)。

## 3.1、内嵌Hive应用
如果未配置hive-site.xml，则context会自动在当前目录中创建并创建metastore_db，该路径可以通过`spark.sql.warehouse.dir`配置。默认情况下`spark-warehouse`会在当前目录下创建。

> When working with Hive, one must instantiate SparkSession with Hive support, including connectivity to a persistent Hive metastore, support for Hive serdes, and Hive user-defined functions.

```java
SparkConf conf = new SparkConf().setAppName("sql").setMaster("local").set("spark.testing.memory", "2140000000");
        JavaSparkContext sc = new JavaSparkContext(conf);
        // warehouseLocation points to the default location for managed databases and tables
        String warehouseLocation = new File("spark-warehouse").getAbsolutePath();
        SparkSession spark = SparkSession
                .builder()
                .appName("Java Spark Hive Example")
                .config("spark.sql.warehouse.dir", warehouseLocation)
                .enableHiveSupport()
                .getOrCreate();

        spark.sql("create database if not exists my_database");

        spark.sql("CREATE TABLE IF NOT EXISTS src (key INT, value STRING) USING hive");

        // The results of SQL queries are themselves DataFrames and support all normal functions.
        Dataset<Row> sqlDF = spark.sql("SELECT key, value FROM src WHERE key < 10 ORDER BY key");

        // The items in DataFrames are of type Row, which lets you to access each column by ordinal.
        Dataset<String> stringsDS = sqlDF.map(
                (MapFunction<Row, String>) row -> "Key: " + row.get(0) + ", Value: " + row.get(1),
                Encoders.STRING());
        stringsDS.show();
```

## 3.2、外部Hive应用
如果想连接外部已经部署好的Hive，需要通过以下几个步骤。
1. 将Hive中的hive-site.xml拷贝或者软连接到Spark安装目录下的conf目录下。
2. 打开spark shell，注意带上访问Hive元数据库的JDBC客户端

# 4、JSON文件
Spark SQL 能够自动推测 JSON数据集的结构，并将它加载为一个Dataset[Row]. 可以通过SparkSession.read.json()去加载一个 Dataset[String]或者一个JSON 文件.注意，这个JSON文件不是一个传统的JSON文件，每一行都得是一个JSON串。

# 5、JDBC
Spark SQL可以通过JDBC从关系型数据库中读取数据的方式创建DataFrame，通过对DataFrame一系列的计算后，还可以将数据再写回关系型数据库中。

```java
package com.spark.jdbc;

import org.apache.spark.SparkConf;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;

import java.util.Properties;

public class JDBCTest {
    public static void main(String[] args) {
        SparkConf conf = new SparkConf().setAppName("sql").setMaster("local").set("spark.testing.memory", "2140000000");
        SparkSession spark = SparkSession
                .builder()
                .appName("JDBC Test")
                .config(conf)
                .enableHiveSupport()
                .getOrCreate();

        // 方式1
        Dataset<Row> jdbcDF = spark.read()
                .format("jdbc")
                .option("url", "jdbc:mysql://ip:port/sunrun_sdfs")
                .option("dbtable", "sunrun_sdfs.sdfs_web_config")
                .option("user", "username")
                .option("password", "password")
                .load();

        jdbcDF.show();

        // 方式2
        Properties connectionProperties = new Properties();
        connectionProperties.put("user", "username");
        connectionProperties.put("password", "password");
        Dataset<Row> jdbcDF2 = spark.read()
                .jdbc("jdbc:mysql://ip:port/sunrun_sdfs", "sdfs_web_config",  connectionProperties);
        jdbcDF2.show();

        // 指定写入mode
        jdbcDF2.write().mode(SaveMode.Overwrite).jdbc("jdbc:mysql://localhost/sunrun_sdfs?characterEncoding=UTF-8","sdfs_web_config",connectionProperties);

    }
}

```

> 存储模式saveMode参考1.3。`characterEncoding=UTF-8`指定编码格式，可以保证写入数据不会出现中文乱码。



注意，需要将相关的数据库驱动放到spark的类路径下。
```
bin/spark-shell --driver-class-path postgresql-9.4.1207.jar --jars postgresql-9.4.1207.jar
```


Spark SQL也提供JDBC连接支持，这对于让商业智能(BI)工具连接到Spark集群上以及在多用户间共享一个集群的场景都非常有用。

# 6、Avro文件

# 总结
## 1、Spark SQL的输入与输出
1、对于spark的输入需要使用`sparkSession.read`方式：
1. 通用模式 sparkSession.read.format("json").load(...) 支持的类型包括parquet json text csv orc jdbc
2. 专业模式 sparkSession.read.json、csv直接指定类型。

2、对于spark的输出需要使用`sparkSession.write`的方式。
1. 通用模式 dataFrame.write.format("json").save("path")
2. 专业模式 dataFrame.write.csv("path") 直接指定类型

3、如果直接使用通用模式，spark默认使用parquet文件格式。

4、如果需要保存成一个text文件，那么需要dataFrame里面只有一列。















