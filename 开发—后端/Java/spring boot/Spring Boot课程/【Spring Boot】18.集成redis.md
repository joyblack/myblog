# 简介
redis是什么相信大家都有具体的了解，不了解的同学最好先去官方网站查阅学习。

我们之前讲到的缓存系统，默认使用的是ConcurrentMapCacheManager==ConcurrentMapCache，默认开启的是SimpleCacheConfiguration配置，我们之前分析过，他还支持其他的很多缓存配置，包括我们要讲到的redis。

通过将redis集成到我们的缓存系统，我们就可以轻松的通过reids的客户端查询对应的缓存信息，实现了缓存信息的可视化。

> 印象笔记 —— redis是一个比传统数据库更轻量，但却拥有强大功能的“数据库”，一般在应用中充当缓存组件，例如作为数据库和应用程序上层的中间件、提供session会话信息保存等。

# 1 reids基础环境搭建
1. 安装redis
传统安装redis的方法，我们就不多说了，我们使用之前用的docker安装redis.
* 拉取redis
``` shell 
docker pull redis
```
* 启动reids
``` shell
docker run -d -p 6379:6379 --name redis redis
```
* 查看结果
``` shell
docker ps
```
输出
```
439e18fd2ea6        rabbitmq:3-management                                 "docker-entrypoint..."   5 days ago          Up 5 days           4369/tcp, 5671/tcp, 0.0.0.0:5672->5672/tcp, 15671/tcp, 25672/tcp, 0.0.0.0:15672->15672/tcp   rabbit
3d9ee1d941b0        redis                                                 "docker-entrypoint..."   5 days ago          Up 5 days           0.0.0.0:6379->6379/tcp                                                                       redis
402fbb3778ad        docker.elastic.co/elasticsearch/elasticsearch:6.5.3   "/usr/local/bin/do..."   5 days ago          Up 5 days           0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp                                               loving_carson
e3ef44911869        mariadb                                               "docker-entrypoint..."   5 days ago          Up 5 days           0.0.0.0:3306->3306/tcp                                                                       mysql
59f9c80d269b        tomcat                                                "catalina.sh run"        5 days ago          Up 5 days           0.0.0.0:8080->8080/tcp                                                                       goofy_swartz
```
之前我已经装好了redis，我们可以看到redis已经在我们端口6379上映射好了，接下来就可以使用redis客户端连接并查看我们自己的redis了。

2. 安装redis客户端
redis客户端有很多，不过比较常用的是 *RedisDesktopManager* ，您可以轻松的下载安装。通过点击`Connect to Redis Server`按钮（如果您的版本和我的差不多的话，应该在右下方往右数的第二个按钮，有一个绿色的`+`），按照我们的redis环境对其进行配置，如果成功的话，双击生成的redis服务，就可以看到出现16个数据仓库，说明您整个过程已经成功了。一般都是如下的配置
```
Name ： 随意写
Host ： 你的Redis服务器id
Port： 6379
Auth： 无需填写
```

3. 尝试一下redis的使用
redis的使用您可以参考官网的文档尝试或者参考一些关于redis的一些博客，官方文档列出了许多相关的命令，可以一一尝试下，非常有意思。（先了解redis的特性之后在开始妥当一些。）


# 2 整合redis
1. 引入redis的场景启动器：
##### pom.xml
``` xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
```

2. 配置redis
可以通过sprig.redis相关参数配置redis。
#### application.yml
``` yml
spring:
  redis:
    host: 10.21.1.47
    port: 6379
```
port默认6379，如果是默认端口的话我们也可以不予指定。

1. 查看redis自动配置类源码
``` java
/*
 * Copyright 2012-2018 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.springframework.boot.autoconfigure.data.redis;

import java.net.UnknownHostException;

import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisOperations;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;

/**
 * {@link EnableAutoConfiguration Auto-configuration} for Spring Data's Redis support.
 *
 * @author Dave Syer
 * @author Andy Wilkinson
 * @author Christian Dupuis
 * @author Christoph Strobl
 * @author Phillip Webb
 * @author Eddú Meléndez
 * @author Stephane Nicoll
 * @author Marco Aust
 * @author Mark Paluch
 */
@Configuration
@ConditionalOnClass(RedisOperations.class)
@EnableConfigurationProperties(RedisProperties.class)
@Import({ LettuceConnectionConfiguration.class, JedisConnectionConfiguration.class })
public class RedisAutoConfiguration {

	@Bean
	@ConditionalOnMissingBean(name = "redisTemplate")
	public RedisTemplate<Object, Object> redisTemplate(
			RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
		RedisTemplate<Object, Object> template = new RedisTemplate<>();
		template.setConnectionFactory(redisConnectionFactory);
		return template;
	}

	@Bean
	@ConditionalOnMissingBean
	public StringRedisTemplate stringRedisTemplate(
			RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
		StringRedisTemplate template = new StringRedisTemplate();
		template.setConnectionFactory(redisConnectionFactory);
		return template;
	}

}
```
可以看出，他为我们提供了两个组件类，一个是RedisTemplate（k-v都是对象），一个是StringRedisTemplate(k-v都是字符串)。由于我们经常使用字符串操作，所以redis配置类中为提供了stringRedisTemplate这个组件。

我们可以直接在应用中直接注入就可以使用了。

# 3 测试redis操作
redis支持的五大数据类型:String（字符串）、List（列表）、Set（集合）、Hash（散列）、ZSet（有序集合），我们都可以使用springboot提供的组件类进行操作。

1. StringRedisTemplate
> 通过`redisTemplate.opsXXX.redis提供的Command`来操作相应的数据。例如redisTemplate.opsForHash.

##### test/AwebApplicationTests
``` java
package com.zhaoyi.aweb;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class AwebApplicationTests {

    @Autowired
    StringRedisTemplate stringRedisTemplate;

    @Autowired
    RedisTemplate redisTemplate;
    @Test
    public void test01() {
        stringRedisTemplate.opsForValue().append("name", "a");
        stringRedisTemplate.opsForValue().append("name","kuya");
        System.out.println(stringRedisTemplate.opsForValue().get("name"));
    }

    @Test
    public void contextLoads() {

    }

}


```

运行test01测试方法后，我们的redis存储库中存储了一个String类型的name数据，其值为akuya，其他的操作大家都可以一一逐个测试，当然不同的数据类型设置和获取由些许差异。

接下来我们使用RedisTemplate类型的template来测试对象的保存。

1. RedisTemplate
##### test/AwebApplicationTests
``` java
    @Autowired
    RedisTemplate redisTemplate;
    @Test
    public void test02() {
        Integer id = 1;
        String key = "user_" + id;
        User user = userService.getUser(id);
        redisTemplate.opsForValue().set(key, user);
        System.out.println(redisTemplate.opsForValue().get(key));
    }
```

我们查询id=2的用户信息，并以`user_{id}`为key的方式存储一个对象user的信息，运行测试用例test02我们会发现报错：
```
...
java.lang.IllegalArgumentException: DefaultSerializer requires a Serializable payload but received an object of type [com.zhaoyi.aweb.bean.User]
...
```
提示我们需要提供的应该是一个可序列化的有效载荷（patload）类型，因此，我们需要将User标志为可序列化的对象类型。
##### bean/User.class
``` java
public class User implements Serializable {
    private static final long serialVersionUID = 4125096758372084309L;
```
我们再运行之后，查看redis客户端的存储信息发现
```
key=\xAC\xED\x00\x05t\x00\x06user_1

value = \xAC\xED\x00\x05sr\x00\x19com.zhaoyi.aweb.bean.User\xC7\xD7\xAC\x00\x0F\xDB\x0A\x97\x02\x00\x04L\x00\x0CdepartmentIdt\x00\x13Ljava/lang/Integer;L\x00\x02idq\x00~\x00\x01L\x00\x09loginNamet\x00\x12Ljava/lang/String;L\x00\x08userNameq\x00~\x00\x02xpsr\x00\x11java.lang.Integer\x12\xE2\xA0\xA4\xF7\x81\x878\x02\x00\x01I\x00\x05valuexr\x00\x10java.lang.Number\x86\xAC\x95\x1D\x0B\x94\xE0\x8B\x02\x00\x00xp\x00\x00\x00\x01q\x00~\x00\x06t\x00\x05akuyat\x00\x09\xE9\x98\xBF\xE5\xBA\x93\xE5\xA8\x85
```

也就是说，保存对象时，都是以jdk序列化机制，不管是key还是value都是序列化的字符串了。

通常，我们还是习惯自己转化为json方式来存储：
* 将对象转化为json字符串存储 这个很简单，我们一般使用这一种
* 修改默认序列化器为json序列化器。

我们先查看默认情况下用的是什么序列化器：
##### org.springframework.data.redis.core.RedisTemplate
``` java
if (defaultSerializer == null) {

    defaultSerializer = new JdkSerializationRedisSerializer(
            classLoader != null ? classLoader : this.getClass().getClassLoader());
}
```

也就是`JdkSerializationRedisSerializer`，接下来，我们修改为自己的序列化器。
##### config/MyConfig.class
``` java
package com.zhaoyi.aweb.config;

import com.zhaoyi.aweb.bean.User;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;

import java.net.UnknownHostException;

@Configuration
public class MyConfig {

    @Bean
    public RedisTemplate<String, User> redisTemplateUser(RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
        RedisTemplate<String, User> template = new RedisTemplate();
        template.setConnectionFactory(redisConnectionFactory);
        // 设置默认的序列化器
        Jackson2JsonRedisSerializer<User> userJackson2JsonRedisSerializer = new Jackson2JsonRedisSerializer<User>(User.class);
        template.setDefaultSerializer(userJackson2JsonRedisSerializer);
        return template;
    }
}

```

然后，我们使用该template来进行redis的存储操作
##### test/AwebApplicationTests
``` java
    @Autowired
    RedisTemplate<String, User> redisTemplate;
    @Test
    public void test02() {
        Integer id = 1;
        String key = "user_" + id;
        User user = userService.getUser(id);
        redisTemplate.opsForValue().set(key, user);
        //System.out.println(redisTemplate.opsForValue().get(key));
    }
```

查看我们的redis客户端，就可以看到不管是key还是value都是易读的的形式了：
``` 
key = "user_1"
value = 
{
  "id": 1,
  "loginName": "akuya",
  "userName": "阿库娅",
  "departmentId": 1
}
```


# 4 测试缓存
我们引入redis的starter之后，我们的容器中的缓存管理器变成了RedisCacheManager，他的作用是创建了`RedisCache`来作为缓存组件，RedisCachle通过我们配置的redis来进行缓存数据。

> 前面我们使用查询user的时候，会发现redis生成了一个名叫`user`命名空间，缓存了我们查询的用户信息。

默认创建的RedisCacheManager使用的是RedisTemplate<Object,Object>，他默认使用的序列化器还是我们默认的JDK序列化机制。要改变这种行为，我们同样需要创建自己的自定义CacheManager，注意2.0和1.x版本还是有很大的区别，请小心版本带来的问题。


但在寻找其区别的时候，我发现一个问题，那就是我们应用中不可能没有一个类就写一个template，因此，我们需要写一个通用的redis底层存储配置，也就是说遵循：*以`String`类型的数据作为key，以json字符串作为结果*进行存储，因此，编写了如下的配置器，如果嫌麻烦的同学可以直接复制过去使用，兼容任何的类与底层缓存：
##### config/JoyRedisConfig.class
``` java 
package com.zhaoyi.aweb.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.*;

import java.net.UnknownHostException;

@Configuration
public class JoyRedisConfig {

    /**
     * 配置RedisTemplate<String,Object>
     * @param redisConnectionFactory
     * @return
     * @throws UnknownHostException
     */
    @Bean
    public RedisTemplate<String,Object> redisTemplateUser(RedisConnectionFactory redisConnectionFactory) throws UnknownHostException {
        RedisTemplate<String, Object> template = new RedisTemplate();
        template.setConnectionFactory(redisConnectionFactory);
        // 设置序列化器
        template.setDefaultSerializer(valueSerializer());
        return template;
    }

    @Bean
    public RedisCacheManager redisCacheManagerUser(RedisConnectionFactory redisConnectionFactory){
        // 这里可以配置超时时间等
        RedisCacheConfiguration redisCacheConfiguration = RedisCacheConfiguration
                // Default { using the following:
                // key expiration === eternal
                // cache null values === yes
                // prefix cache keys===yes
                // default prefix===the actual cache name
                // key serializer === org.springframework.data.redis.serializer.StringRedisSerializer
                // value serializer === org.springframework.data.redis.serializer.JdkSerializationRedisSerializer
                // conversion service === DefaultFormattingConversionService with #registerDefaultConverters(ConverterRegistry) default
                .defaultCacheConfig()
                // Define the {@link SerializationPair} used for de-/serializing cache keys.
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(keySerializer()))
                // Define the {@link SerializationPair} used for de-/serializing cache values.
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(valueSerializer()))
                // Disable caching
                .disableCachingNullValues();
        return RedisCacheManager.builder(redisConnectionFactory)
                .cacheDefaults(redisCacheConfiguration)
                .transactionAware()
                .build();
    }

    // key序列化器
    private RedisSerializer<String> keySerializer() {
        return new StringRedisSerializer();
    }

    // Value序列化器
    private RedisSerializer<Object> valueSerializer() {
        return new GenericJackson2JsonRedisSerializer();
    }
}

```
> 我们可以看到通过配置`@Cacheable(value = "user", key = "#id")`生成的缓存key的样子为`user::1`，也就是说cacheName指定的值，生成了user::这样的前缀，在redis中以名称空间的形式存在；另外，如果我们以`@Cacheable(value = {"user","saber"}, key = "#id")`，这样存储的话，结果会在user和saber两个名称空间中，存储两份结果，即`user::1`和`saber::1`。

> 注意这是2.x版本，简化配置。基本满足需要，如果您有详细的配置，例如超时时间、针对具体的容器进行配置，可以在`redisCacheConfiguration`配置。

> 还记得`@CacheManager`注解吗，他所指定的就是我们现在定义的这些CacheManager了。

> 如果你配置了多个缓存管理器，别忘了为默认的缓存管理器添加一个`@Primary`注解。



