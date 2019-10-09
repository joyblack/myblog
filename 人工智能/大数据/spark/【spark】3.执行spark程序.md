# 简介
前面的章节我们已经安装好了一套spark集群，接下来我们使用该集群运行spark程序。

# 1、运行第一个程序：蒙特·卡罗算法求PI
接下来我们运行一下官方的测试用例包里的实例执行spark程序，下面的命令是使用蒙特·卡罗算法求PI。
```
# /opt/module/spark-2.4.0-bin-hadoop2.7/bin/spark-submit --class org.apache.spark.examples.SparkPi --master spark://h131:7077 --executor-memory 1G --total-executor-cores 2 /opt/module/spark-2.4.0-bin-hadoop2.7/examples/jars/spark-examples_2.11-2.4.0.jar 100
```
其中:
* --master spark://h131:7077 指定Master的地址，该地址根据您的实际环境设置；
* --executor-memory 1G 指定每个executor可用内存为1G
* --total-executor-cores 2 指定每个executor使用的cup核数为2个
* spark-examples_2.11-2.4.0.jar 是运行的jar包，该包的版本号还是根据你的实际情况去设置
* 最后的100是传递给main函数的参数值。

# 2、使用spark-shell交互执行程序
```
*** 在DFS中上传一个待处理文件
# hadoop fs -put README.md /

*** 进入交互行
# bin/spark-shell

*** 使用scala语言运行脚本，计算单词数量，并将结果同样输出到dfs上
scala> sc.textFile("hdfs://h131:8020/README.md").flatMap(_.split(" ")).map((_,1)).reduceByKey(_+_).saveAsTextFile("hdfs://h131:8020/out")

*** 查看结果
# hadoop fs -cat /out/p*
```
