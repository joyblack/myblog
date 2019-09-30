# 简介
在讲解Springboot相关组件之前，我们先要了解在java的缓存插件体系，类似于我们之前学习数据操作的数据源规范一样，也有一个标准，这个标准叫做JSR107，我们可以通过在网上查询相关的信息。

## JSR107
Java Caching定义了5个核心接口，分别是CachingProvider, CacheManager, Cache, Entry 和 Expiry。
1. CachingProvider定义了创建、配置、获取、管理和控制多个CacheManager。一个应用可以在运行期访问多个CachingProvider。
2. CacheManager定义了创建、配置、获取、管理和控制多个唯一命名的Cache，这些Cache存在于CacheManager的上下文中。一个CacheManager仅被一个CachingProvider所拥有。
3. Cache是一个类似Map的数据结构并临时存储以Key为索引的值。一个Cache仅被一个CacheManager所拥有。
4. Entry是一个存储在Cache中的key-value对。
5. Expiry 每一个存储在Cache中的条目有一个定义的有效期。一旦超过这个时间，条目为过期的状态。一旦过期，条目将不可访问、更新和删除。缓存有效期可以通过ExpiryPolicy设置

# 1 应用程序缓存架构

![图1](img/1.png)

# 2 spring的缓存抽象
Spring从3.1开始定义了org.springframework.cache.Cache和org.springframework.cache.CacheManager(缓存管理器)接口来统一不同的缓存技术；并支持使用JCache（JSR-107）注解简化我们开发；

Cache接口为缓存的组件规范定义，包含缓存的各种操作集合；
Cache接口下Spring提供了各种xxxCache的实现；如RedisCache，EhCacheCache , ConcurrentMapCache等；

每次调用需要缓存功能的方法时，Spring会检查检查指定参数的指定的目标方法是否已经被调用过；如果有就直接从缓存中获取方法调用后的结果，如果没有就调用方法并缓存结果后返回给用户。下次调用直接从缓存中获取。
使用Spring缓存抽象时我们需要关注以下两点；
1. 确定方法需要被缓存以及他们的缓存策略
2. 从缓存中读取之前缓存存储的数据

# 3 常用注解
在我们开发应用程序中，比较常用的注解如下所示：
|||
|-|-|
|Cache	|缓存接口，定义缓存操作。实现有：RedisCache、EhCacheCache、ConcurrentMapCache等|
|CacheManager	|缓存管理器，管理各种缓存（Cache）组件|
|@Cacheable	|主要针对方法配置，能够根据方法的请求参数对其结果进行缓存|
|@CacheEvict	|清空缓存|
|@CachePut	|保证方法被调用，又希望结果被缓存。|
|@EnableCaching	|开启基于注解的缓存|
|@keyGenerator	|缓存数据时key生成策略|
|@serialize	|缓存数据时value序列化策略|



# 4 缓存使用测试
接下来我们编写一个应用程序体验一下springboot中缓存的使用。

1. 搭建基本环境
* 创建项目，选择模块：cache web mysql mybatis
* 导入数据库文件到数据库joyblack，脚本内容如下（核心章节我们用的数据库）
##### joyblack.yml
``` sql
/*
Navicat MySQL Data Transfer

Source Server         : docker
Source Server Version : 50505
Source Host           : 10.21.1.47:3306
Source Database       : joyblack

Target Server Type    : MYSQL
Target Server Version : 50505
File Encoding         : 65001

Date: 2018-12-20 09:45:44
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `department`
-- ----------------------------
DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `id` int(11) NOT NULL,
  `department_name` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of department
-- ----------------------------
INSERT INTO `department` VALUES ('1', '乡下冒险者公会');
INSERT INTO `department` VALUES ('2', '城市冒险者公会');

-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `login_name` varchar(20) NOT NULL,
  `department_id` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES ('1', '阿库娅', 'akuya', '1');
INSERT INTO `user` VALUES ('2', '克里斯汀娜', 'crustina', '1');
INSERT INTO `user` VALUES ('3', '惠惠', 'huihui', '1');
```
2. 整合mybatis操作数据库（核心章节14.整和mybatis），我们采用基于注解的方式使用。

##### pom.xml
``` xml
     <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-cache</artifactId>
    </dependency>
```

##### application.yml
``` yml
spring:
  datasource:
    username: root
    password: 123456
    url: jdbc:mysql://127.0.0.1:3306/joyblack?characterEncoding=utf8&serverTimezone=GMT
    driver-class-name: com.mysql.cj.jdbc.Driver
server:
  port: 8090
mybatis:
  configuration:
    # 开启驼峰映射规则
    map-underscore-to-camel-case: true
```
##### bean/User.class
``` java
package com.zhaoyi.aweb.bean;

public class User {
    private Integer id;
    private String loginName;
    private String userName;
    private Integer departmentId;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getLoginName() {
        return loginName;
    }

    public void setLoginName(String loginName) {
        this.loginName = loginName;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }
}

```
##### bean/Department.class
``` java
package com.zhaoyi.aweb.bean;

public class Department {
    private Integer id;
    private String departmentName;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }
}
```

##### mapper/UserMapper.class
``` java
package com.zhaoyi.aweb.mapper;

import com.zhaoyi.aweb.bean.User;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

public interface UserMapper {

    @Insert(" insert into user(id, login_name, user_name, department_id) values (#{id}, #{loginName}, #{userName}, #{departmentId})")
    int insertUser(User user);

    @Delete("delete from user where id = #{id}")
    int deleteUser(Integer id);

    @Select("select * from user where id = #{id}")
    User getUserById(Integer id);

    @Update("update user set user_name = #{userName} where id = #{id}")
    int updateUser(User user);
}
```

##### mapper/DepartmentMapper.class
``` java
package com.zhaoyi.aweb.mapper;

import com.zhaoyi.aweb.bean.Department;
import org.apache.ibatis.annotations.*;

public interface DepartmentMapper {

    // insert a derpartment.
    // @Options(useGeneratedKeys = true, keyProperty = "id") may you want get insert data generated id.
    @Insert("insert into department(id,department_name) values(#{id}, #{departmentName})")
    int insertDepartment(Department department);

    // delete a department by id.
    @Insert("delete from department where id = #{id}")
    int deleteDepartment(Integer id);

    // query a department by id.
    @Select("select * from department where id = #{id}")
    Department getDepartmentById(Integer id);

    // update a department information.
    @Update("update department set department_name=#{departmentName} where id=#{id}")
    int updateDepartment(Department department);
}
```

1. 由于mapper中没有添加@Mapper注解，我们要告诉springboot扫描对应的mapper包

##### aweb/SpringBootApplication.class
``` java
package com.zhaoyi.aweb;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@MapperScan(value = "com.zhaoyi.aweb.mapper")
@SpringBootApplication
public class AwebApplication {
    public static void main(String[] args) {
        SpringApplication.run(AwebApplication.class, args);
    }

}
```

4. 接下来，编写一个controller测试一下环境是否OK
##### controller/UserController.class
``` java
package com.zhaoyi.aweb.controller;

import com.zhaoyi.aweb.bean.User;
import com.zhaoyi.aweb.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @Autowired
    private UserMapper userMapper;

    @RequestMapping("/user/insert")
    public User insertUser(User user){
        userMapper.insertUser(user);
        return user;
    }

    @RequestMapping("/user/delete/{id}")
    public Integer insertUser(@PathVariable("id") Integer id){
        return userMapper.deleteUser(id);
    }

    @RequestMapping("/user/select/{id}")
    public User getUser(@PathVariable("id") Integer id){
       return userMapper.getUserById(id);
    }

    @RequestMapping("/user/update")
    public User updateUser(User user){
        userMapper.updateUser(user);
        return user;
    }
}
```

访问 localhost:8090/user/select/1，得到：
``` json
{"id":1,"loginName":"akuya","userName":"阿库娅","departmentId":1}
```


5. 编写一个service

前面我们相当于复习了一遍之前的操作，我们现在先做一下改变，一般来说，controller调用的service相关的东西，因此，我们将对mapper的操作提到servicer一层，我们添加一个service包:

##### service.UserService.class
``` java
package com.zhaoyi.aweb.service;

import com.zhaoyi.aweb.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.zhaoyi.aweb.bean.User;

@Service
public class UserService {
    @Autowired
    private UserMapper userMapper;

    public User getUser(Integer id){
        System.out.println("查询:" + id);
        return userMapper.getUserById(id);
    }
}

```

接下来，我们重新写一下controller的方法，如下所示:
##### controller/UserController.class
``` java
package com.zhaoyi.aweb.controller;

import com.zhaoyi.aweb.bean.User;
import com.zhaoyi.aweb.mapper.UserMapper;
import com.zhaoyi.aweb.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {
    @Autowired
    private UserService userService;

    @RequestMapping("/user/select/{id}")
    public User getUser(@PathVariable("id") Integer id){
       return userService.getUser(id);
    }

}
```

6. 开启缓存相关配置

这样，我们就保证controller只和service进行交互了。我们开始新知识了，一般使用缓存，我们需要如下步骤：

* 开启基于注解的缓存；
* 标注缓存注解。

很简单吧？

现在，我们每访问一次select url，都会在控制台打印一次
```
查询:1
```

也就是说，当前都会调用service的getUser在数据库进行查询操作。接下来我们为该方法提供缓存效果，即在启动类中添加注解`@EnableCaching`：

##### AwebApplication.class
``` java
package com.zhaoyi.aweb;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@EnableCaching
@MapperScan(value = "com.zhaoyi.aweb.mapper")
@SpringBootApplication
public class AwebApplication {
    public static void main(String[] args) {
        SpringApplication.run(AwebApplication.class, args);
    }

}
```
然后我们去标注缓存注解在对应的服务方法上
##### service/UserService.class
``` java
  @Cacheable(value = {"user"})
    public User getUser(Integer id){
        System.out.println("查询:" + id);
        return userMapper.getUserById(id);
    }
```
这一次我们再次访问，发现除了第一次会打印查询记录之外，其他的查询都不会打印了（一个id只会进行一次查询，即第一次），显然已经做了缓存了。


# 5 缓存工作原理

还是得先从自动配置类源码入手。

##### CacheAutoConfiguration.class
``` java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package org.springframework.boot.autoconfigure.cache;

import java.util.List;
import java.util.function.Supplier;
import java.util.stream.Collectors;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.AutoConfigureAfter;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.couchbase.CouchbaseAutoConfiguration;
import org.springframework.boot.autoconfigure.data.jpa.EntityManagerFactoryDependsOnPostProcessor;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.autoconfigure.hazelcast.HazelcastAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cache.CacheManager;
import org.springframework.cache.interceptor.CacheAspectSupport;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.ImportSelector;
import org.springframework.core.type.AnnotationMetadata;
import org.springframework.orm.jpa.AbstractEntityManagerFactoryBean;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.util.Assert;

@Configuration
@ConditionalOnClass({CacheManager.class})
@ConditionalOnBean({CacheAspectSupport.class})
@ConditionalOnMissingBean(
    value = {CacheManager.class},
    name = {"cacheResolver"}
)
@EnableConfigurationProperties({CacheProperties.class})
@AutoConfigureAfter({CouchbaseAutoConfiguration.class, HazelcastAutoConfiguration.class, HibernateJpaAutoConfiguration.class, RedisAutoConfiguration.class})
@Import({CacheAutoConfiguration.CacheConfigurationImportSelector.class})
public class CacheAutoConfiguration {
    public CacheAutoConfiguration() {
    }

    @Bean
    @ConditionalOnMissingBean
    public CacheManagerCustomizers cacheManagerCustomizers(ObjectProvider<CacheManagerCustomizer<?>> customizers) {
        return new CacheManagerCustomizers((List)customizers.orderedStream().collect(Collectors.toList()));
    }

    @Bean
    public CacheAutoConfiguration.CacheManagerValidator cacheAutoConfigurationValidator(CacheProperties cacheProperties, ObjectProvider<CacheManager> cacheManager) {
        return new CacheAutoConfiguration.CacheManagerValidator(cacheProperties, cacheManager);
    }

    static class CacheConfigurationImportSelector implements ImportSelector {
        CacheConfigurationImportSelector() {
        }

        public String[] selectImports(AnnotationMetadata importingClassMetadata) {
            CacheType[] types = CacheType.values();
            String[] imports = new String[types.length];

            for(int i = 0; i < types.length; ++i) {
                imports[i] = CacheConfigurations.getConfigurationClass(types[i]);
            }

            return imports;
        }
    }

    static class CacheManagerValidator implements InitializingBean {
        private final CacheProperties cacheProperties;
        private final ObjectProvider<CacheManager> cacheManager;

        CacheManagerValidator(CacheProperties cacheProperties, ObjectProvider<CacheManager> cacheManager) {
            this.cacheProperties = cacheProperties;
            this.cacheManager = cacheManager;
        }

        public void afterPropertiesSet() {
            Assert.notNull(this.cacheManager.getIfAvailable(), () -> {
                return "No cache manager could be auto-configured, check your configuration (caching type is '" + this.cacheProperties.getType() + "')";
            });
        }
    }

    @Configuration
    @ConditionalOnClass({LocalContainerEntityManagerFactoryBean.class})
    @ConditionalOnBean({AbstractEntityManagerFactoryBean.class})
    protected static class CacheManagerJpaDependencyConfiguration extends EntityManagerFactoryDependsOnPostProcessor {
        public CacheManagerJpaDependencyConfiguration() {
            super(new String[]{"cacheManager"});
        }
    }
}

```

我们通过打断点方式，可以查看配置相关的信息，这里就不一一列出了。其运行过程大致如下：

1. 方法运行之前，先查询`Cache`（缓存组件），按照`@CacheName`指定的名字获取(``CacheManager`获取相应的缓存)；第一次获取缓存时，如果没有对应的组件，会先自动创建。  总之，第一步获取了一个缓存组件。

2. 在组件中通过我们提供的`key`，默认是方法的参数，之后，在缓存内部，根据我们提供的key又根据某种策略生成内部的`key`，默认使用`SimpleKeyGenerator`生成key（如果没有参数：key = new SimpleKey()，如果有一个参数，key=参数的值，多个参数 key = SimpleKey(param)）查询对应的值。

3. 如果没有从对应的`key`中查到值，就会调用目标方法（缓存标注的方法）返回的结果放到缓存（key对应的值）之中；如果有值，则直接将结果返回。


> `@Cacheable`标注的方法执行之前先来检查缓存中有没有这个数据，默认按照参数的值查找缓存，如果没有就运行方法结果放入缓存。以后再次调用就可以直接使用缓存中的数据。

核心：
1. 使用`CacheManager`按照名字得到Cache组件，若没有配置，默认就是`ConcurrentMapCacheManager`组件；

2. key是使用`KeyGenerator`生成的，默认使用`SimpleKeyGenerator`;

# 6 @Cacheable分析
CacheEnable主要用于标准方法，表示对该方法的返回结果进行缓存保存。

通过观察CacheEnable源码如下所示：
``` java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package org.springframework.cache.annotation;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import org.springframework.core.annotation.AliasFor;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface Cacheable {
    @AliasFor("cacheNames")
    String[] value() default {};

    @AliasFor("value")
    String[] cacheNames() default {};

    String key() default "";

    String keyGenerator() default "";

    String cacheManager() default "";

    String cacheResolver() default "";

    String condition() default "";

    String unless() default "";

    boolean sync() default false;
}

```
从中可以查询到我们可以定制的属性8个，其中`value`和`cacheNames`是相同功效的两个注解参数。我们接下来分析几个常用的，cacheManager放到后面。
1. `value`&`cacheNames` 缓存组件的名称，在 spring 配置文件中定义，必须指定至少一个。
``` java
@Cacheable(value="mycache")
```
他等同于
``` java
 @Cacheable(value={"cache1","cache2"}
```
2. `key`
缓存的 key，可以为空，如果指定要按照 SpEL 表达式编写，如果不指定，则缺省按照方法的所有参数进行组合。
``` java
@Cacheable(value = {"user"}, key="#root.methodName+'[' + #id + ']'")
```
此方法自定义了key的值为：methodname[id]。其中id为我们传入的参数的值。

其语法特点遵循如下取值方式：
|名字|	位置	|描述	|示例|
|-|-|-|-|
|methodName	|root object|	当前被调用的方法名	#root.methodName
|method	|root object|	当前被调用的方法	#root.method.name
|target	|root object|	当前被调用的目标对象	#root.target
|targetClass|	root object|	当前被调用的目标对象类	#root.targetClass
|args	|root object|	当前被调用的方法的参数列表	#root.args[0]
|caches	|root object|	当前方法调用使用的缓存列表（如@Cacheable(value={"cache1", "cache2"})），则有两个cache	#root.caches[0].name
|argument name	|evaluation context|	方法参数的名字. 可以直接 #参数名 ，也可以使用 #p0或#a0 的形式，0代表参数的索引；	#iban 、 #a0 、  #p0 
|result	|evaluation context|	方法执行后的返回值（仅当方法执行之后的判断有效，如‘unless’，’cache put’的表达式 ’cache evict’的表达式beforeInvocation=false）	#result
||||

3. keyGenerator 和key二选一，指定key的生成策略，即用于指定自定义key生成器(KeyGenerator)。

我们来测试一下这个功能，首先编写配置文件
##### config/CacheConfig.class
``` java
package com.zhaoyi.aweb.config;

import org.springframework.cache.interceptor.KeyGenerator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.lang.reflect.Method;

@Configuration
public class CacheConfig {

    @Bean
    public KeyGenerator keyGenerator(){
        return new KeyGenerator() {
            @Override
            public Object generate(Object o, Method method, Object... objects) {
                return method.getName() + "[" + Arrays.asList(objects).toString()  + "]";
            }
        };
    }
}

```
我们自定义了一个key的生成器，接下来只需要在缓存注解处标注我们定义的生成器即可：

##### service/UserService.class
``` java
@Cacheable(value = {"user"}, keyGenerator="keyGenerator")
    public User getUser(Integer id){
        System.out.println("查询:" + id);
        return userMapper.getUserById(id);
    }
```

> `keyGenerator`在孤独部分的是我们加入容器的bean的名字，@Bean不指定name时，默认就是方法名作为类名，因此我们此时的bean的名字就是`keyGenerator`。

通过断点，我们可以发现，当查询用户1的信息时，该方式生成的key类似为：`getUser[[1]]`

4. cacheManager
指定缓存管理器
5. cacheResolver
和cacheManager二选一，缓存解析器
6. condition 缓存的条件，可以为空，使用SpEL编写，返回 true 或者 false，只有为 true才进行缓存/清除缓存，在调用方法之前之后都能判断。
``` java
 @Cacheable(value = {"user"}, condition = "#a0 > 1")
    public User getUser(Integer id){
        System.out.println("查询:" + id);
        return userMapper.getUserById(id);
    }
```
当`condition`表明只对id大于2的用户信息进行缓存。

> `#a0`代表第1个参数，你也可以直接`#参数名`提取对应的参数值。

7. unless(@CachePut)(@Cacheable)
用于否决缓存，不像condition，该表达式只在方法执行之后判断，此时可以拿到返回值`result`进行判断。条件为true不会缓存，fasle才缓存。例如：
``` java
@Cacheable(value="testcache",unless="#result == null")
```

> `#result`表示返回结果。

#### sync
是否使用异步模式，默认false，是否等待方法执行完才返回结果，另外，该配置如果生效，则`@unless`注解失效。

# @CachePut
缓存机制如果对一个经常变化的值进行操作的话，显然我们需要一个更新机制，例如当编号为1的用户被修改了之后，也希望通过返回结果缓存或者更新（如果对应的key已经有了的话）他的缓存信息。这个功能就是由`@CachePut`来完成。

他的特点是标注方法在进行操作之后，对结果进行缓存。我们不难想象，他的使用方式和`@Cacheable`如出一辙，对其指定同样的和`@Cacheable`一样的key即可。

为了测试一下，我们为controller添加一个update方法

##### controller/UserController.class
``` java
  @RequestMapping("/user/update")
    public User updateUser(User user){
        return userService.updateUser(user);
    }
```

然后对service使用`@CachePut`注解，注意指定和读取时使用的一样的key（即用户ID）：
##### service/UserService.class
``` java

    @Cacheable(value = "user", key = "#id")
    public User getUser(Integer id){
        System.out.println("查询:" + id);
        return userMapper.getUserById(id);
    }

    @CachePut(value = "user", key="#user.id")
    public User updateUser(User user) {
        userMapper.updateUser(user);
        return userMapper.getUserById(user.getId());
    }

```
我们和`@Cacheabl`e一样用了相同的缓存组件user，以及一致的key生成策略——用户ID，同时查询了更新后的用户信息作为返回值，确保`@CachePut`将其放进缓存。

接下来我们先查询id为1的用户信息，重复查两次，确保对当前结果进行了缓存，访问localhost:8090/user/select/1
``` json
{"id":1,"loginName":"akuya","userName":"阿库娅","departmentId":1}
```

现在，我们将userName修改为“阿库娅520”，访问localhost:8090/user/update?id=1&userName=阿库娅520，确保修改成功之后，我们再来访问localhost:8090/user/select/1:

``` json
{"id":1,"loginName":"akuya","userName":"阿库娅520","departmentId":1}
```
得到了我们更新之后的结果，说明`@CachePut`达到了我们想要的需求。


> 为了测试@CachePut的效果，可以先去除更新@CachePut的注解，这样我们就可以发现，即便我们修改了用户信息，缓存的信息还是旧用户信息，添加了@CachePut之后，结果就实时更新了。


> 和`@Cacheable`不一样的是，`@CachePut`是优先调用方法，再将结果存储在缓存中；而`@Cacheable`则是先判断缓存中是否存在对应的key，不存在才调用方法。因此我们可以推导出`@Cacheable`指定key的时候是不能使用`#result`这样的语法的（聪明的你应该很容易理解）。

# 8 @CacheEvict
缓存清除，例如我们删除一个用户的时候，可以使用该注解删除指定的缓存信息。

同样需要指定缓存组件，以及key，有了之前的经验，我们应该写这样的service方法就可以了：

##### service/UserService.class
``` java
   @CacheEvict(value = "user", key="#id")
    public void deleteUser(Integer id) {
        System.out.println("删除");
        userMapper.deleteUser(id);
    }
```

我们也指定了`user`，也指定了其key的值。

相比较之前的注解，`CacheEvict`还有一些特殊的注解，例如：
1. `allEntries` 默认值false，标志为true之后，会清除指定组件中的所有缓存信息，例如
``` java
@CacheEvict(value = "user", allEntries = true)
```
该注解就会在方法执行后，将user组件中的所有缓存都清除。

2. `beforeInvocation` 默认为false，如果设置为true，那么清除缓存操作会发生在方法执行之前。这种情况比较特殊，默认情况下，我们是方法执行后才进行清缓存操作，显然如果在方法运行过程中出现异常，就不会清除缓存。所以，如果有特殊要求，我们可以使用该参数，让缓存一开始就清除掉，而不管你方法是否运行成功与否。

# 9 @Caching
如果我们的缓存规则比较复杂，需要用到以上多个注解的特性，那么可以考虑使用`@Caching`注解，查询其源码我们就可以知道，他其实就是其他注解的组合体：
##### org.springframework.cache.annotation/Caching.interface
``` java
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
public @interface Caching {
    Cacheable[] cacheable() default {};

    CachePut[] put() default {};

    CacheEvict[] evict() default {};
}
```

为了使用`@Caching`，我们可以编写一个这样的service，通过loginName查询用户信息，然后呢，将返回结果放在几个不同的key值之中，这样，我们直接通过id或者其他为查询条件查询时，就可以直接从
之前的查询中，拿到结果，而无需再从数据库中查询了：
##### mapper/UserMapper.class
``` java 
    @Select("select * from user where login_name = #{loginName}")
    User getUserByLoginName(String loginName);
```

##### service/UserService.class
``` java
@Caching(
        cacheable = {
            @Cacheable(value = "user", key = "#loginName")
        },
        put = {
            @CachePut(value="user", key = "#result.id"),
            @CachePut(value="user", key = "#result.userName")
        }
    )
    public User getUserByLoginName(String loginName){
        return userMapper.getUserByLoginName(loginName);
    }
```
我们通过loginName查询到结果之后，还想要通过userName以及id作为缓存的key保存到内存中，这些key值都只能从返回结果中取到。我们前面有提到，`@cacheable`是没办法拿到返回结果的。因此我们使用`@CachePut`来完善了我们的需求。

接下来通过测试就会发现，只要我们通过loginName查询了akuya的数据，我们再通过id为1（就是akuya）来查询akuya信息，发现这时候就直接得到结果，无需查询数据库了。因为我们的缓存组件中，通过`userService.getUserByLoginName`方法的执行，已经就id、loginName以及userName对akuya的信息进行了缓存。

# 10 @CacheConfig
仔细观察我们之前缓存属性配置你会发现，很多属性非常的啰嗦，例如`value="user"`,重复指定了N次，我们能不能通过某个注解，直接一次性将这些配置指定了呢？

有，他就是`CacheConfig`，用于抽取缓存的公共配置。以下是其源码：
##### org.springframework.cache.annotation.CacheConfig
``` java
/*
 * Copyright 2002-2015 the original author or authors.
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

package org.springframework.cache.annotation;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * {@code @CacheConfig} provides a mechanism for sharing common cache-related
 * settings at the class level.
 *
 * <p>When this annotation is present on a given class, it provides a set
 * of default settings for any cache operation defined in that class.
 *
 * @author Stephane Nicoll
 * @author Sam Brannen
 * @since 4.1
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface CacheConfig {

	/**
	 * Names of the default caches to consider for caching operations defined
	 * in the annotated class.
	 * <p>If none is set at the operation level, these are used instead of the default.
	 * <p>May be used to determine the target cache (or caches), matching the
	 * qualifier value or the bean names of a specific bean definition.
	 */
	String[] cacheNames() default {};

	/**
	 * The bean name of the default {@link org.springframework.cache.interceptor.KeyGenerator} to
	 * use for the class.
	 * <p>If none is set at the operation level, this one is used instead of the default.
	 * <p>The key generator is mutually exclusive with the use of a custom key. When such key is
	 * defined for the operation, the value of this key generator is ignored.
	 */
	String keyGenerator() default "";

	/**
	 * The bean name of the custom {@link org.springframework.cache.CacheManager} to use to
	 * create a default {@link org.springframework.cache.interceptor.CacheResolver} if none
	 * is set already.
	 * <p>If no resolver and no cache manager are set at the operation level, and no cache
	 * resolver is set via {@link #cacheResolver}, this one is used instead of the default.
	 * @see org.springframework.cache.interceptor.SimpleCacheResolver
	 */
	String cacheManager() default "";

	/**
	 * The bean name of the custom {@link org.springframework.cache.interceptor.CacheResolver} to use.
	 * <p>If no resolver and no cache manager are set at the operation level, this one is used
	 * instead of the default.
	 */
	String cacheResolver() default "";

}
```
源码也加了不少注释，但其内在属性都是提取的公共配置，我们直接在service类上指定之后，如果内部方法没有特殊指定，都会套用我们使用该注解指定的值。例如，我们抽取出公共value属性。

``` java
@Service
@CacheConfig(cacheNames = "user")
public class UserService {
```
这样，我们整个service的缓存方法注解，如果都是用的user组件，就无需特殊指定，直接删除即可。通过该注解可以自动的帮我们指定这个值。

> cacheNames和value是同一个意思，不过`@CacheConfig`没对value做兼容，所以我们这里必须写`cacheNames`.


经过这些练习，或许您会发现，缓存内部存储的数据我们能看到吗？如果能看到就好了。可以吗？当然可以。所以，我们接下来要学习的redis，为我们解决这个问题。









