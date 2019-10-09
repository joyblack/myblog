# 简介
在Java应用中，绝大多数情况下都是通过同步的方式来实现交互处理的；但是在处理与第三方系统交互的时候，容易造成响应迟缓的情况，之前大部分都是使用多线程来完成此类任务。

> 其实，在Spring 3.x之后，就已经内置了@Async来完美解决这个问题。

> 两个注解：@EnableAysnc、@Aysnc

# 使用步骤
使用异步任务的方式很简单，只需：
1. 启动类开启异步任务
@EnableASync
2. 服务方法标注异步注解 @Async

# 测试
创建一个web项目。

1. 创建一个服务类，为其添加睡眠程序，模拟其执行缓慢：
##### service/HelloService.class
``` java
package com.zhaoyi.cweb.service;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class HelloService {


    public void doSomething(){
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}


```

2. 创建一个controller，映射hello地址并调用service方法：
##### controller/HelloController.class
``` java
package com.zhaoyi.cweb.controller;

import com.zhaoyi.cweb.service.HelloService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class HelloController {

    @Autowired
    HelloService helloService;

    @GetMapping("/hello")
    public String hello(){
        helloService.doSomething();
        return "hello";
    }
}

```
显然，我们访问/hello的话，要等待3秒才能获得结果。因为
doSomething方法占用了太多的时间。


3. 我们添加异步处理，首先需要在启动类处添加开启异步任务注解。

###### App.class
``` java
package com.zhaoyi.cweb;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@EnableAsync
@SpringBootApplication
public class CwebApplication {

    public static void main(String[] args) {
        SpringApplication.run(CwebApplication.class, args);
    }

}
```

4. 然后从服务方法处添加异步注解
##### service/HelloService.class
``` java
package com.zhaoyi.cweb.service;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Service
public class HelloService {


    @Async
    public void doSomething(){
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}

```
接下来我们运行项目，访问同样的地址就可以立马得到反馈了。

> 异步任务会被java单独开启的线程执行，从而保证不阻塞原进程。

