1、当我们不指定2NN的地址时，默认会和NN处在同一台机器上。

2、mapreduce包下的类是新版API，mapred是旧版API。
因此，我们导入包的时候为了保证不出现错误，最好都是用形如`org.apache.hadoop.mapreduce...`的包。