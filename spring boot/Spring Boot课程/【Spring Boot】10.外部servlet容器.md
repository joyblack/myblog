# 简介
前面我们讲了关于嵌入式servlet容器的配置及其工作原理，其优点毫无疑问：
* 简单、便携
* 无需安装tomcat等容器

缺点：
* 默认不支持JSP
* 定制比较复杂（使用定制器(ServerProperties、自定义定制器)，自己编写嵌入式servlet的创建工厂）

但很多时候，还是需要支持JSP，或者需要将应用部署到固定的web容器中，即我们以war对应用进行打包（springboot默认是jar）。

# 创建一个war发布的项目
和之前创建项目的方式一样，只不过在选择发布方式的时候从`jar`变为`war`即可，项目名为jspweb。

由于这是一个以war发布的项目，我们应该创建webapp文件夹以及web.xml描述文件，但是现在没有，因此需要我们去创建。

## 创建web应用目录
在编辑器的右上角有一个名为Project Structure的按钮，打开项目结构配置对话框（ctrl+alt+shift+s）.
1. 点击Models菜单栏
2. 展开jspweb目录树
3. 点击Web模块。我们可以看到右边有两个提示，先点右下部分的，双击弹出提示，点确认，编辑器变为我们创建好了相应的web目录；
4. 在注意上面的一个框，即添加描述文件的(web.xml)，点击`+`按钮，添加一个web.xml文件，注意，路径那里写在我们下面创建的那个web路径下。即`xxx\jspweb\src\main\webapp\WEB-INF\web.xml`，其中XXXX是项目所在的本地路径。

## 配置外部服务器
很显然，此时要项目运行起来，我们得添加外部的servlet容器。在进行如下步骤前，请记得先去tomcat官网下载一个tomcat，安装在本地（解压到本地一个目录即可）。
1. 导入本地tomcat容器
我们需要将本地的tomcat容器整合到idea编辑器中：
  * 点击右上角的下拉框，选择`edit configuration`;
  * 在弹出的对话框中点击左上角的+号，为我们的项目添加运行组件（即tomcat）
  * 往下拉，找到一个名为`tomcat server`的项，点击，选择`local `即本地的tomcat
  * 在对话框右方进行配置信息，例如设置这个项的名称，tomcat的路径两个。
  * 点击上方的选项卡Deployment，配置我们的发布项目，进行关联;
  * 点击右方的+按钮-> artifact -> jspweb:war explorded
  * 点击ok

直接运行项目，就可以直接访问我们的首页了（当然，如果是新项目，当然会跳到找不到页面的错误页面）。

我们可以直接在webapp下面新增一个hello.jsp,然后访问localhost:8080/hello.jsp即可。

## 使用外部容器的步骤
总结一下，我们如果想要用外部容器的话，大概需要如下步骤：
1. 必须创建一个war发布的项目，利用idea把webapp目录以及描述文件创建好；
2. 将嵌入式的tomcat场景启动器指定为provided;
3. 必须编写一个`SpringBootServletInitializer`的子类，目的是为了调用configure方法

``` java
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        // 传入springboot应用的主程序
        return application.sources(JspwebApplication.class);
    }

}
```
4. 配置外部容器，并且将项目发布包进行关联；
5. 启动服务器就可以使用了。

# 外部容器启动原理
回想一下我们之前。
1. jar： 直接执行了springboot的main方法，启动ioc容器，并创建嵌入式的servlet容器；
2. war： 启动服务器，由服务器来启动springboot应用，之后才能启动ioc容器等；

服务器如何启动springboot的？看上一节的代码就可以知道
``` java
public class ServletInitializer extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        // 传入springboot应用的主程序
        return application.sources(JspwebApplication.class);
    }

}
```

## 探究原理
参考文档servlet3.0（Spring注解版）中的8.2.4节： `Shared libraries / runtimes pluggability`，里面定义了这样的规则：
1. 服务器启动（web应用启动）会创建当前web应用里面每一个jar包里面ServletContainerInitializer实例：
2. ServletContainerInitializer的实现放在jar包的META-INF/services文件夹下，有一个名为javax.servlet.ServletContainerInitializer的文件，内容就是ServletContainerInitializer的实现类的全类名
3. 还可以使用@HandlesTypes，在应用启动的时候加载我们感兴趣的类；

接下来分析一下我们这个项目的运行过程
1. 启动Tomcat
2. org\springframework\spring-web\4.3.14.RELEASE\spring-web-4.3.14.RELEASE.jar!\META-INF\services\javax.servlet.ServletContainerInitializer：

其中，Spring的web模块里面有这个文件`org.springframework.web.SpringServletContainerInitializer`;

3. SpringServletContainerInitializer将@HandlesTypes(WebApplicationInitializer.class)标注的所有这个类型的类都传入到onStartup方法的Set<Class<?>>，接下来为这些WebApplicationInitializer类型的类创建实例；

4. 每一个WebApplicationInitializer都调用自己的onStartup；

5. 相当于我们的SpringBootServletInitializer的类会被创建对象，并执行onStartup方法

6. SpringBootServletInitializer实例执行onStartup的时候会createRootApplicationContext；创建容器
```java
protected WebApplicationContext createRootApplicationContext(
      ServletContext servletContext) {
    //1、创建SpringApplicationBuilder
   SpringApplicationBuilder builder = createSpringApplicationBuilder();
   StandardServletEnvironment environment = new StandardServletEnvironment();
   environment.initPropertySources(servletContext, null);
   builder.environment(environment);
   builder.main(getClass());
   ApplicationContext parent = getExistingRootWebApplicationContext(servletContext);
   if (parent != null) {
      this.logger.info("Root context already created (using as parent).");
      servletContext.setAttribute(
            WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, null);
      builder.initializers(new ParentContextApplicationContextInitializer(parent));
   }
   builder.initializers(
         new ServletContextApplicationContextInitializer(servletContext));
   builder.contextClass(AnnotationConfigEmbeddedWebApplicationContext.class);
    
    //调用configure方法，子类重写了这个方法，将SpringBoot的主程序类传入了进来
   builder = configure(builder);
    
    //使用builder创建一个Spring应用
   SpringApplication application = builder.build();
   if (application.getSources().isEmpty() && AnnotationUtils
         .findAnnotation(getClass(), Configuration.class) != null) {
      application.getSources().add(getClass());
   }
   Assert.state(!application.getSources().isEmpty(),
         "No SpringApplication sources have been defined. Either override the "
               + "configure method or add an @Configuration annotation");
   // Ensure error pages are registered
   if (this.registerErrorPageFilter) {
      application.getSources().add(ErrorPageFilterConfiguration.class);
   }
    //启动Spring应用
   return run(application);
}
```

7. Spring的应用就启动并且创建IOC容器

```java
public ConfigurableApplicationContext run(String... args) {
   StopWatch stopWatch = new StopWatch();
   stopWatch.start();
   ConfigurableApplicationContext context = null;
   FailureAnalyzers analyzers = null;
   configureHeadlessProperty();
   SpringApplicationRunListeners listeners = getRunListeners(args);
   listeners.starting();
   try {
      ApplicationArguments applicationArguments = new DefaultApplicationArguments(
            args);
      ConfigurableEnvironment environment = prepareEnvironment(listeners,
            applicationArguments);
      Banner printedBanner = printBanner(environment);
      context = createApplicationContext();
      analyzers = new FailureAnalyzers(context);
      prepareContext(context, environment, listeners, applicationArguments,
            printedBanner);
       
       //刷新IOC容器
      refreshContext(context);
      afterRefresh(context, applicationArguments);
      listeners.finished(context, null);
      stopWatch.stop();
      if (this.logStartupInfo) {
         new StartupInfoLogger(this.mainApplicationClass)
               .logStarted(getApplicationLog(), stopWatch);
      }
      return context;
   }
   catch (Throwable ex) {
      handleRunFailure(context, listeners, analyzers, ex);
      throw new IllegalStateException(ex);
   }
}
```

总结一下启动原理：
* 按照Servlet3.0标准ServletContainerInitializer扫描所有jar包中METAINF/services/javax.servlet.ServletContainerInitializer文件指定的类并加载
* 加载spring web包下的SpringServletContainerInitializer
* 扫描@HandleType(WebApplicationInitializer)
* 加载SpringBootServletInitializer并运行onStartup方法
* 加载@SpringBootApplication主类，启动容器等

先是启动servlet容器，再启动springboot应用，刚好和我们的内嵌方式相反。

至此章节开始之后有一节是讲关于docker相关的知识，这点推荐大家自己去学习相关的书籍和视频就好，不在插入此系列文档之中了。

> docker是一个很棒的理念，相关的衍生技术已经得到了广泛的运用，作为一名it相关的人员，必须得学，因为不是三言两语说得完的，因此，就不在springboot这里说明了。