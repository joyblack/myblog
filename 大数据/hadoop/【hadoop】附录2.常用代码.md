# POM文件
``` xml
<?xml version="1.0" encoding="UTF-8"?>
    <groupId>com.zhaoyi</groupId>
    <artifactId>firsthadoop</artifactId>
    <version>1.0-SNAPSHOT</version>
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <hadoop.version>2.7.3</hadoop.version>
    </properties>
    <dependencies>
    <!-- 引入hadoop相关依赖 -->
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
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
            <scope>compile</scope>
        </dependency>
    </dependencies>
</project>
```

```java
public static Text transformTextToUTF8(Text text, String encoding) {
String value = null;
try {
value = new String(text.getBytes(), 0, text.getLength(), encoding);
} catch (UnsupportedEncodingException e) {
e.printStackTrace();
}
return new Text(value);
}
```

