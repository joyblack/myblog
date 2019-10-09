# 简介
Spring Cloud是一个分布式的整体解决方案。Spring Cloud 为开发者提供了在分布式系统（配置管理，服务发现，熔断，路由，微代理，控制总线，一次性token，全局琐，leader选举，分布式session，集群状态）中快速构建的工具，使用Spring Cloud的开发者可以快速的启动服务或构建应用、同时能够快速和云平台资源进行对接。

## SpringCloud分布式开发五大常用组件
* 服务发现——Netflix Eureka
* 客服端负载均衡——Netflix Ribbon
* 断路器——Netflix Hystrix
* 服务网关——Netflix Zuul
* 分布式配置——Spring Cloud Config

# 快速体验
## 搭建项目环境
1. 创建空项目
2. 创建注册中心模块：eureka-server，模块选择Eureka-Server
3. 创建服务提供者模块: provider-ticket，模块选择Eureka-Discovery、web模块。（服务提供者是从服务中心注册自己）
4. 创建服务消费者模块：consumer-ticket，模块选择Eureka-Discovery、web模块。（服务提供者是从服务中心中获取提供者）

## 配置注册中心模块
1. 修改配置文件application.yml：
``` yml
server:
  port: 8761 # eureka server defort port
eureka:
  instance:
    hostname: eureka-server # eureka instance host name
  client:
    register-with-eureka: false # don't set myself to eureka, default is true
    fetch-registry: false # don't get register info to eureka server, because we will set this item to be server
    service-url:
      defaultZone: http://localhost:8761/eureka/ # register center server url, default value is http://localhost:8761/eureka/
```
> 注意我修改properties为yml，这是比较容易阅读的语言，层次更加的清晰。

2. 启动类处启用euraka server注解
``` java
package com.zhaoyi.eurekaserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

// 启用注册中心功能(enable eureka server)
@EnableEurekaServer
@SpringBootApplication
public class EurekaServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }

}
```
3. 运行项目，访问: localhost:8761 即可查看注册中心网站。接下来，我们配置服务提供者，将服务注册到注册中心。
## 配置服务提供者模块
1. 配置文件application.yml
``` yml
spring:
  application:
    name: provider-ticket
server:
  port: 8086 # provider server port
eureka:
  instance:
    prefer-ip-address: true # register server use ip style.
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/ # register center url.
```
该配置中：
* 指定了项目名为provider-ticket
* 开放端口 8086
* 设置注册到服务中心时，使用ip地址
* 设置注册中心的地址为http://localhost:8761/eureka/，即我们刚刚启动的注册中心作为注册地址。

2. 编写service，和我们之前分布式的测试例子一样，是个买票的简单程序
``` java
// 接口类
package com.zhaoyi.providerticket.service;
public interface TicketService {
    public String buy();
}
```
``` java
// 接口实现类
package com.zhaoyi.providerticket.service;

import org.springframework.stereotype.Service;

@Service
public class TicketServiceImpl implements TicketService {
    @Override
    public String buy() {
        return "《Grimgar of Fantasy and Ash》";
    }
}
```

3. 编写controller，用于显示服务运行端口以及使用买票服务
``` java
package com.zhaoyi.providerticket.controller;

import com.zhaoyi.providerticket.service.TicketService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TicketController {

    @Autowired
    TicketService ticketService;

    @Value("${server.port}")
    private Integer serverPort;

    @GetMapping("/ticket")
    public String ticket(){

        return "server:" + serverPort + " and buy a ticket:" + ticketService.buy() ;
    }
}
```

> 启动提供模块的时候，请保证注册中心模块处于运行状态。

> 为了往服务中心多注册几个服务提供者，我们修改不同端口8086以及8087，并通过maven发布多2个jar包，将其复制到外部文件夹中，然后一一使用java -jar启动起来。注意：通过启动参数修改端口号没有意义的，因为我们就是想体验返回内容的不同，所以还是改改端口，发不同的jar包好些—— 模拟多个provider服务。

多发布几个provider，同时运行，我们可以看到，注册中心注册了我们的多个provider。

这时候访问IP:8761，就可以看到我们的两个提供者实例都注册上了:

|Application|AMIs|Availability Zones|Status|
|-|-|-|-|
|PROVIDER-TICKET|n/a(2)|(2)|UP (2)-DESKTOP-Q1PPPMM:provider-ticket:8087, DESKTOP-Q1PPPMM:provider-ticket:8086|
||||

## 配置服务消费模块 
1. 配置文件配置
```yml
spring:
  application:
    name: consumer-ticket
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka
  instance:
    prefer-ip-address: false
server:
  port: 8899

```
同样的，我们开启8899端口，服务名设置为consumer-ticket，注册中心地址注册为http://localhost:8761/eureka，使用ip方式进行注册。

2. 主启动类开启发现服务功能并且添加RestTmeplate组件
``` java 
package com.zhaoyi.consumerticket;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;

@EnableDiscoveryClient
@SpringBootApplication
public class ConsumerTicketApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConsumerTicketApplication.class, args);
    }

    @LoadBalanced
    @Bean
    public RestTemplate restTemplate(){
        return new RestTemplateBuilder().build();
    }
}
```
我们开启了发现服务注解，并且在容器中添加了一个类型为RestTemplate的Bean，通过其为我们调用注册中心的具体实现。

> @LoadBalanced注解可以实现对调用服务的负载均衡访问。

3. 编写controller，消费注册中心为我们提供的服务
``` java
package com.zhaoyi.consumerticket.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
public class IndexController {
    @Autowired
    private RestTemplate restTemplate;

    @GetMapping("/buy")
    public String buy(){
        return "恭喜您，购买了" + restTemplate.getForObject("http://PROVIDER-TICKET/ticket", String.class
        );
    }
}

```

> PROVIDER-TICKET是我们注册的服务的名字，可以从你的服务中心首页的注册项的application栏目查找到;

> ticket是提供服务者监听的服务地址，即相当于我们访问服务IP:8086/ticket一样的效果。

运行效果，我们访问消费者ip:8899/buy，得到如下输出：
```
恭喜您，购买了server:8086 and buy a ticket:《Grimgar of Fantasy and Ash》
```

同时，多访问几次，你会看到8086 8087的控制台会分别相应各请求，也可以通过打印的端口号看出具体是哪个端口上的服务响应的请求，这取决于负载均衡的流量导向。


# 结束语
spring cloud算是目前分布式开发的一个很好的解决方案，还有很多内容需要我们去了解，希望本文能够为您开启一个初始的印象，迎头而上，在springcloud的使用道路上一路凯歌。
