
# HelloWorld应用程序
1. 给maven的settings.xml配置文件的profiles标签添加
``` xml
    <profile>
        <id>jdk‐1.8</id>
        <activation>
            <activeByDefault>true</activeByDefault>
            <jdk>1.8</jdk>
        </activation>
        <properties>
            <maven.compiler.source>1.8</maven.compiler.source>
            <maven.compiler.target>1.8</maven.compiler.target>
            <maven.compiler.compilerVersion>1.8</maven.compiler.compilerVersion>
        </properties>
    </profile>
```
2. 在maven中添加sprig boot相关依赖
``` xml
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.5.9.RELEASE</version>
    </parent>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
```
3. 编写一个主程序，启动spring boot应用
``` java
package com.zhaoyi.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HelloWorldApplication {
    public static void main(String[] args){
        SpringApplication.run(HelloWorldApplication.class, args);
    }
}
``` 

# 程序探究
## 1、POM文件
### 1 父项目
```
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.5.9.RELEASE</version>
    </parent>]
```
父项目才真正的管理Spring Boot应用里面的所有依赖版本。

Spring boot的版本仲裁中心：
以后我们导入依赖默认是不需要写版本（没有在dependency里面管理的依赖自然需要声明版本号）

### 2、导入的依赖
```
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>
```
#### 1、启动器
spring-boot-starter: spring-boot场景启动器；如spring-boot-starter-web则帮我们导入了web模块需要正常运行所依赖的组件。
参照官方文档我们可以发现，spring-boot-starter-*代表了一系列的功能场景，当你需要什么具体业务需求的时候，将其导入就可以了，比如aop、data-redis、mail、web等。他将所有的功能场景都抽出来，做成一个个的starter（启动器），其先关的业务场景的所有依赖都会导入进来，要用什么功能就导入什么场景的启动器。

## 2、主程序类
``` java
package com.zhaoyi.hello;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HelloWorldApplication {
    public static void main(String[] args){
        SpringApplication.run(HelloWorldApplication.class, args);
    }
}
```
***@SpringBootApplication*** SB应用标注在某个类上说明这个类是SB的主配置类，SB就应该运行这个类的main方法来启动SB应用。

``` java
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(
    excludeFilters = {@Filter(
    type = FilterType.CUSTOM,
    classes = {TypeExcludeFilter.class}
), @Filter(
    type = FilterType.CUSTOM,
    classes = {AutoConfigurationExcludeFilter.class}
)}
)
public @interface SpringBootApplication {
```
***@SpringBootConfiguration*** SB的配置类；
标注在某个类上，表示这个类是SB的配置类。

***@Configuration*** 配置类上来标注这个注解；
配置类就是配置文件；配置类也是容器中的一个组件；@companent

***@EnableAutoConfiguration*** 开启自动配置功能；
以前我们需要在SP中配置的东西，SB帮我们自动配置，通过此配置告诉SB开启自动配置功能。这样，自动配置的功能才能生效。

``` java

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@AutoConfigurationPackage
@Import({EnableAutoConfigurationImportSelector.class})
public @interface EnableAutoConfiguration {
    String ENABLED_OVERRIDE_PROPERTY = "spring.boot.enableautoconfiguration";

    Class<?>[] exclude() default {};

    String[] excludeName() default {};
}
```
***@AutoConfigurationPackage*** 自动配置包
SP的底层注解@import，给容器中导入一个组件。
将主配置类（@SpringBottApplication标注的类）所在包及下面所有子包里面的所有组件扫描到SP容器。

***@Import({EnableAutoConfigurationImportSelector.class})*** 导入哪些组件的选择器；将所有需要导入的组件以全类名的方式返回，这些组件就会被添加到容器中； 
会给容器中导入非常多的自动配置类（xxxAutoConfiguration）;就是给容器中导入这个场景需要的所有组件，并配置好这些组件。这样就免去了我们手动编写配置注入功能组件等的工作；

SB在启动的时候从类路径下的META-INFO/spring.factories中获取EnableAutoConfiguration指定的值，将这些纸作为自动配置类导入容器中，自动配置类就生效，帮我们进行自动配置工作；以前我们需要自己配置的东西，自动配置类都帮我们做了。

J2EE的整体解决方案和自动配置都在sprig-boot-autoconfigure.jar中了；

# 使用Spring Initializer快速创建SB项目
IDE都支持使用Spring的项目创建向导；
选择我们需要的模块，向导会联网创建SB项目；

@ResponseBody 这个类的所有方法（或者单个方法——）返回的数据直接写给浏览器。
@ResponseBody写在类上面时，大可以写为@RestController，其等价于@ResponseBody+@Controller;

## 默认生成的项目
* 主程序已经生成好了，我们只需关注自己的业务逻辑
* resounces文件夹中的目录结构
  * static：保存所有的静态资源：js css images；
  * templates：保存所有的模板页面；（SB默认jar包，使用嵌入式页面；可以使用模板引擎——freemarker、thymeleaf）
  * application.properties SB应用的配置文件；SB的一些默认配置可以在这里进行修改。
