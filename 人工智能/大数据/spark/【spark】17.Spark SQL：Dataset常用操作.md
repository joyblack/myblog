# 简介
本章节讲述DataFrame的常用操作。DataSet的操作方式十分的优雅，它支持DSL Query风格以及SQL的操作方式。不过在Java中，我们比较关注的还是SQL风格的操作方式。

# 1、SQL风格
```java
    JavaSparkContext sc = new JavaSparkContext(conf);
    SparkSession spark = SparkSession.builder().appName("sql").config(conf).getOrCreate();
    JavaRDD<User> rdd = sc.parallelize(Arrays.asList(new User(1, "zhaoyi"), new User(2, "hongqun"), new User(3,"akuya")));
    Dataset<Row> userDataset = spark.createDataFrame(rdd, User.class);
    // Register the DataFrame as a SQL temporary view
    userDataset.createOrReplaceTempView("user");
    Dataset<Row> firstUserDataset = spark.sql("select * from user where id = 1");
    firstUserDataset.show();
```
最终输出结果：
```
+---+------+
| id|  name|
+---+------+
|  1|zhaoyi|
+---+------+
```
> 在使用sql查询之前，需要将Dataset注册为临时表，这样就可以执行查询了。






