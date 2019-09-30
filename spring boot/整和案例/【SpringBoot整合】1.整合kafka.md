# 简介
kafka简介。

再次之前，先安装kafka服务。

参考文档：

1. [spring for kafka文档](https://docs.spring.io/spring-kafka/docs/2.2.4.RELEASE/reference/) 

2. [spring boot for kafka文档](https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-messaging.html#boot-features-kafka)

# 1、依赖包
```xml
    <!-- kafka -->
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
```

# 2、配置组件
> 注意一些配置可以移除到配置文件中。


## 2.1、配置生产者组件
```java
package com.sunrun.emailanalysis.config;

import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableKafka
public class KafkaProducerConfigure {

    @Bean
    public ProducerFactory<String, String> producerFactory() {
        return new DefaultKafkaProducerFactory<>(producerConfigs());
    }

    /**
     * Kafka配置信息
     * @return
     */
    @Bean
    public Map<String, Object> producerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "10.21.1.24:9092");
        props.put(ProducerConfig.RETRIES_CONFIG, 0);
        props.put(ProducerConfig.BATCH_SIZE_CONFIG, 16384);
        props.put(ProducerConfig.LINGER_MS_CONFIG, 1);
        props.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return props;
    }

    /**
     * Spring Kafka的template
     * @return
     */
    @Bean
    public KafkaTemplate<String, String> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }

}
```

## 2.2、配置消费者组件
```java
package com.sunrun.emailanalysis.config;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.config.KafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.ConcurrentMessageListenerContainer;

import java.util.HashMap;
import java.util.Map;

@EnableKafka
@Configuration
public class KafkaConsumerConfig {
    @Bean
    KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, String> factory = new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.setConcurrency(3);
        factory.getContainerProperties().setPollTimeout(3000);
        return factory;
    }

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(consumerConfigs());
    }

    @Bean
    public Map<String, Object> consumerConfigs() {
        Map<String, Object> propsMap = new HashMap<>();
        propsMap.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "10.21.1.24:9092");
        propsMap.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
        propsMap.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, "100");
        propsMap.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, "15000");
        propsMap.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        propsMap.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        propsMap.put(ConsumerConfig.GROUP_ID_CONFIG, "group1");
        propsMap.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        return propsMap;
    }
}
```

定义了ProducerConfig和ConsumerConfig后我们需要实现具体的生产者和消费者。其中，我们在KafkaListenerContainerFactory中使用了ConcurrentKafkaListenerContainer， 我们将使用多线程消费消息。

# 3、编写实例
定义好了组件后，我们就可以在程序中使用它们了。

## 3.1、编写Service
```java
package com.sunrun.emailanalysis.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.util.concurrent.ListenableFutureCallback;

@Service
public class MyProducerService {
    @Autowired
    private KafkaTemplate template;

    //发送消息方法
    public void send(String topic, String message) {
        ListenableFuture<SendResult<String, String>> future = template.send(topic,message);
        future.addCallback(new ListenableFutureCallback<SendResult<String, String>>() {
            @Override
            public void onSuccess(SendResult<String, String> result) {
                System.out.println("msg OK." + result.toString());
            }

            @Override
            public void onFailure(Throwable ex) {
                System.out.println("msg send failed: ");
            }
        });
    }
}
```

## 3.2、编写Controller
```java
package com.sunrun.emailanalysis.controller;

import com.sunrun.emailanalysis.service.MyProducerService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("kafka")
public class KafkaController {

    @Autowired
    private MyProducerService myProducerService;
    @RequestMapping("index")
    public void index(){
        myProducerService.send("test","你好啊，整合Spring KAFKA");
    }
}
```
## 3.3、编写监听者
我们可以使用我们的consumer配置创建消费者组件(@Compenent、@Bean)，Spring项目启动的时候加载消费者。

还可以直接使用`@KafkaListener(topics = {"topicName"})`注解。

```java
package com.sunrun.emailanalysis.cosumer;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class EAConsumer {
    @KafkaListener(topics = {"test"})
    public void receive(String message){
        System.out.println("接收到信息:" + message);
    }
}
```

> 在spring kafka中，可以把cosumer看做是listener。

接下来启动SpringBoot项目，输入网址
```
http://127.0.0.1/kafka/index
```
即可激活生产消息的方式，在控制台由监听程序打印出发送的消息
```
msg OK.SendResult [producerRecord=ProducerRecord(topic=test, partition=null, headers=RecordHeaders(headers = [], isReadOnly = true), key=null, value=你好啊，整合Spring KAFKA, timestamp=null), recordMetadata=test-0@6]
接收到信息:你好啊，整合Spring KAFKA
```

# 总结
1、参考文档：
* https://docs.spring.io/spring-kafka/docs/2.1.6.RELEASE/reference/html/_reference.html#kafka-template

* https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-messaging.html#boot-features-kafka