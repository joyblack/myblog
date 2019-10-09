# 1 日志框架的选择
## 1.1 框架一览
JUL、JCL、JBoss-logging、log4j、log4j2、slf4j等。

|日志门面（抽象层）|日志实现|
|-|-|
|JCL(Jakra Commons Logging) SLF4j(Simple Logging Facade for Java) Jboss-Logging|Log4j JUL(java.util.logging) Log4j2 Logback|

左边选一个门面（抽象层），右边选一个实现，但当前最合适的选择还是：
- 日志门面：SLF4J;
- 日志实现：Logback
  
SpringBoot的选择：其底层由于是Spring框架，Spring框架默认使用的是JCL，所以SB选用的是*SLF4J*和*logback*。

# 2 SLF4j的使用
# 2.1 使用方法
以后开发的时候，日志记录方法的调用，不应该直接调用日志的实现类，而是调用日志抽象层里面的方法。
[参考slf4j官方网站](https://www.slf4j.org/manual.html)

给系统里面导入slf4j的jar和logback的实现jar
``` java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HelloWorld {
  public static void main(String[] args) {
    Logger logger = LoggerFactory.getLogger(HelloWorld.class);
    logger.info("Hello World");
  }
}
```
图示：

![slf4j系统jar演示图](https://www.slf4j.org/images/concrete-bindings.png)

每一个日志的实现框架都有自己的配置文件。使用slf4j以后，配置文件还是做成日志实现框架的配置文件；也就是说，slf4j只是提供了一个抽象标准而已。

## 2.2 遗留问题
项目A（slf4j+logback）:Spring(commons-logging)+Hiberrate(jboss-logging)。
则我们还是得需要统一日志记录，即使是别的框架也统一使用slf4j进行输出。
![](https://www.slf4j.org/images/legacy.png)

如何让系统中的日志都统一到slf4j：
1. 将系统中其他日志框架先排除出去；
2. 用中间包（如上图所示）来替换原有的日志框架；
3. 导入slf4j的实现包；

# 3 SpringBoot日志原理
## 3.1 spring-boot中底层依赖
在idea中新建一个项目后，分析pom文件的依赖，获得依赖关系图，留意其中几个比较核心的依赖部分：
``` xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter</artifactId>
      <version>2.1.1.RELEASE</version>
      <scope>compile</scope>
    </dependency>
```

spring boot中使用他来做日志功能

``` xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-logging</artifactId>
      <version>2.1.1.RELEASE</version>
      <scope>compile</scope>
    </dependency>
```
该依赖我们可以看到又依赖了不少日志框架，从依赖关系中我们可以总结：
1. spring boot的底层也是使用slf4j + logback的方式记录日志；
2. 剩下还有3个日志依赖模块，即是上一节用于将其他日志框架转为适合slf4j规范的包；
3. 中间的替换包我们打开一看，会发现其内部的报名其实和原替换类一模一样，并且源码部分具体逻辑相似，只不过工厂类之类的，用的已经是slf4j的了。
注意此部分讲解的是1.5.10版本的了，2.0以后似乎使用的是另一种设计模式，等以后慢慢研究吧。
4. 如果我们要引入其他框架，一定要把这个框架的默认日志依赖移除掉。不然会由于和SB的这些导入包产生冲突。
> 注：此部分的内容在2.0.x之后其实已经不一样了，目前还没深入研究，之后仔细查看。

# 4 Spring boot日志使用
## 4.1 简单示例
``` java
@RunWith(SpringRunner.class)
@SpringBootTest
public class Hello3ApplicationTests {
    Logger logger = LoggerFactory.getLogger(getClass());
    @Test
    public void contextLoads() {
        // 日志的级别
        // 由低到高：trace<debug<info<warn<error
        // 通过此级别关系，我们可以通过调整日志的级别：日志就只会在这个级别以及以后的更高级别才生效。
        logger.trace("this is trace log...");
        logger.debug("this is debug log...");
        logger.info("this is info log...");
        logger.warn("this is warn log...");
        logger.error("this is error log...");
    }
}
```
输出结果如下：
``` log
8-12-11 15:22:49.507  INFO 10116 --- [           main] c.z.s.hello3.Hello3ApplicationTests      : this is info log...
2018-12-11 15:22:49.507  WARN 10116 --- [           main] c.z.s.hello3.Hello3ApplicationTests      : this is warn log...
2018-12-11 15:22:49.507 ERROR 10116 --- [           main] c.z.s.hello3.Hello3ApplicationTests      : this is error log...
```
从结果我们不难看出，SB的默认日志级别是info，即只输出info及其以后更高级别的日志信息。

## 4.2 调整日志级别
找到配置文件，新增如下配置：
``` properties
logging.level.com.zhaoyi = trace
```
该配置用于将com.zhaoyi包下面的所有日志记录级别为trace，这样就可以保证测试输出的结果包含trace及其以后级别的输出了，而其他包则继续沿用logging.level.root的配置了（info）。

## 4.3 有关日志的配置
### 修改日志存放方式及路径
#### logging.file
如果我们不指定日志输出文件的话，日志的所有信息都只会在控制台输出，那么，如果我们想要将日志内容输出到具体的日志文件该怎么做呢？
很简单，使用如下配置:
``` properties
logging.file=my_log.log
```
使用该配置之后，spring boot就会将当前生成的配置信息输出到当前项目的根路径下的日志文件下，即my_log.log，当然如果您添加了具体的路径信息，则就会在指定的路径下生成日志文件，这里是默认路径，即当前项目的根目录下。

#### logging.path
当然我们也可以配置默认的日志路径（注意是路径，不是文件）
``` properties
logging.path=/log_path/
```
该配置会在当前项目所在的磁盘根目录生成一个log_path文件夹，并使用spring boot默认的日志文件名spring.log生成一个日志文件。


> 如果我们同时配置了日志文件（logging.file）和日志路径(logging.path)两个选项，那么生效的是logging.file配置。

### 修改日志的输出格式
#### logging.pattern.console
该选项用于配置控制台输出的日志格式。如：
``` properties
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss.SSS} [ %thread ] - [ %-5level ] [ %logger{50} : %line ] - %msg%n
```
其中:
* %d表示日期时间；
* %thread表示线程名；
* %-5level：级别从左显示5个字符宽度；
* %logger{50} 表示logger名字最长50个字符，否则按照句点分割；
* %msg：日志消息；
* %n是换行符；

#### logging.pattern.file
该配置用于配置日志文件记录的日志格式,其配置方式同`logging.pattern.console`。

## 4.4 高级配置
如果我们想要指定自己的相关日志配置，则需要按如下官方文档所示即可：
|Logging System|Customization|
|-|-|
|Logback|logback-spring.xml, logback-spring.groovy, logback.xml, or logback.groovy|
|Log4j2|log4j2-spring.xml or log4j2.xml|
|JDK (Java Util Logging)|logging.properties|
也就是说，我们可以直接在类路径下放入包含如下配置信息的日志配置文件logback-spring.xml，自己裁定日志配置模式:
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<!--
scan：当此属性设置为true时，配置文件如果发生改变，将会被重新加载，默认值为true。
scanPeriod：设置监测配置文件是否有修改的时间间隔，如果没有给出时间单位，默认单位是毫秒当scan为true时，此属性生效。默认的时间间隔为1分钟。
debug：当此属性设置为true时，将打印出logback内部日志信息，实时查看logback运行状态。默认值为false。
-->
<configuration scan="false" scanPeriod="60 seconds" debug="false">
    <!-- 定义日志的根目录 -->
    <property name="LOG_HOME" value="/app/log" />
    <!-- 定义日志文件名称 -->
    <property name="appName" value="atguigu-springboot"></property>
    <!-- ch.qos.logback.core.ConsoleAppender 表示控制台输出 -->
    <appender name="stdout" class="ch.qos.logback.core.ConsoleAppender">
        <!--
        日志输出格式：
			%d表示日期时间，
			%thread表示线程名，
			%-5level：级别从左显示5个字符宽度
			%logger{50} 表示logger名字最长50个字符，否则按照句点分割。 
			%msg：日志消息，
			%n是换行符
        -->
        <layout class="ch.qos.logback.classic.PatternLayout">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
        </layout>
    </appender>

    <!-- 滚动记录文件，先将日志记录到指定文件，当符合某个条件时，将日志记录到其他文件 -->  
    <appender name="appLogAppender" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 指定日志文件的名称 -->
        <file>${LOG_HOME}/${appName}.log</file>
        <!--
        当发生滚动时，决定 RollingFileAppender 的行为，涉及文件移动和重命名
        TimeBasedRollingPolicy： 最常用的滚动策略，它根据时间来制定滚动策略，既负责滚动也负责出发滚动。
        -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--
            滚动时产生的文件的存放位置及文件名称 %d{yyyy-MM-dd}：按天进行日志滚动 
            %i：当文件大小超过maxFileSize时，按照i进行文件滚动
            -->
            <fileNamePattern>${LOG_HOME}/${appName}-%d{yyyy-MM-dd}-%i.log</fileNamePattern>
            <!-- 
            可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件。假设设置每天滚动，
            且maxHistory是365，则只保存最近365天的文件，删除之前的旧文件。注意，删除旧文件是，
            那些为了归档而创建的目录也会被删除。
            -->
            <MaxHistory>365</MaxHistory>
            <!-- 
            当日志文件超过maxFileSize指定的大小是，根据上面提到的%i进行日志文件滚动 注意此处配置SizeBasedTriggeringPolicy是无法实现按文件大小进行滚动的，必须配置timeBasedFileNamingAndTriggeringPolicy
            -->
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>100MB</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <!-- 日志输出格式： -->     
        <layout class="ch.qos.logback.classic.PatternLayout">
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [ %thread ] - [ %-5level ] [ %logger{50} : %line ] - %msg%n</pattern>
        </layout>
    </appender>

    <!-- 
		logger主要用于存放日志对象，也可以定义日志类型、级别
		name：表示匹配的logger类型前缀，也就是包的前半部分
		level：要记录的日志级别，包括 TRACE < DEBUG < INFO < WARN < ERROR
		additivity：作用在于children-logger是否使用 rootLogger配置的appender进行输出，
		false：表示只用当前logger的appender-ref，true：
		表示当前logger的appender-ref和rootLogger的appender-ref都有效
    -->
    <!-- hibernate logger -->
    <logger name="com.atguigu" level="debug" />
    <!-- Spring framework logger -->
    <logger name="org.springframework" level="debug" additivity="false"></logger>



    <!-- 
    root与logger是父子关系，没有特别定义则默认为root，任何一个类只会和一个logger对应，
    要么是定义的logger，要么是root，判断的关键在于找到这个logger，然后判断这个logger的appender和level。 
    -->
    <root level="info">
        <appender-ref ref="stdout" />
        <appender-ref ref="appLogAppender" />
    </root>
</configuration> 
```
需要注意的是，在类路径下放配置文件的时候，官方也推荐命名带上spring扩展名，如Logback-spring.xml.其中：
- logback.xml: 直接就被日志框架识别了；并且如果配置节中有`springProfile`的话，logback是无法识别该配置节的，会报错；
- logback-spring.xml：日志框架就不直接加载日志的配置项，由spring boot的profile模块控制各种不同环境下的输出。
``` xml
<springProfile name="dev">
	<!-- configuration to be enabled when the "dev" profile is active -->
</springProfile>
```
若此时我们指定启动参数`--spring.profiles.active=dev`的话，该标签所包含的配置才会生效。

参考地址：https://logback.qos.ch/manual/layouts.html#coloring

# 5 切换日志框架
前面我们已经知道，sb使用的默认日志框架为slf4j+logback，倘若我们需要使用其他的日志框架该如何做呢？（其实不推荐）。可以按照slf4j的日志是配图进行相关的切换。例如用slf4j+log4j替换slf4j+logback。在pom文件中加入如下配置：
```xml
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-web</artifactId>
  <exclusions>
    <exclusion>
      <artifactId>logback-classic</artifactId>
      <groupId>ch.qos.logback</groupId>
    </exclusion>
    <exclusion>
      <artifactId>log4j-over-slf4j</artifactId>
      <groupId>org.slf4j</groupId>
    </exclusion>
  </exclusions>
</dependency>

<dependency>
  <groupId>org.slf4j</groupId>
  <artifactId>slf4j-log4j12</artifactId>
</dependency>
```
又如：我们想使用slf4j+log4j2，则需要加入如下配置：

```xml
   <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <exclusions>
                <exclusion>
                    <artifactId>spring-boot-starter-logging</artifactId>
                    <groupId>org.springframework.boot</groupId>
                </exclusion>
            </exclusions>
        </dependency>

<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>
```
也就是说，在原先的默认pom配置上，排除掉`spring-boot-starter-logging`，改用`spring-boot-starter-log4j2`即可。然后我们就在类路径下写log4j2的配置文件就可以了。