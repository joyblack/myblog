# 自定义starter
自定义starter：
* 这个场景需要使用到的依赖是什么？
* 如何编写自动配置？

以我们web场景启动器的自动配置类WebMVCAutoConfiguration类为例：
``` java
@Configuration 
@ConditionalOnWebApplication(
    type = Type.SERVLET
)
@ConditionalOnClass({Servlet.class, DispatcherServlet.class, WebMvcConfigurer.class})
@ConditionalOnMissingBean({WebMvcConfigurationSupport.class})
@AutoConfigureOrder(-2147483638)
@AutoConfigureAfter({DispatcherServletAutoConfiguration.class, TaskExecutionAutoConfiguration.class, ValidationAutoConfiguration.class})
public class WebMvcAutoConfiguration {

```
在自动配置类中，经常可以看到如下的注解:
* `@Configuration`  指明这是一个配置类
* `@ConditionalOnXXX`  在指定条件成立的情况下自动配置类生效
* `@AutoConfigureAfter` 指定自动配置类的顺序
* `@Bean`  给容器中添加组件
* `@ConfigurationPropertie`结合相关`xxxProperties`类来绑定相关的配置
* `@EnableConfigurationProperties` 让`xxxProperties`生效加入到容器中

而且，自动配置类要能加载，需要将他们配置在类路径下的`META-INF/spring.factories`.例如springBoot的
```
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
```

# 模式
启动器只用来做依赖导入，他是一个空jar文件，仅提供辅助性的依赖管理，这些依赖可能用于自动装配或者其他类库。他是专门来写一个自动配置模块；启动器依赖自动配置；别人只需要引入启动器（starter）就可以了。

## 命名规则
* 官方 spring-boot-starter-模块名
* 非官方（如我们自己编写的） 模块名-spring-boot-starter

mybatis-spring-boot-starter；自定义启动器名-spring-boot-starter


# 自己做一个starter
## 创建项目
1. 新建一个空的项目：hellostarter；
2. 启动器（做依赖引入）：添加一个module，group_id为com.zhaoyi.starter，ArtifactId为hello-spring-boot-stater；
3. 自动配置（做自动配置）：在来添加一个module作为初始化器，选择springinitializer创建，group_id为com.zhaoyi.starter，ArtifactId为hello-spring-boot-starter-autoconfigurer，不添加任何场景模块；
4. 点击apply，点击ok。

## 主程序模块
#### 启动器/pom.xml
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.zhaoyi.starter</groupId>
    <artifactId>hello-spring-boot-stater</artifactId>
    <version>1.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>com.zhaoyi.starter</groupId>
            <artifactId>hello-spring-boot-starter-autoconfigurer</artifactId>
            <version>0.0.1-SNAPSHOT</version>
        </dependency>
    </dependencies>

</project>
```
其实就是引入另外一个自动配置的坐标信息即可，至此，启动器模块无需加入任何代码，我们接下来完善自动配置模块。

> `hello-spring-boot-stater` 我这里starter少写一个r了，请假装他是有r的。

## 自动配置模块

#### pom.xml
``` xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.1.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.zhaoyi.starter</groupId>
    <artifactId>hello-spring-boot-starter-autoconfigurer</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>hello-spring-boot-starter-autoconfigurer</name>
    <description>Demo project for Spring Boot</description>
    <properties>
        <java.version>1.8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>
    </dependencies>

</project>

```

删除一些其他不必要的依赖，只需要`springboot-starer`以及`spring-boot-configuration-processor`，这是所有starer都需要的基本配置。

> 下方的build也记得删除，因为我们会删除主程序的启动类，插件会报错。

> `spring-boot-configuration-processor`是2.x必须引入的包。

在starter包路径下添加三个如下类文件

#### starter/HelloProperties.class
```java
package com.zhaoyi.starter;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "zhaoyi.hello")
public class HelloProperties {
    private String prefix;
    private String suffix;

    public String getPrefix() {
        return prefix;
    }

    public void setPrefix(String prefix) {
        this.prefix = prefix;
    }

    public String getSuffix() {
        return suffix;
    }

    public void setSuffix(String suffix) {
        this.suffix = suffix;
    }
}
```

该类配置了Properties类，并强调了与配置文件的zhaoyi.hello前缀的配置关联，支持prefix以及suffix两项配置。

#### starter/HelloService.class
```java
package com.zhaoyi.starter;

public class HelloService {

    private HelloProperties helloProperties;

    public HelloProperties getHelloProperties() {
        return helloProperties;
    }

    public void setHelloProperties(HelloProperties helloProperties) {
        this.helloProperties = helloProperties;
    }

    public String sayHello(String name){
        return helloProperties.getPrefix() + name + helloProperties.getSuffix();
    }
}
```
该服务类用于对外提供服务，我们可以看到他提供了一个方法，用于返回前缀+传入参数+后缀这样的字符串，同时提供了一个setter接口，用于HelloServiceAutoConfiguration进行Properties设置。


```java
package com.zhaoyi.starter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConditionalOnWebApplication
@EnableConfigurationProperties(HelloProperties.class)//属性文件生效
public class HelloServiceAutoConfiguration {

    @Autowired
    private HelloProperties helloProperties;

    @Bean
    public HelloService helloService(){
        HelloService helloService = new HelloService();
        helloService.setHelloProperties(helloProperties);
        return helloService;
    }
}
```

该自动配置类和我们之前查看的springboot的自动配置类的源码很相似，他使用HelloProperties作为注入属性对象，同时往容器中注入一个名为`helloService`的bean，提供给用户消费。

#### resources/META-INF/spring.factories
```
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.zhaoyi.starter.HelloServiceAutoConfiguration 
```

至此我们的工作做完了：首先，我们写了自动配置类，这个类给容器中给容器中添加HelloService组件，该组件用到的属性是和HelloProperties绑定的，而HelloProperties的值又是可以通过从配置文件中进行配置（绑定了前缀zhaoyi.hello），我们这里支持两个属性即prefix和suffix。最后，我们通过在resources即类路径下新建`META-INF/spring.factories`文件保证springboot启动后配置类会加载生效。

接下来我们将整个项目发布到本地仓库中（点击maven install）。先install自动配置模块，然后在install启动器模块（因为启动器模块是依赖于自动配置模块的，因此在后面install）。

我们会发现，两个jar包已经被安装在了我们的本地仓库中，接下来，我们就写一个测试网站来试试我们自己的starter吧。

## 测试

创建一个web项目，选择web模块，并在pom文件中引入我们上一节中自己创建的starter，导入坐标信息：

``` xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.1.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>demo</name>
    <description>Demo project for Spring Boot</description>

    <properties>
        <java.version>1.8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>com.zhaoyi.starter</groupId>
            <artifactId>hello-spring-boot-stater</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```

还记得我们的自定义starter吗？他提供了两个配置项，于是，我们到配置文件中添加此配置。

#### application.yml
``` yml
server:
  port: 8085
zhaoyi:
  hello:
    prefix: this is prefix
    suffix: this is suffix
```
该配置文件指明了服务启动端口8085，同时，设置了我们自定义场景的配置：prefix以及suffix。好了，万事俱备，接下来就是消费该场景启动器提供给我们的服务了。创建一个controller：

#### controller/IndexController.class
``` java
package com.example.demo.controller;

import com.zhaoyi.starter.HelloService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class IndexController {

    @Autowired
    private HelloService helloService;
    
    @RequestMapping("/hello")
    public String index(){
        String hello = helloService.sayHello("hello");
        return hello;
    }
}
```

在我们springboot启动的时候，springboot已经将helloService这个bean注入到了容器中，我们直接注入到controller中就可以使用了，并且我们配置的值也会随之装配到HelloProperties对象上，接下来访问`http://localhost:8085/hello`，就可以得到以下的输出：
```
this is prefixhellothis is suffix
```

也就在我们传入的参数前后分别添加配置的指定值。

至此，我们的自定义starter完成了，在实际开发中，我们自己编写starter的场景其实并不多见，但是你也许会发现很多有趣的事情，如果能把一些常用的模块这样提取出来，供后来者使用，未尝不是一种对自己的提升。