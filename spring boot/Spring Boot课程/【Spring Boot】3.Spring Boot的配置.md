# 简介
springboot使用一个全局配置文件，配置文件名是固定的：
* application.properties
* application.yml
  
配置文件的作用：修改springboot自动配置的默认值。springboot在底层都给我们自动配置好了；

配置文件位于src/resources下面。

## YAML
yaml a markup language 是一个标记语言，以数据为中心，比其他类型的标记语言更适合作为配置文件。
标记语言：以前的配置文件大多都使用XXX.xml文件，

## 不同文件配置方式
YAML：
``` yml
server:
  port: 8081
```
XML:
``` xml
<server>
  <port>8081</port>
</server>
```
properties:
``` json
server.port = 8081
```

# 例子：配置文件实现值的注入
## 编写配置文件
``` yml
person:
  lastName: zhaoyi
  list:
    - list1
    - list2
  maps:
    k1: v1
    k2: v2
  age: 25
  boss: false
  dog:
    name: xiaohuang
    age: 30 
```
## 配置组件
``` java
// person类
@Component
@ConfigurationProperties(prefix = "person")
public class Person {
    private String lastName;
    private List<Object> list;
    private Map<String, Object> maps;
    private Integer age;
    private Boolean boss;
    private Dog dog;

    @Override
    public String toString() {
        return "Person{" +
                "lastName='" + lastName + '\'' +
                ", list=" + list +
                ", maps=" + maps +
                ", age=" + age +
                ", boss=" + boss +
                ", dog=" + dog +
                '}';
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public List<Object> getList() {
        return list;
    }

    public void setList(List<Object> list) {
        this.list = list;
    }

    public Map<String, Object> getMaps() {
        return maps;
    }

    public void setMaps(Map<String, Object> maps) {
        this.maps = maps;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public Boolean getBoss() {
        return boss;
    }

    public void setBoss(Boolean boss) {
        this.boss = boss;
    }

    public Dog getDog() {
        return dog;
    }

    public void setDog(Dog dog) {
        this.dog = dog;
    }
}

// dog类
package com.zhaoyi.hello1.com.zhaoyi.hello1.bean;

public class Dog {
    private String name;
    private int age;

    @Override
    public String toString() {
        return "Dog{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```
## 使配置拥有提示
导入配置文件处理器，这样就会有提示编写资源的信息；
``` xml
  <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-configuration-processor</artifactId>
        <optional>true</optional>
  </dependency>
```
只有组件是容器中的组件,才能使用ConfigurationProperties提供的功能；

## 编写测试类
springboot单元测试：可以在测试期间很方便的类似编码一样进行自动注入等容器功能；
``` java
@RunWith(SpringRunner.class)
@SpringBootTest
public class Hello1ApplicationTests {

    @Autowired
    Person person;

    @Test
    public void contextLoads() {
        System.out.println(person);
    }
}
```

# properties配置文件的编码问题
## 使用properties配置文件
注释掉application.yml的配置文件信息，新建一个application.properties文件，写入和applicatio.yml相同功能的配置
``` json
person.age=14
person.last-name=张三
person.boss=false
person.maps.k1=v1
person.maps.k2=v2
person.list=a,b,c
person.dog.name=小狗
person.dog.age=5
```
运行测试后发现有关中文部分的输出是乱码。

## 解决方法
idea使用的是utf-8编码，在setting处查询file encoding，设置为utf-8，并选择在运行时转化为ascll（勾选）

# @configurationProperties和@Value
Spring中配置一个Bean:
``` xml
<bean class="person">
  <property name="lastName" value="zhangsan"></property>
</bean>
```
其中，value可以：
* 字面量
* ${key} 从环境变量或者配置文件中提取变量值
* `#{SPEL}`
  
而@Value其实效果和其一样，比如，在类属性上写
``` java
@Value("person.lastName")
private String lastName
@Value("#{11*2}")
private Integer age
```

## 区别
||@ConfigurationProperties|@Value|
|-|-|-|
|功能|批量注入配置文件中的属性|一个个指定|
||支持松散绑定|不支持松散绑定|
|SpEL|不支持|支持|
|JSR303数据校验|支持|不支持|
|复杂类型封装|支持|不支持|
注：
* 松散绑定例如:
配置文件填写的是last-name，而@Value必须写一模一样的，否则会报错。而使用@ConfigurationProperties则可以使用驼峰式（其实就是类的属性名）
* @Validation 在类上加入此配置之后，开启jsr303校验，例如在某字段上加上@Email，则配置文件对应字段必须符合邮箱格式。相反，如果此处我们使用@Value注入值，可以看到，可以正常的注入，即便提供的不符合邮箱格式，也不会报错。

## 选择
从上面的说明我们可以知道，两者在配置上基本可以相互替换，彼此功能也大体一致，那么，我们在业务场景中，该选用哪一种进行编码呢？

1. 如果说，我们只是在某个业务逻辑中需要获取一下配置文件的某项值，考虑使用`@Value`.
``` java
@RestController
public class HelloController {
    @Value("${person.last-name}")
    private String name;

    @RequestMapping("/")
    public String hello(){
        return "hello world, " + name;
    }
}
```
2. 但是，如果我们专门去写一个java bean来和配置文件进行映射，那么毫无疑问，我们应该使用`@ConfigurationProperties`；
 
# @PopertySource注解

> `@PropertySource` 加载指定的配置文件。
> 
我们知道，@ConfigurationProperties默认从全局配置文件（application.properties）中获取值，但通常我们会将相关的配置文件放到某个配置文件中，例如，我们将有关person的配置信息放到person.properties中去。为了使组件类Person能够找到配置文件的配置信息，需要使用增加新的注解`@PropertySource`指定从哪里加载配置等相关信息。
``` java
@PropertySource("classpath:person.properties")
@Component
@ConfigurationProperties(prefix = "person")
public class Person {
}
```

# @ImportResource注解
> `@ImportResource` 导入Spring的配置文件，让配置文件里面的内容生效。

1. 添加新的服务类HelloService
``` java
package com.zhaoyi.hello1.service;
public class HelloService {
}
```

2. 在类目录下创建一个bean.xml，即spring的配置文件，其中配置了一个service的bean.
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
<bean id="helloService" class="com.zhaoyi.hello1.service.HelloService"></bean>
</beans>
```
那么问题来了，在spring-boot中显然是不会加载此bean的，我们测试一下。

3. 编写测试类
``` java
@RunWith(SpringRunner.class)
@SpringBootTest
public class Hello1ApplicationTests {
    @Autowired
    ApplicationContext ioc;

    @Test
    public void testBean(){
        System.out.println("Is have helloService bean? " + ioc.containsBean("helloService"));
    }
}
``` 
测试结果：
```
Is have helloService bean? false
```
Spring boot里面是没有Spring的配置文件，我们自己编写的配置文件，也不能自动识别，想让Spring的配置文件生效，则需要手动指示将其加载进行，使用`@ImportResource`标注在一个配置类（例如应用程序启动类，他也是一个配置类）上:
``` java
@ImportResource(locations = {"classpath:bean.xml"})
@SpringBootApplication
public class Hello1Application {
    public static void main(String[] args) {
        SpringApplication.run(Hello1Application.class, args);
    }
}
```
这时候运行测试用例就会发现，bean已经出现在容器中了。

# @Bean注解

> @ImportResource(locations = {"classpath:bean.xml"})

一般我们不会使用6中所提到的这种方式，因为xml配置方式实在是写了太多的无用代码，如果xml的标签声明，以及头部的域名空间导致。因此，SpringBoot推荐给容器中添加组件的方式：全注解方式。也就是用配置类来充当bean配置文件。如下，即为一个配置类：
``` java
/**
 * @Configuration 指明当前类是一个配置类
 */
@Configuration
public class MyConfig {
    // 将方法的返回值添加到容器中：容器中这个组件的id就是方法名
    @Bean
    public HelloService helloService(){
        return new HelloService();
    }
}
``` 
通过该配置类，可以为容器中添加了一个名为`helloService`的bean。

# 配置文件占位符
无论是使用yaml还是properties都自持文件占位符配置方式
## 随机数
${random.value}

${random.int}

${random.long}

${random.int(10)}

${random.int[1024,65536]}

## 属性占位符
* 可以在配置文件中引用前面配置过的属性；
* ${app.name:默认值} 若找不到属性时，则取默认值处填写的值；

## 例子
1. 在person.properties中写入如下配置
``` java
person.age=14
person.last-name=张三${random.uuid}
person.boss=false
person.maps.k1={person.xxx:novalue}
person.maps.k2=v2
person.list=a,b,c
person.dog.name=${person.last-name}_小狗狗
person.dog.age=${random.int}
```
1. 测试输出
``` java
Person{lastName='张三1b9fbbb1-6c58-4a35-8165-ad23800d7456', list=[a, b, c], maps={k2=v2, k1=novalue}, age=14, boss=false, dog=Dog{name='张三b3a355d7-54ce-4afd-9ae6-d3be4aeb4165_小狗狗', age=-122850975}}
```
注意：留意默认值那一项设置，我们如愿的成功设置了默认值novalue。在实际项目中，这种情况比较常用，稍微留意一下。如果没有默认值，则会将${xxx}这一段作为值，这显然是错误的。

# 9 Profile
> profile一般是spring用来做多环境支持的，可以通过激活指定参数等方式快速的切换当前环境。
## 9.1 多Profile文件
我们在主配置文件编写的时候，文件名可以是 `application-{profile}.properties(yml)`
例如:
application-dev.properties、application-prod.properties等。

## 激活指定profile
1. 在application.properties中指定：
``` java
spring.profiles.active=dev
```
2. 命令行方式激活，此配置的优先级高于配置文件处的配置。
```
--spring.profiles.active=dev
```
* 方式一 点击编译环境右上角的下拉框，选择第一项`edit configuration`，在environment配置节中的`Program arguments`写入spring.profiles.active=dev即可。
* 方式二 将当前的项目打包生成jar包，然后执行`java -jar your-jar-name.jar --spring.profiles.active=dev`即可。
3. 虚拟机参数方式激活 在步骤2的老地方，`Program arguments`上一项即为虚拟机参数激活，不过填写的内容为`-Dspring.profiles.active=dev`，即多了一个`-D`而已。

## yml多文档配置文件
若我们使用properties，则需要编写多个不同的配置文件，但如果我们使用yml的话，则可以通过多文档配置节实现单文件管理。*注：有关yml相关的知识参考此文档的前半部分*。

可以看到，我们通过`---`三个横线实现文档分割，同时在每一个文档块处指定了各个profile的不同配置信息，即dev环境下启动服务使用8082端口，prod环境下使用8083端口。而指定哪一个profile则是通过默认的文档块（即第一块）中的spring.profiles.active进行配置。完成如上配置之后我们启动服务，显然此时是以激活的prod环境所配置的端口8083运行的，如下启动日志所示：
```
com.zhaoyi.hello1.Hello1Application      : The following profiles are active: prod
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 8083 (http)
```
也就说，当我们选定一个profile后，对应的文档块的配置就会全部生效。

# 9 配置文件的加载位置
SpringBoot启动会扫描以下位置的application.properties或者application.yml文件作为SpringBoot的默认配置文件:
- file:./config/
- file:./
- classpath:/config/
- classpath:/

以上是按照优先级顺序从高到低，所有位置的文件都会被加载，但对于相同配置：高优先级配置内容会覆盖低优先级配置的内容，其他的则互补。

我们也可以通过spring.config.location参数来设置默认的配置文件位置。项目打包好以后，使用命令行参数形式来指定配置文件的新位置，指定的配置文件和默认加载的配置互补起作用。并且我们指定的该配置文件优先级是最高的。

# 外部配置的加载顺序
SpringBoot支持多种外部配置方式，他可以从以下位置加载配置，按优先级从高到低排列如下（高优先级配置覆盖低优先级配置，所有配置会形成互补配置）：
1. 命令行参数
``` shell
java -jar package_name_version.jar --server-port=8080 --server.context-path=/hello 
```
多个参数之间用空格分开，用`--parameter_name=value`进行配置。

2. 来自java:comp/env的JNDI属性
3. java系统属性（System.getProperties()）
4. 操作系统环境变量
5. RandomValuePropertySource配置的random.*属性值

都是由jar包外向jar包内进行寻找，高优先级的配置覆盖低优先级的配置。然后
优先加载带profile的：

6. jar包外部的application-{profile}.properties或application.yml(带spring.profile)配置文件
> 在jar文件的同级目录放一个application.properties文件，其配置内容会被加载； 

7. jar包内部的application-{profile}.properties或application.yml(带spring.profile)配置文件
   
再来加载不带profile的：

8. jar包外部的application.properties或application.yml(不带spring.profile)配置文件
9.  jar包内部的application.properties或application.yml(不带spring.profile)配置文件
10.  @Configuration注解类上的@PropertySource
11.  通过SpringApplication.setDefaultProperties指定的默认属性。
 
官方文档列出了比这里更多的配置文档，请参考，版本更迭地址会经常变动，可自行前往官方网站进行查看。

# 自动配置原理
配置文件的配置属性可以参照官方文档：[前往](https://docs.spring.io/spring-boot/docs/2.1.1.RELEASE/reference/htmlsingle/#common-application-properties)
## 自动配置原理
1. springboot启动的时候加载主配置类，开起了自动配置功能`@EnableAutoConfiguration`。
2. @EnableAutoConfiguration作用：利用EnableAutoConfigurationImportSelector给容器中导入一些组件，可以查看selectImport()方法的内容:
``` java
    public String[] selectImports(AnnotationMetadata annotationMetadata) {
        if (!this.isEnabled(annotationMetadata)) {
            return NO_IMPORTS;
        } else {
            AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader.loadMetadata(this.beanClassLoader);
            AutoConfigurationImportSelector.AutoConfigurationEntry autoConfigurationEntry = this.getAutoConfigurationEntry(autoConfigurationMetadata, annotationMetadata);
            return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
        }
    }
```
扫描所有jar包类路径下`META-INF/spring.factories`文件，吧扫描到的这些文件的内容包装成properties对象；从properties中获取到EnableAutoConfiguration.class类对应的值，然后把他们添加在容器中；

说到底，就是将类路径下`META-INF/spring.factories`里面配置的所有EnableAutoConfiguration的值加入到了容器中。
``` xml
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration,\
org.springframework.boot.autoconfigure.batch.BatchAutoConfiguration,\
org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration,\
org.springframework.boot.autoconfigure.cassandra.CassandraAutoConfiguration,\
org.springframework.boot.autoconfigure.cloud.CloudServiceConnectorsAutoConfiguration,\
org.springframework.boot.autoconfigure.context.ConfigurationPropertiesAutoConfiguration,\
...（more）
```
每一个这样的xxxAutoConfiguration类都会是容器中的一个组件，都加入到了容器中，用他们来做自动配置。

3. 每一个自动配置类进行自动配置功能。
以`org.springframework.boot.autoconfigure.web.servlet.HttpEncodingAutoConfiguration`为例：
``` java

@Configuration
@EnableConfigurationProperties({HttpProperties.class})
@ConditionalOnWebApplication(
    type = Type.SERVLET
)
@ConditionalOnClass({CharacterEncodingFilter.class})
@ConditionalOnProperty(
    prefix = "spring.http.encoding",
    value = {"enabled"},
    matchIfMissing = true
)
public class HttpEncodingAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean
    public CharacterEncodingFilter characterEncodingFilter() {
        CharacterEncodingFilter filter = new OrderedCharacterEncodingFilter();
        filter.setEncoding(this.properties.getCharset().name());
        filter.setForceRequestEncoding(this.properties.shouldForce(org.springframework.boot.autoconfigure.http.HttpProperties.Encoding.Type.REQUEST));
        filter.setForceResponseEncoding(this.properties.shouldForce(org.springframework.boot.autoconfigure.http.HttpProperties.Encoding.Type.RESPONSE));
        return filter;
    }
   ...
}
```
我们可以看到该类的注解如下：
* `@Configuration` 毫无疑问，表明这是一个配置类，和我们要自定义一个配置文件一样，实现给容器中添加组件；
* `@EnableConfigurationProperties`  启动指定类的ConfigurationPropertiesg功能，这样就可以将配置文件中对应的值和HttpEncodingProperties绑定起来；并把HttpEncodingProperties加入到ioc容器中;
* `@ConditionalOnWebApplication` Spring底层`@Conditional`注解，根据不同的条件，如果满足指定的条件，整个配置类里面的配置就会生效；此处判断的就是当前应用是不是Web应用；否则配置不生效；
* `@ConditionalOnClass` 判断当前项目有没有类(`CharacterEncodingFilter`)，这是SpringMVC中进行乱码解决的过滤器；
* `@ConditionalOnProperty` 判断配置文件中是否存在某个配置 `spring.http.encoding.enabled`；如果不存在，则判断成立，如果没有配置，则此处将其设置为`true`；
* `@Bean` 给容器中添加Bean组件，该组件的某些值需要从properties中获取，此处即为HttpEncodingProperies，显然此刻他的取值已经和springboot的properties文件进行注入了；
  
> 根据不同的条件进行判断当前这个配置类是否生效。一单这个配置类生效，这个配置类就会给容器中添加各种组件；这些组件的属性均来自于其对应的Properties类的，这些Properties类里面的每一个属性，又是和配置文件绑定的。
  
4. 所有在配置文件中能配置的属性都是在xxxProperties类中的封装者；配置文件能配置什么就可以查看对应的属性类。如上面的这个配置类我们就可以参考他的注解`@EnableConfigurationProperties`指定的properties类`HttpProperties`：
``` java
@ConfigurationProperties(
    prefix = "spring.http"
)
public class HttpProperties {
```

## 配置精髓
1. springboot启动会加载大量的自动配置类；
2. 我们看我们需要的功能有没有springboot默认写好的自动配置类；
3. 我们再来看这个自动配置类中到底配了那些组件，倘若已经有了，我们就不需要再编写配置文件进行配置了。
4. 给容器中自动配置类添加组件的时候，会从对应的Properties类中获取某些属性。我们就可以在配置文件中指定这些属性的值（其已经通过注解进行了绑定）；

## 总结
xxxAutoConfiguration 这种类就是用来做自动配置的，他会给容器中添加相关的组件，其对应的Properties则对应了配置的各种属性；也就是说，通过这些配置类，我们以前需要在SpringMVC中写配置类、文件实现的东西，现在，只需要在Properites配置文件中加入相关的配置即可，不再那么麻烦了。

> 当然，一些特殊的配置还是得自己写组件的哦。

# @Conditional*相关注解
## @Conditinal派生注解
只有其指定的条件成立，配置类的所有类型才会生效，更小范围的，例如注释在某个Bean组件上面的相关条件注解成立，才会生成该Bean。
## 常用派生注解一览
@Conditional扩展注解|作用（判断是否满足当前指定条件）
-|-
@ConditionalOnJava|系统的java版本是否符合要求
@ConditionalOnBean| 容器中存在指定Bean
@ConditionalOnMissingBean |容器中不存在指定Bean
@ConditionalOnExpression| 满足SpEL表达式指定
@ConditionalOnClass |系统中有指定的类
@ConditionalOnMissingClass |系统中没有指定的类
@ConditionalOnSingleCandidate |容器中只有一个指定的Bean，或者这个Bean是首选Bean
@ConditionalOnProperty |系统中指定的属性是否有指定的值
@ConditionalOnResource |类路径下是否存在指定资源文件
@ConditionalOnWebApplication |当前是web环境
@ConditionalOnNotWebApplication |当前不是web环境
@ConditionalOnJndi |JNDI存在指定项

> 我们可以发现，尽管我们拥有许多的自动配置类，其还是得必须满足一定条件才会生效，该机制就是有@Conditinal派生注解等控制的，常见的是`@ConditionalOnClass`，即判断当前系统具不具备相关的类。

## debug模式
配置文件application.properties中添加配置，开启Debug模式：
```
debug=true
```
默认情况下debug的值为false，通过启用`debug=true`属性，让控制台打印相关的报告，例如那些自动配置类启用(positive matches)、没启用(negative matches)等。