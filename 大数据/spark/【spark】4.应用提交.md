# 简介

# 1、本地运行
可以在idea中直接运行spark程序。

# 2、服务器运行
1、提交spark的顺序，编写pom文件的build：
```xml
<build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.2</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>

            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.1.1</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.spark.WordCount</mainClass>
                        </manifest>
                    </archive>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```
2、将带有依赖的包上传到master节点 执行：
```
../bin/spark-submit --master spark://h131:7077 --executor-memory 1G --total-executor-cores 2 --class com.spark.WordCount spark-learn-1.0-SNAPSHOT-jar-with-dependencies.jar hdfs://h131:8020/README.md hdfs://h131:8020/out1
```
其中指定顺序可以这样牢记：
```
--master
--executor-memory
--total-executor-cores
--class
jar
Main参数
```
