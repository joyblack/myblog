# 简介

# 1、Data Types
|Data type|Value type in Scala	|API to access or create a data type|
|-|-|-|
|ByteType	|Byte	|ByteType|
|ShortType	|Short	|ShortType|
||IntegerType	|Int	|IntegerType|
|LongType	|Long	|LongType|
|FloatType	|Float	|FloatType|
|DoubleType	|Double	|DoubleType|
|DecimalType	|java.math.BigDecimal	|DecimalType|
|StringType	|String|	StringType|
|BinaryType	|Array[Byte]	|BinaryType|
|BooleanType	|Boolean	|BooleanType|
|TimestampType	|java.sql.Timestamp|	TimestampType|
|DateType	|java.sql.Date	|DateType|
|ArrayType	|scala.collection.Seq|	ArrayType(elementType, [containsNull])**Note: The default value of containsNull is true.**|
|MapType	|scala.collection.Map	|MapType(keyType, valueType, [valueContainsNull])**Note: The default value of valueContainsNull is true.**|
|StructType	|org.apache.spark.sql.Row	|StructType(fields)**Note: fields is a Seq of StructFields. Also, two fields with the same name are not allowed.**|
|StructField	|The value type in Scala of the data type of this field (For example, Int for a StructField with the data type IntegerType)|	StructField(name, dataType, [nullable])**Note: The default value of nullable is true.**|


# 2、NaN 语义

# 3、数学运算