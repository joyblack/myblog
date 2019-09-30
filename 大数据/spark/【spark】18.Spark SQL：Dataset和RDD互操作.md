# 简介
Dataset和RDD之间的转换支持两种方式，一种是通过反射实现；另一种则是通过指定schema实现。

# 1、通过反射
```java
    SparkConf conf = new SparkConf().setAppName("sql").setMaster("local").set("spark.testing.memory", "2140000000");
    JavaSparkContext sc = new JavaSparkContext(conf);
    SparkSession spark = SparkSession.builder().appName("sql").config(conf).getOrCreate();
    JavaRDD<User> rdd = sc.parallelize(Arrays.asList(new User(1, "zhaoyi"), new User(2, "hongqun"), new User(3,"akuya")));

    // 通过反射获取rdd的元素信息生成df
    Dataset<Row> userDF = spark.createDataFrame(rdd, User.class);

    // 注册临时表
    userDF.createOrReplaceTempView("user");

    // 1. 可以通过索引访问数据列信息，首先需要定义一个解码器
    Encoder<String> stringEncoder = Encoders.STRING();
    Dataset<String> nameDF = userDF.map((MapFunction<Row, String>) row -> "Name: " + row.getString(1), stringEncoder);
    nameDF.show();
    // +-------------+
    // |        value|
    // +-------------+
    // | Name: zhaoyi|
    // |Name: hongqun|
    // |  Name: akuya|
    // +-------------+

    // 2. 也可以通过列名称获取列信息
    Dataset<String> nameDF2 = userDF.map((MapFunction<Row, String>) row -> "Name: " + row.<String>getAs("name"), stringEncoder);
    nameDF2.show();
    // +-------------+
    // |        value|
    // +-------------+
    // | Name: zhaoyi|
    // |Name: hongqun|
    // |  Name: akuya|
    // +-------------+
```

# 2、通过指定Schema
如果反射的元素类无法具体指定，那么通过定义Schema来创一个使用该Schema的DF使用。创建步骤如下：
1. 创建一个多行结构的RDD;
2. 创建用StructType类型的类(即schema)，用来表示的行结构信息；
```java
List<StructField> fields = Arrays.asList(
    DataTypes.createStructField("col1", DataTypes.IntegerType,true),
    DataTypes.createStructField("col2", DataTypes.IntegerType,true)
);
StructType schema = DataTypes.createStructType(fields);
```
3. 通过SparkSession提供的createDataFrame方法来应用Schema。


具体示例如下：
```java
        SparkConf conf = new SparkConf().setAppName("sql").setMaster("local").set("spark.testing.memory", "2140000000");
        JavaSparkContext sc = new JavaSparkContext(conf);
        SparkSession spark = SparkSession.builder().appName("sql").config(conf).getOrCreate();

        // 1.创建一个多行结构的RDD
        JavaRDD<Row> rdd = sc.parallelize(Arrays.asList(RowFactory.create(1, "zhaoyi"),
                RowFactory.create(2, "hezhen"),
                RowFactory.create(3, "akuya"),
                RowFactory.create(4, "huihui"),
                RowFactory.create(4, "crasetina")
        ));

        // 2.创建用StructType类型的类(即schema)，用来表示的行结构信息
        List<StructField> fields = Arrays.asList(DataTypes.createStructField("id", DataTypes.IntegerType,true),
                DataTypes.createStructField("name", DataTypes.StringType,true)
                );
        StructType schema = DataTypes.createStructType(fields);

        // 3.通过SparkSession提供的createDataFrame方法来应用Schema
        Dataset<Row> userDF = spark.createDataFrame(rdd, schema);

        userDF.show();
        // +---+---------+
        // | id|     name|
        // +---+---------+
        // |  1|   zhaoyi|
        // |  2|   hezhen|
        // |  3|    akuya|
        // |  4|   huihui|
        // |  4|crasetina|
        // +---+---------+
```
只要注意几个方法就可以了：
* RowFactory可以用来创建Row对象
* DataTypes有两个静态方法：`createStructField(String name, DataType dataType, boolean nullable)`用于创建列相关的信息；`createStructType(List<StructField> fields)`用于创建行相关信息（粗略理解），接下来，在使用我们之前讲过的创建DF的多个重载方法之一的`createDataFrame(final JavaRDD<Row> rowRDD, final StructType schema)`就可以完成rdd到df的转换了。


# 转换总结
在spark支持的其他语言中，可能会考虑三者之间的转化问题，但对于java来说，其实只需考虑RDD和他们之间的转换就可以了。

RDD、DataFrame、Dataset三者有许多共性，有各自适用的场景常常需要在三者之间转换。

DataFrame/Dataset转RDD，spark提供了一个rdd方法，可以直接使用：
```java
RDD<Row> rdd = userDF.rdd();
```
