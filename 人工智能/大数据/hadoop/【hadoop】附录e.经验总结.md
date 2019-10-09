
# 1、经验总结
## 1.1、新旧API区别
mapreduce包下的类是新版API，mapred是旧版API。因此，我们导入包的时候为了保证不出现错误，最好都是用形如`org.apache.hadoop.mapreduce...`的包。

