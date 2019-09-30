# 简介
前面我们已经学习了如何在RabbitMQ的安装及简单使用以及在SpringBoot中集成RabbitMQ组件，接下来我们来学习RabbitMQ的一些高级特性。

# RabbitMQ监听器
1、添加Book

为了测试监听器的使用场景，我们先构建一个bean。
##### bean/Book.class
``` java
package com.zhaoyi.bweb.bean;

public class Book {
    private String author;
    private String bookName;
    private String introduce;

    public Book() {
    }

    public static Book defaultBook(){
        return new Book("红楼梦","曹雪芹", "四大名著之一...");
    }

    public Book(String bookName, String author, String introduce) {
        this.author = author;
        this.bookName = bookName;
        this.introduce = introduce;
    }

    public String getIntroduce() {
        return introduce;
    }

    public void setIntroduce(String introduce) {
        this.introduce = introduce;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getBookName() {
        return bookName;
    }

    public void setBookName(String bookName) {
        this.bookName = bookName;
    }

    @Override
    public String toString() {
        return "Book{" +
                "author='" + author + '\'' +
                ", bookName='" + bookName + '\'' +
                ", introduce='" + introduce + '\'' +
                '}';
    }
}
```
> 使用我们上一节中学习使用的项目进行接下来的操作。

在应用中使用RabbitMQ的监听器。

2、在主程序处开启基于注解的RabbitMQ模式

##### BwebApplication.class
``` java
package com.zhaoyi.bweb;

import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@EnableRabbit
@SpringBootApplication
public class BwebApplication {
    public static void main(String[] args) {
        SpringApplication.run(BwebApplication.class, args);
    }
}
```

3、编写一个Service，监听消息队列
##### service/BookService.class
``` java
package com.zhaoyi.bweb.service;

import com.zhaoyi.bweb.bean.Book;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;

@Service
public class BookService {

    @RabbitListener(queues = {"joyblack.news"})
    public void listernerBook(Book book){
        System.out.println("receive a message:");
        System.out.println(book);
    }
}

```

> 该监听方法会将消息体数据映射到Book对象，如果数据类型不一致会出现应用程序异常。

该service中的listernerBook监听了我们定制的MQ服务的joyblack.news的队列信息，当joyblack.news接受到信息的时候，会调用该方法。

4、 在测试用例中添加一个测试用例，用于向`joyblack.news`中发送包含Book数据的消息。

##### test/BwebApplicationTests
``` java
    @Autowired
    RabbitTemplate rabbitTemplate;

    @Test
    public void send(){
        rabbitTemplate.convertAndSend("exchange.direct", "joyblack.news", Book.defaultBook());
    }
```

运行主程序。

然后运行我们的测试运行，可以看到，每当我们运行一次测试用例，就会触发service的listernerBook的一次调用，并打印结果：
```
...
receive a message:
Book{author='曹雪芹', bookName='红楼梦', introduce='四大名著之一...'}
receive a message:
Book{author='曹雪芹', bookName='红楼梦', introduce='四大名著之一...'}
....
```

也就是说，通过@EnableRabbit以及@RabbitListener两个注解，我们就可以在springboot实现简单的消息监听了。

当然，我们也可以有其他的接收消息的模式，比如获取消息全部内容:
##### service/BookService.class
``` java
package com.zhaoyi.bweb.service;

import com.zhaoyi.bweb.bean.Book;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;

@Service
public class BookService {

//    @RabbitListener(queues = {"joyblack.news"})
//    public void listernerBook(Book book){
//        System.out.println("receive a message:");
//        System.out.println(book);
//    }

    @RabbitListener(queues = {"joyblack.news"})
    public void listernerBook(Message message){
        System.out.println("receive a message:");
        System.out.println(message);
    }
}
```

发送消息后打印的结果为：
```
receive a message:
(Body:'{"author":"曹雪芹","bookName":"红楼梦","introduce":"四大名著之一..."}' MessageProperties [headers={__TypeId__=com.zhaoyi.bweb.bean.Book}, contentType=application/json, contentEncoding=UTF-8, contentLength=0, receivedDeliveryMode=PERSISTENT, priority=0, redelivered=false, receivedExchange=exchange.direct, receivedRoutingKey=joyblack.news, deliveryTag=1, consumerTag=amq.ctag-a8Co2RP7og21nB5A6R5QbQ, consumerQueue=joyblack.news])
```
即包含了整个消息内容。

# 管理组件AmqpAdmin
前面我们已经通过MQ的组件测试了很多有意思的功能，但是别忘了，我们很多组件，比如交换器、消息队列等，都是我们通过RabbitMQ的管理网站事先创建的。那么，我们会有这样的疑问，可不可以通过RabbitMQ提供的什么组件帮我们在应用程序中完成这样的操作呢？答案是能！

这个组件就是我们这一章节将要讲到的AmqpAdmin。通过AmqpAdmin我们可以创建交换器、消息队列以及绑定规则等。

要使用AmqpAdmin很简单，还记得我们之前讲过的自动配置类吗，他提供的两个重要组件之一就是AmqpAdmin。我们直接在应用程序中注入该组件就可以使用了。

## 创建交换器
Exchange.inteface是MQ组件中定义的一个接口
##### org.springframework.amqp.core.Exchange
``` java
package org.springframework.amqp.core;

import java.util.Map;

public interface Exchange extends Declarable {
    String getName();

    String getType();

    boolean isDurable();

    boolean isAutoDelete();

    Map<String, Object> getArguments();

    boolean isDelayed();

    boolean isInternal();
}
```

我们查看该接口的实现类有5个（其实有一个抽象类作为中间件），他们分别是DirectExchange、FanoutExchange、CustomExchange、TopicExchange以及HeadersExchange。其中有2个我们不用在意，其他三个刚好对应我们之前所讲到的3种交换器类型，因此，要创建交换器，直接创建对应类型的交换器即可，例如，我们创建一个direct类型的交换器，并命名为exchange.myDirect.
##### Test.class
``` java
package com.zhaoyi.bweb;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.amqp.core.AmqpAdmin;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class BwebApplicationTests {

    @Autowired
    AmqpAdmin amqpAdmin;

    @Test
    public void createExchange(){
        amqpAdmin.declareExchange(new DirectExchange("exchange.myDirect"));
        System.out.println("create exchange success.");
    }
}


```
运行该测试用例，我们就可以在管理网站处的Exchanges选项卡查看到新创建的direct类型的exchange了。

> amqpAdmin.declarexxxx可以创建xxx类型的RabbitMQ组件。

同理，我们可以通过amqpAdmin.declareQueue创建其他的组件，提供的参数一一对应于我们配置对应组件时指定的那些配置选项。

## 创建队列
##### Test.class
``` java
    @Test
    public void createQueue(){
        amqpAdmin.declareQueue(new Queue("queue.myQueue", true));
        System.out.println("create Queue success.");
    }
```
该测试用例创建了一个name=queue.myQueue，以及durable为true（即可持久化）的队列。

## 创建绑定规则
创建绑定规则时我们需要查看一下Binding类对应的方法参数:
##### org.springframework.amqp.core.Binding
``` java
    public Binding(String destination, Binding.DestinationType destinationType, String exchange, String routingKey, Map<String, Object> arguments) {
		// 目的地
        this.destination = destination;
		// 目的的类型
        this.destinationType = destinationType;
		// 交换器
        this.exchange = exchange;
		// 路由键
        this.routingKey = routingKey;
		// 额外参数
        this.arguments = arguments;
    }
```

因此，我们对应这些参数进行配置就可以了，你也可以感觉得到，这些参数都是和我们的管理网站的可视化配置一一对应起来的：
##### Test.class
``` java
    @Test
    public void createBinding(){
        amqpAdmin.declareBinding(new Binding("queue.myQueue",
                Binding.DestinationType.QUEUE,
                "exchange.myDirect",
                "queue.myQueue",
                null
                ));
        System.out.println("create Binding success.");
    }
```

可以看到，我们定义了一个绑定规则，他是绑定在交换器exchange.myDirect上，路由键为queue.myQueue，并指向目的地为queue.myQueue的队列。

现在，查看管理网站，可以清晰的看到我们这次创建的三个组件，以及他们之间的绑定关系。

> 注意路由键这个属性，通常情况下，我们会将其命名为和目的地队列一样的名称，但请不要混淆二者。如果你的应用足够复杂，显然是很多绑定规则，并且路由键是多种多样的。

>  amqpAdmin.deleteXxx 可以帮助我们删除指定名称的交换器和队列，大家可以自己尝试使用。

