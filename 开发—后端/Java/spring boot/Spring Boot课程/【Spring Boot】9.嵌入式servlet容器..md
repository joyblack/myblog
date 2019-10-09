# 简介
我们已经知道，使用SpringBoot启动web应用并不需要配置tomcat，就可以直接使用，其实是springboot使用的是tomcat作为嵌入式的servlet容器导致的，这称作嵌入式的servlet容器，这是怎么一回事，springboot的内部都做了些什么呢？

# 问题
1. 如何定制和修改servlet容器的相关配置？
2. SpringBoot能不能支持其他的Servlet容器？


# 修改相关配置
## 1. 通过全局配置文件application.properties修改
修改server对象的值相关属性就可以了(`ServerProperties`)。
#### 通用的Servlet容器设置
```
server.port = 8081
server.context-path=/myweb
```

#### 修改tomcat相关的配置
```
server.tomcat.xxxx=cccc
```

## 2. 通过配置类
编写一个`WebServerFactoryCustomize`类型的servlet组件，注意，我这里是2.x版本，如果是1.x的话应该是`EmbeddedServletContainerCustomizer`，教程里是1.0的 ，不过整体差别不大，差不多是一样的用法：

#### MyConfig.class
``` java
@Configuration
public class MyConfig implements WebMvcConfigurer {

    @Bean
    // 定制嵌入式的servlet容器相关规则
    public WebServerFactoryCustomizer<ConfigurableWebServerFactory> webServerFactoryCustomizer(){
        return new WebServerFactoryCustomizer<ConfigurableWebServerFactory>() {
            @Override
            public void customize(ConfigurableWebServerFactory factory) {
                factory.setPort(8085);
            }
        };
    }
}
```

# 注册servlet三大组件
我们知道servletd的三大组件分别为：Servlet、Filter、Listener。由于我们现在打包是jar形式，以jar方式启动嵌入式的tomcat，不是标准的web目录结构，标准目录下有一个`WEB-INF/web.xml`，我们一般会在web.xml中注册三大组件，而jar形式该怎么注册呢？

## 注册Servlet
要注册Servlet，只需在SpringBoot容器中注册一个名为`ServletRegistrationBean`的组件即可，查看源码，其某个构造函数如下所示，分别代表我们需要传入的servlet，以及映射的路径。
#### org.springframework.boot.web.servlet.ServletRegistrationBean.class
``` java 
public ServletRegistrationBean(T servlet, String... urlMappings) {
        this(servlet, true, urlMappings);
    }
```
因此，我们可以这样做：
1. 自定义一个servlet
#### servlet/MyServlet.class
``` java
package com.zhaoyi.springboot.restweb.servlet;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class MyServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().write("I'm Myservlet!");
    }
}

然后，再将该Servlet绑定到ServletRegistrationBean组件并添加到容器中。
```
#### config/MyServerConfig.class

``` java
package com.zhaoyi.springboot.restweb.config;

import com.zhaoyi.springboot.restweb.servlet.MyServlet;
import org.springframework.boot.web.server.ConfigurableWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MyServerConfig {

    @Bean
    // 配置servlet容器
    public WebServerFactoryCustomizer<ConfigurableWebServerFactory> webServerFactoryCustomizer(){
        return new WebServerFactoryCustomizer<ConfigurableWebServerFactory>() {
            @Override
            public void customize(ConfigurableWebServerFactory factory) {
                factory.setPort(8085);
            }
        };
    }

    /**
     * 配置自定义Servlet组件
     * @return
     */
    @Bean
    public ServletRegistrationBean myServlet(){
        ServletRegistrationBean registrationBean = new ServletRegistrationBean(new MyServlet(), "/myServlet");
        return registrationBean;
    }
}
```
访问地址:localhost:8085/myServlet，即可得到反馈
```
I'm Myservlet!
```

> 上一节有一个配置容器的配置（将内嵌容器的启动端口号修改为8085），我将其移动到了MyServerConfig.class中，留意一下。

## 注册Filter
之后的两大组件的注册方式其实就和Servlet注册的方式大同小异了，我们看看怎么做就行了。先来自定义一个Filter，我们需要实现`javax.servlet.Filter`接口，该接口的源码如下所示:
#### javax.servlet.Filter.class
``` java

package javax.servlet;

import java.io.IOException;

public interface Filter {
    default void init(FilterConfig filterConfig) throws ServletException {
    }

    void doFilter(ServletRequest var1, ServletResponse var2, FilterChain var3) throws IOException, ServletException;

    default void destroy() {
    }
}
```
可以看到，有两个默认方法，因此，我们实现该接口，只需实现其doFilter方法即可。
#### filter/MyFilter.class
``` java
package com.zhaoyi.springboot.restweb.filter;

import javax.servlet.*;
import java.io.IOException;

public class MyFilter implements Filter {
    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        System.out.println("this is my filter...");
        filterChain.doFilter(servletRequest, servletResponse);
    }
}
```

> `filterChain.doFilter`放行请求，我们可以看到Chain（链条）的字样，在实际生产中其实我们需要定义很多Filter，他们在应用中形成一个链条，依次过滤，所以很有chain的味道。

接下来，我们将该Filter注册到容器中，并设置需要过滤的映射路径：

#### config/MyServerConfig.class
``` java
    // Filter
    @Bean
    public FilterRegistrationBean filterRegistrationBean(){
        FilterRegistrationBean<Filter> filterFilterRegistrationBean = new FilterRegistrationBean<>();
        filterFilterRegistrationBean.setFilter(new MyFilter());
        filterFilterRegistrationBean.setUrlPatterns(Arrays.asList("/index","/myFilter"));
        return filterFilterRegistrationBean;
    }
```

这样，我们访问`localhost:8085/index`、`localhost:8085/myFilter`这些路径的时候，就会在控制台打印如下信息:
```
this is my filter...
```

而其他的路径则不受影响，表明过滤器生效了。

## 注册Listener
#### listener/MyListener.class
``` java
package com.zhaoyi.springboot.restweb.listener;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

public class MyListener implements ServletContextListener {
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        System.out.println("contextInitialized... application start ....");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        System.out.println("contextDestroyed... application end ....");
    }
}
```

#### config/MyServerConfig.class
``` java
package com.zhaoyi.springboot.restweb.config;

import com.zhaoyi.springboot.restweb.filter.MyFilter;
import com.zhaoyi.springboot.restweb.listener.MyListener;
import com.zhaoyi.springboot.restweb.servlet.MyServlet;
import org.springframework.boot.web.server.ConfigurableWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.servlet.Filter;
import java.util.Arrays;

@Configuration
public class MyServerConfig {

    @Bean
    // servlet
    public WebServerFactoryCustomizer<ConfigurableWebServerFactory> webServerFactoryCustomizer(){
        return new WebServerFactoryCustomizer<ConfigurableWebServerFactory>() {
            @Override
            public void customize(ConfigurableWebServerFactory factory) {
                factory.setPort(8085);
            }
        };
    }



    /**
     * 配置自定义Servlet组件
     * @return
     */
    @Bean
    public ServletRegistrationBean servletRegistrationBean(){
        ServletRegistrationBean registrationBean = new ServletRegistrationBean(new MyServlet(), "/myServlet");
        return registrationBean;
    }

    // Filter
    @Bean
    public FilterRegistrationBean filterRegistrationBean(){
        FilterRegistrationBean<Filter> filterFilterRegistrationBean = new FilterRegistrationBean<>();
        filterFilterRegistrationBean.setFilter(new MyFilter());
        filterFilterRegistrationBean.setUrlPatterns(Arrays.asList("/index","/myFilter"));
        return filterFilterRegistrationBean;
    }

    // Listener
    @Bean
    public ServletListenerRegistrationBean servletListenerRegistrationBean(){
        ServletListenerRegistrationBean servletListenerRegistrationBean = new ServletListenerRegistrationBean(new MyListener());
        return servletListenerRegistrationBean;
    }
}
```

在应用启动的时候，可以看到控制台打印
```
contextInitialized... application start ....
```

我们点击左下角的`Exit`按钮，注意不是红色方块按钮退出的时候，可以看到控制台打印
```
contextDestroyed... application end ....
```
Spring Boot帮我们自动配置SpringMVC的时候,自动的注册了SpringMVC的前端控制器,`DispatcherServlet`，查看`DispatcherServletAutoConfiguration`的源码
####  org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration.class
``` java
 @Bean(
            name = {"dispatcherServletRegistration"}
        )
        @ConditionalOnBean(
            value = {DispatcherServlet.class},
            name = {"dispatcherServlet"}
        )
        public DispatcherServletRegistrationBean dispatcherServletRegistration(DispatcherServlet dispatcherServlet) {
            DispatcherServletRegistrationBean registration = new DispatcherServletRegistrationBean(dispatcherServlet, this.webMvcProperties.getServlet().getPath());
            // 默认拦截: / 所有请求，包括静态资源，但是不拦截JSP请求。注意/*会拦截JSP
            // 可以通过server.servletPath来修改SpringMVC前端控制器默认拦截的请求路径
            registration.setName("dispatcherServlet");
            registration.setLoadOnStartup(this.webMvcProperties.getServlet().getLoadOnStartup());
            if (this.multipartConfig != null) {
                registration.setMultipartConfig(this.multipartConfig);
            }

            return registration;
        }
```

# 使用其他的容器：Jetty（长连接）
> tomcat、Undertow、Netty、Jetty。Netty应该是后来的版本加入的支持，这里就不在阐述了。我们关注其他三个即可。

SpringBoot支持:tomcat jetty undertow，其中tomcat是默认使用的.而使用tomcat 的原因是项目引入了web启动场景包，该场景包默认引用的就是tomcat容器，因此，倘若我们想要换成其他的容器，要在dependencies中排除默认的tomcat场景包，加入其他的包即可。
#### project.pom
``` xml
      <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
```
进入其中，查看关联引用可以找到对应的tomcat场景引入包
#### spring-boot-starter-web.xxxx.pom
``` xml
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-tomcat</artifactId>
      <version>2.1.1.RELEASE</version>
      <scope>compile</scope>
    </dependency>
```
如果我们还需继续研究下去的话，会发现当前tomcat场景启动器包所用的tomcat版本为9.x版本，比较新：

#### spring-boot-starter-tomcat-xxxx.pom
``` xml
...

<dependency>
      <groupId>org.apache.tomcat.embed</groupId>
      <artifactId>tomcat-embed-el</artifactId>
      <version>9.0.13</version>
      <scope>compile</scope>
    </dependency>
...

```

也就是说，如果我们将tomcat-starter排除，然后在pom文件中引入其他的servlet容器场景包即可。

#### pom.xml
``` xml
 <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <exclusions>
                <exclusion>
                    <artifactId>spring-boot-starter-tomcat</artifactId>
                    <groupId>org.springframework.boot</groupId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jetty</artifactId>
        </dependency>
        ...
```
解下来直接运行项目，我们会发现，除了启动容器变成了jetty，其他的一切按正常配置运行：
```
Jetty started on port(s) 8085 (http/1.1) with context path '/'
```

undertow和jetty一模一样的方式，直接吧jetty改为undertow就行了。继续启动:
```
Undertow started on port(s) 8085 (http) with context path ''
```

接下来我们分析spring boot的内在工作原理，在此之前，别忘了换回tomcat作为内嵌容器。

> 要换回tomcat容器，只需将排除代码块`<exclusions>`以及其他内嵌容器场景包引入代码删除即可。

> 在这里还是推荐学习一下maven相关知识，推荐书籍  **Maven实战**。


# 嵌入容器配置原理
#### org.springframework.boot.autoconfigure.web.embedded.EmbeddedWebServerFactoryCustomizerAutoConfiguration.class
``` java

@Configuration
@ConditionalOnWebApplication
@EnableConfigurationProperties({ServerProperties.class})
public class EmbeddedWebServerFactoryCustomizerAutoConfiguration {
    public EmbeddedWebServerFactoryCustomizerAutoConfiguration() {
    }

    @Configuration
    @ConditionalOnClass({HttpServer.class})
    public static class NettyWebServerFactoryCustomizerConfiguration {
        public NettyWebServerFactoryCustomizerConfiguration() {
        }

        @Bean
        public NettyWebServerFactoryCustomizer nettyWebServerFactoryCustomizer(Environment environment, ServerProperties serverProperties) {
            return new NettyWebServerFactoryCustomizer(environment, serverProperties);
        }
    }

    @Configuration
    @ConditionalOnClass({Undertow.class, SslClientAuthMode.class})
    public static class UndertowWebServerFactoryCustomizerConfiguration {
        public UndertowWebServerFactoryCustomizerConfiguration() {
        }

        @Bean
        public UndertowWebServerFactoryCustomizer undertowWebServerFactoryCustomizer(Environment environment, ServerProperties serverProperties) {
            return new UndertowWebServerFactoryCustomizer(environment, serverProperties);
        }
    }

    @Configuration
    @ConditionalOnClass({Server.class, Loader.class, WebAppContext.class})
    public static class JettyWebServerFactoryCustomizerConfiguration {
        public JettyWebServerFactoryCustomizerConfiguration() {
        }

        @Bean
        public JettyWebServerFactoryCustomizer jettyWebServerFactoryCustomizer(Environment environment, ServerProperties serverProperties) {
            return new JettyWebServerFactoryCustomizer(environment, serverProperties);
        }
    }

    @Configuration
    @ConditionalOnClass({Tomcat.class, UpgradeProtocol.class})
    public static class TomcatWebServerFactoryCustomizerConfiguration {
        public TomcatWebServerFactoryCustomizerConfiguration() {
        }

        @Bean
        public TomcatWebServerFactoryCustomizer tomcatWebServerFactoryCustomizer(Environment environment, ServerProperties serverProperties) {
            return new TomcatWebServerFactoryCustomizer(environment, serverProperties);
        }
    }
}
```
从其中就可以看出，该组件注册各个嵌入式Servlet容器的时候，会根据当前对应的某个class是否位于类路径上，才会实例化一个Bean，也就是说，我们导入不同的包，则会导致这里根据我们导入的包生成对应的`xxxxWebServerFactoryCustomizer`组件。这些组件在同样的路径下定义了具体的信息
* JettyWebServerFactoryCustomizer
* NettyWebServerFactoryCustomizer
* TomcatWebServerFactoryCustomizer
* UndertowWebServerFactoryCustomizer

我们以嵌入式的tomcat容器工厂`TomcatWebServerFactoryCustomizer`为例进行分析，当我们引入了tomcat场景启动包后，springboot就会为我们注册该组件。我们查看其源码：

#### org.springframework.boot.autoconfigure.web.embedded.TomcatWebServerFactoryCustomizer

``` java

public class TomcatWebServerFactoryCustomizer implements WebServerFactoryCustomizer<ConfigurableTomcatWebServerFactory>, Ordered {
...
}
```

该工厂类配置了tomcat的基本环境。其中：

``` java
   public TomcatWebServerFactoryCustomizer(Environment environment, ServerProperties serverProperties) {
        this.environment = environment;
        this.serverProperties = serverProperties;
    }
```

传入了我们提供的环境信息以及服务器配置信息。

## 修改配置
我们之前讲过可以通过`WebServerFactoryCustomizer`这个定制器帮我们修改容器的配置。现在我们可以看到也可以通过修改`ServerProperties`.想要定制servlet容器，给容器中添加一个`WebServerFactoryCustomizer`类型的组件就可以了。

步骤：
1. SpringBoot根据导入的依赖情况给容器中添加相应的嵌入式容器工厂，比如`WebServerFactoryCustomizer`。
2. 容器中某个组件要创建对象就会被后置处理器`WebServerFactoryCustomizerBeanPostProcessor`就会工作。（这里版本不一样，有点难以理解。）
3. 后置处理器，从容器中获取所有的`WebServerFactory`类型的Factory，例如我们之前配置的`ConfigurableWebServerFactory`，调用定制器的定制方法。 

# 嵌入容器启动原理
什么时候创建嵌入式的servlet容器工厂？
什么时候获取嵌入式的Servlet容器并启动tomcat？

以下过程可通过断点慢慢查看。

1. SpringBoot应用运行run方法；
2. SpringBott刷新Ioc容器，即创建Ioc容器对象并初始化容器，包括创建我们容器中的每一个组件；根据不同的环境（是web环境吗）创建不同的容器。
3. 刷新2中创建好的容器（进行了很多步刷新）
4. web ioc容器会创建嵌入式的Servlet容器:createEmbeddedServletContainer().
5. 获取嵌入式的Servlet容器工厂，接下来就是从ioc容器中获取我们之前配置的哪一种类型的组件，后置处理器一看是这个对象，就获取所有的定制器来先定制servlet容器的相关配置；
6. 就进入到我们之前分析的流程；
7. 利用容器工厂获取嵌入式的Servlet容器；
8. 启动serlvet容器；
9. 以上步骤仅仅是onRefresh()方法而已，先启动嵌入式的servlet容器(tomcat)，然后才将ioc容器中剩下的没有创建出的对象获取出来；

> 一句话，ioc容器启动时，会创建嵌入式的servlet容器(tomcat).



