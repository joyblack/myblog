# 简介
https://docs.spring.io/spring-hadoop/docs/2.5.1.BUILD-SNAPSHOT/reference/html/introduction.html

# 1、引入依赖
```xml
    <properties>
        <hadoop.version>2.7.7</hadoop.version>
    </properties>
    <!-- hadoop -->
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-client</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-common</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
    <dependency>
        <groupId>org.apache.hadoop</groupId>
        <artifactId>hadoop-hdfs</artifactId>
        <version>${hadoop.version}</version>
    </dependency>
```

> 注意版本和hadoop服务器安装版本保持一致。


# 2、配置文件配置
