# 简介
既然讲到了SQL相关，那么无论如何，都逃不掉UDF这个概念。那么，在Spark SQL中如何使用UDF呢。

强类型的Dataset和弱类型的DataFrame都提供了相关的聚合函数， 如 count()，countDistinct()，avg()，max()，min()。除此之外，用户可以设定自己的自定义聚合函数。

# 1、弱类型聚合函数

通过继承UserDefinedAggregateFunction来实现用户自定义聚合函数。下面展示一个求平均工资的自定义聚合函数。

1、json文件

```json
{"name":"zhaoyi","score":80}
{"name":"hongqun","score":90}
```

2、聚合函数
```java
package com.spark.sql;

import java.util.ArrayList;
import java.util.List;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.expressions.MutableAggregationBuffer;
import org.apache.spark.sql.expressions.UserDefinedAggregateFunction;
import org.apache.spark.sql.types.DataType;
import org.apache.spark.sql.types.DataTypes;
import org.apache.spark.sql.types.StructField;
import org.apache.spark.sql.types.StructType;

public class MyAverage extends UserDefinedAggregateFunction {
        private StructType inputSchema;
        private StructType bufferSchema;

        public MyAverage() {
            // inputSchema
            List<StructField> inputFields = new ArrayList<>();
            inputFields.add(DataTypes.createStructField("inputColumn", DataTypes.LongType, true));
            inputSchema = DataTypes.createStructType(inputFields);

            // bufferSchema
            List<StructField> bufferFields = new ArrayList<>();
            bufferFields.add(DataTypes.createStructField("sum", DataTypes.LongType, true));
            bufferFields.add(DataTypes.createStructField("count", DataTypes.LongType, true));
            bufferSchema = DataTypes.createStructType(bufferFields);
        }

        // 输入参数的数据类型
        public StructType inputSchema() {
          return inputSchema;
        }

        // 缓冲输入类型
        public StructType bufferSchema() {
          return bufferSchema;
        }
        // 返回的参数类型
        public DataType dataType() {
          return DataTypes.DoubleType;
        }
        // 对于相同的输入是否产生相同的输出
        public boolean deterministic() {
          return true;
        }

        // 初始化缓冲区数据：update(index, value)
        public void initialize(MutableAggregationBuffer buffer) {
          buffer.update(0, 0L);
          buffer.update(1, 0L);
        }

        // 相同的Execute间的数据合并
        public void update(MutableAggregationBuffer buffer, Row input) {
          if (!input.isNullAt(0)) {
            long updatedSum = buffer.getLong(0) + input.getLong(0);
            long updatedCount = buffer.getLong(1) + 1;
            buffer.update(0, updatedSum);
            buffer.update(1, updatedCount);
          }
        }

        // 不同Execute间的数据合并
        public void merge(MutableAggregationBuffer buffer1, Row buffer2) {
          long mergedSum = buffer1.getLong(0) + buffer2.getLong(0);
          long mergedCount = buffer1.getLong(1) + buffer2.getLong(1);
          buffer1.update(0, mergedSum);
          buffer1.update(1, mergedCount);
        }

        // 计算最终结果
        public Double evaluate(Row buffer) {
          return ((double) buffer.getLong(0)) / buffer.getLong(1);
        }
}

```

执行Main函数
```java
package com.spark.sql;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaSparkContext;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;

public class UDFTest {
    public static void main(String[] args) {
        SparkConf conf = new SparkConf().setAppName("sql").setMaster("local").set("spark.testing.memory", "2140000000");
        JavaSparkContext sc = new JavaSparkContext(conf);
        SparkSession spark = SparkSession.builder().appName("sql").config(conf).getOrCreate();

        // Register the function to access it
        spark.udf().register("myAverage", new MyAverage());

        Dataset<Row> df = spark.read().json("employees.json");
        df.createOrReplaceTempView("employees");
        df.show();

        Dataset<Row> result = spark.sql("SELECT myAverage(score) as average_salary FROM employees");
        result.show();
    }
}
```

# 2、强类型聚合函数
通过继承Aggregator来实现强类型自定义聚合函数，同样是求平均分数。

```java

import java.io.Serializable;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Encoder;
import org.apache.spark.sql.Encoders;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.TypedColumn;
import org.apache.spark.sql.expressions.Aggregator;

public static class Employee implements Serializable {
  private String name;
  private long salary;

  // Constructors, getters, setters...

}

public static class Average implements Serializable  {
  private long sum;
  private long count;

  // Constructors, getters, setters...

}

public static class MyAverage extends Aggregator<Employee, Average, Double> {
  // A zero value for this aggregation. Should satisfy the property that any b + zero = b
  public Average zero() {
    return new Average(0L, 0L);
  }
  // Combine two values to produce a new value. For performance, the function may modify `buffer`
  // and return it instead of constructing a new object
  public Average reduce(Average buffer, Employee employee) {
    long newSum = buffer.getSum() + employee.getSalary();
    long newCount = buffer.getCount() + 1;
    buffer.setSum(newSum);
    buffer.setCount(newCount);
    return buffer;
  }
  // Merge two intermediate values
  public Average merge(Average b1, Average b2) {
    long mergedSum = b1.getSum() + b2.getSum();
    long mergedCount = b1.getCount() + b2.getCount();
    b1.setSum(mergedSum);
    b1.setCount(mergedCount);
    return b1;
  }
  // Transform the output of the reduction
  public Double finish(Average reduction) {
    return ((double) reduction.getSum()) / reduction.getCount();
  }
  // Specifies the Encoder for the intermediate value type
  public Encoder<Average> bufferEncoder() {
    return Encoders.bean(Average.class);
  }
  // Specifies the Encoder for the final output value type
  public Encoder<Double> outputEncoder() {
    return Encoders.DOUBLE();
  }
}

Encoder<Employee> employeeEncoder = Encoders.bean(Employee.class);
String path = "examples/src/main/resources/employees.json";
Dataset<Employee> ds = spark.read().json(path).as(employeeEncoder);
ds.show();
// +-------+------+
// |   name|salary|
// +-------+------+
// |Michael|  3000|
// |   Andy|  4500|
// | Justin|  3500|
// |  Berta|  4000|
// +-------+------+

MyAverage myAverage = new MyAverage();
// Convert the function to a `TypedColumn` and give it a name
TypedColumn<Employee, Double> averageSalary = myAverage.toColumn().name("average_salary");
Dataset<Double> result = ds.select(averageSalary);
result.show();
```





