# 简介
监控是我们开发服务网站无法绕开的话题。springboot也为我们带来了关于监控的解决方案。

通过引入spring-boot-starter-actuator，可以使用Spring Boot为我们提供的准生产环境下的应用监控和管理功能。我们可以通过HTTP，JMX，SSH协议来进行操作，自动得到审计、健康及指标信息等。

引入步骤也很简单。
1. 引入spring-boot-starter-actuator
2. 通过http方式访问监控端点
3. 可进行shutdown（POST 提交，此端点默认关闭）

[官方参考文档](https://docs.spring.io/spring-boot/docs/2.1.1.RELEASE/reference/htmlsingle/#production-ready)

# 快速体验
1. 搭建基本环境 创建项目，选择的模块有 web,core-DevTools,Ops-Actuator.

2. 查阅官方文档我们可以知道，web应用和JMX不一样。默认情况下除了health，其他的可视化接口都是关闭的，因此我们需要配置开启这些终端。

``` yml
management:
  endpoints:
    web:
      exposure:
        include: "*"
```

3. 启动项目，我们就可以通过`http://localhost:8080/actuator/终端名称`等方式访问自己想知道的具体终端的信息了，例如目标设置为beans获取我们容器中所有的bean信息。以下是对照表

|端点名|描述|
|-|-|
|auditevents|Exposes audit events information for the current application.|
|beans|Displays a complete list of all the Spring beans in your application.|
|caches|Exposes available caches.|
|conditions|Shows the conditions that were evaluated on configuration and auto-configuration classes and the reasons why they did or did not match.|
|configprops|Displays a collated list of all @ConfigurationProperties|
|env|Exposes properties from Spring’s ConfigurableEnvironment.|
|flyway|Shows any Flyway database migrations that have been applied.|
|health|Shows application health information.|
|httptrace|Displays HTTP trace information (by default, the last 100 HTTP request-response exchanges).|
|info|Displays arbitrary application info.|
|integrationgraph|Shows the Spring Integration graph.|
|loggers|Shows and modifies the configuration of loggers in the application.|
|metrics|Shows ‘metrics’ information for the current application.|
|`mappings`|Displays a collated list of all @RequestMapping paths.|
|`scheduledtasks`|Displays the scheduled tasks in your application.|
|sessions|Allows retrieval and deletion of user sessions from a Spring Session-backed session store. Not available when using Spring Session’s support for reactive web applications.|
|shutdown|Lets the application be gracefully shutdown.|
|threaddump|Performs a thread dump.|
|||

如果是web应用，还会有如下更多的可查看终端
|端点名|描述|
|-|-|
|heapdump|Returns an hprof heap dump file.|
|jolokia|Exposes JMX beans over HTTP (when Jolokia is on the classpath, not available for WebFlux).|
|logfile|Returns the contents of the logfile (if logging.file or logging.path properties have been set). Supports the use of the HTTP Range header to retrieve part of the log file’s content.|
|prometheus|Exposes metrics in a format that can be scraped by a Prometheus server.|
|||

> 注意不同的actuator版本可能会有不一致的情况;

> Metrics是一个给JAVA服务的各项指标提供度量工具的包,在JAVA代码中嵌入Metrics代码,可以方便的对业务代码的各个指标进行监控;

> threaddump在1.x版本为dump


其中，info信息默认是没有输出的，但是我们可以通过配置文件填写，例如我们可以在配置文件中添加这样的配置

``` yml
info:
  app:
    id: hello-1
    name: hello
```

重启项目之后，我们查看info信息，就可以得到如下的输出了：
``` json
{"app":{"id":"hello-1","name":"hello"}}
```

> 当然很多继承了InfoProperties的类的相关配置都会读取到该输出中，例如git.xxx.xxx等，大家可以自己去测试。

我们还可以远程关闭应用，即通过shutdown终端，该终端默认是不启用的，我们要通过配置开启。
``` yml
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    shutdown:
      enabled: true
```

重启服务，访问shutdown终端，注意需要提供的是post请求，也就是说，直接通过url是没办法关闭的，可以借助一些http客户端工具辅助完成，比如我们之前提到的postman等。我们就可以远程关闭应用了，应用程序之前还会为我们打招呼，很可爱。
``` json
{
    "message": "Shutting down, bye..."
}
```

# 定制端点

我们可以修改某些端点的访问路径，通过
management.endpoints.端点.属性=xxx
例如`management.endpoint.beans.cache.time-to-live=10s`可以配置bean端口的响应时间等。

> 您可以通过management.endpoint.web相关的属性进行配置，例如修改默认的context地址（base-dir=/actuator）等，都可以参考官方文档一一测试。

# 自定义健康状态组件
 可以从spring-boot-actuator中查看这些为我们提供的监控组件。官网文档告诉我们，如果我们引入了某个组件，例如redis，系统就会在health之中添加相关的监控结果。
 
 如果我们配置了这个选项。
 ``` properties
management.endpoint.health.show-details=always
 ```
 可取值never(默认)、when-authorized(只允许认证用户查看,可以通过management.endpoint.health.roles.配置相应的角色)、always,所有用户都可以查看。

 这样，系统就会为我们监控我们提供的组件的监控信息，不配置detail的话看不到这些详细信息。

```
{"status":"UP","details":{"diskSpace":{"status":"UP","details":{"total":141966430208,"free":2797314048,"threshold":10485760}},"redis":{"status":"UP","details":{"version":"3.0.503"}}}}
```

> You can disable them all by setting the ```management.health.defaults.enabled ``` property.

现在我们开始自定义自己的j健康指示器
1. 编写一个指示器，实现HealthIndicator接口
2. 指示器的名字必须为xxxHealthIndicator;
3. 加入到容器中。

添加类health.MyHealthIndicator
``` java
package com.example.demo.health;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;

@Component
public class MyHealthIndicator implements HealthIndicator {
    @Override
    public Health health() {
        // 自定义的检查方法

        // 返回up代表健康,down代表异常
        return Health.up().withDetail("key","this is we need to say message").build();
    }
}
```

访问actuator/health即可看到我们的输出。
``` json
{"status":"UP","details":{"my":{"status":"UP","details":{"key":"this is we need to say message"}},"diskSpace":{"status":"UP","details":{"total":141966430208,"free":3067961344,"threshold":10485760}},"redis":{"status":"UP","details":{"version":"3.0.503"}}}}
```

可以看到，输出结构的第一层键值是我们的健康指示器的前缀，例如my，而status则取决于我们返回的是up还是down，detail中包含的数据就是我们定义在withDetail方法中的数据。

具体的实现，有兴趣的同学可以查看源码了解。

至此，有关springboot的基础内容就到此为止了。

—— 希望大家一路顺风，赞美这些授课的教师们。




