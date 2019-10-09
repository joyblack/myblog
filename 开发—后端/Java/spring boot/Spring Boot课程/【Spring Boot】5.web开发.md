使用spring boot的开发流程:
1. 创建Spring Boot应用，选中我们需要的模块；
2. Spring Boot已经为我们将所有的场景配置好了(spring-boot-autoconfigure包自动配置)，我们只需要在配置文件中指定对应Properties相关的少量配置就可以运行起来；
3. 编写业务代码。

*自动配置原理？*
> 请记住，饮水则思源，在每运用一个场景的时候，都要记住这是自动配置原理生效的。同时也要思考一下，spring-boot为我们配置了什么？能不能修改？有哪些配置可以修改？是否可以扩展等。

> 一定要记住：xxxAutoConfiguration帮我们在容器中自动的配置相关组件，而其xxxProperties封装了配置文件的内容。

# 5.1 spring boot对静态资源的映射规则
查询类(ctrl+shift+n)`WebMvcAutoConfiguration`查看其源码，与web相关的配置在此处都可以看到：
``` java
@ConfigurationProperties(
    prefix = "spring.resources",
    ignoreUnknownFields = false
)
public class ResourceProperties {
```
也就是说有关配置可以通过spring.resourcec进行设置。
## webjars
再来看
``` java

        public void addResourceHandlers(ResourceHandlerRegistry registry) {
            if (!this.resourceProperties.isAddMappings()) {
                logger.debug("Default resource handling disabled");
            } else {
                Duration cachePeriod = this.resourceProperties.getCache().getPeriod();
                CacheControl cacheControl = this.resourceProperties.getCache().getCachecontrol().toHttpCacheControl();
                if (!registry.hasMappingForPattern("/webjars/**")) {
                    this.customizeResourceHandlerRegistration(registry.addResourceHandler(new String[]{"/webjars/**"}).addResourceLocations(new String[]{"classpath:/META-INF/resources/webjars/"}).setCachePeriod(this.getSeconds(cachePeriod)).setCacheControl(cacheControl));
                }

                String staticPathPattern = this.mvcProperties.getStaticPathPattern();
                if (!registry.hasMappingForPattern(staticPathPattern)) {
                    this.customizeResourceHandlerRegistration(registry.addResourceHandler(new String[]{staticPathPattern}).addResourceLocations(getResourceLocations(this.resourceProperties.getStaticLocations())).setCachePeriod(this.getSeconds(cachePeriod)).setCacheControl(cacheControl));
                }

            }
        }
```
从该代码中我们可以看到，所有`/webjars/**`都去`classpath:/META-INF/resources/webjars`中找资源；
   
   * webjars: 以jar包的方式引入静态资源，如jquery等，我们只需要配置pom文件即可引入这些静态资源，参考:[官网地址](https://www.webjars.org/)

引入jquery：
``` xml
       <dependency>
            <groupId>org.webjars</groupId>
            <artifactId>jquery</artifactId>
            <version>3.3.0</version>
        </dependency>
```
我们将下载到的jquery包展开可以看清楚目录结构，结合上面有关webjars的解释，我们可以尝试通过访问127.0.0.1:8081/webjars/jquery/3.3.0/jquery.js，发现可以成功的访问到该静态资源。也就是说，打包后的项目的确是可以访问到的。

## 静态资源文件夹
还有一种配置资源的方式，"/**"访问当前项目的任何资源：
* classpath:/META-INF/resources/
* classpath:/resources/
* classpath:/static/
* classpath:/public/
* /：当前项目的根路径

也就说，我们在上述文件夹上面放置静态资源，如果没有特别处理，系统默认都是可以访问到的。

## 欢迎页
继续查看该类的源码：
``` java
        @Bean
        public WelcomePageHandlerMapping welcomePageHandlerMapping(ApplicationContext applicationContext) {
            return new WelcomePageHandlerMapping(new TemplateAvailabilityProviders(applicationContext), applicationContext, this.getWelcomePage(), this.mvcProperties.getStaticPathPattern());
        }
```
此处配置的是欢迎页的映射。他都是静态资源文件夹下的所有index.html文件。被`/**`映射。
如localhost:8008则就是访问欢迎页面。

## 默认图标
``` java
            @Bean
            public SimpleUrlHandlerMapping faviconHandlerMapping() {
                SimpleUrlHandlerMapping mapping = new SimpleUrlHandlerMapping();
                mapping.setOrder(-2147483647);
                mapping.setUrlMap(Collections.singletonMap("**/favicon.ico", this.faviconRequestHandler()));
                return mapping;
            }
```
该处配置我们喜欢的图标，即浏览器表标签页左方的小图标。还是映射到了`**.favicon.ico`，也就是我们的所有静态文件夹下面。

从上面可以看出，系统默认用一个`staticLocations`作为映射路径，该路径默认为刚才所列出的默认路径，如果要配置自定义的资源路径，则可以：
```
spring.resources.static-locations=classpath:/hello,classpath:/hello2
```
就可以了，但要注意之前的默认值就不生效了。

# 5.2 模板引擎
市面上比较常用的有JSP、Velocity、FreeMarker、以及Spring boot推荐的Thymeleaf。
> 虽然模板引擎很多，但是其核心思想都是一样的，即按照一定的语法标准，将你的数据转化为实际的html页面，他们的区别只在于语法。

spring boot推荐的themeleaf语法比较简单，而且功能更强大。

## 引入themeleaf
注意，如果是1.x版本的spring boot此处若想使用3.x版本的thymeleaf的话，请在properties配置节配置其版本号以及布局版本号，以覆盖SB中默认的低版本thymeleaf。
``` xml
 <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
        </dependency>
```

查看`spring-boot-autoconfigure`包可以查看到有关thymeleaf相关的配置信息`ThymeleafAutoConfiguration`。其无非就是为thymeleaf添加相关的组件。我们主要关注的是其相关的配置规则：ThymeleafProperties。
``` java
@ConfigurationProperties(
    prefix = "spring.thymeleaf"
)
public class ThymeleafProperties {
    private static final Charset DEFAULT_ENCODING;
    public static final String DEFAULT_PREFIX = "classpath:/templates/";
    public static final String DEFAULT_SUFFIX = ".html";
    private boolean checkTemplate = true;
    private boolean checkTemplateLocation = true;
    private String prefix = "classpath:/templates/";
    private String suffix = ".html";
    private String mode = "HTML";
    private Charset encoding;
    private boolean cache;
    private Integer templateResolverOrder;
    private String[] viewNames;
    private String[] excludedViewNames;
    private boolean enableSpringElCompiler;
    private boolean renderHiddenMarkersBeforeCheckboxes;
    private boolean enabled;
    private final ThymeleafProperties.Servlet servlet;
    private final ThymeleafProperties.Reactive reactive;
```
从默认规则里面我们不难看出很多东西其实已经无需修改，就按该默认配置进行业务代码编写就行了。也就是从配置中可以看出，我们的所有页面只需要放在`classpath:/templates/`资源文件夹下面，并以`.html`即为即可，根本无需其他多余的配置：
``` java
  @RequestMapping("success")
    public String success(){
        return "success";
    }
```
该代码交给thymeleaf渲染`template/success.html`的文件。

# 5.3 thymeleaf语法
详细的官方文件请点击：[参考文档](https://www.thymeleaf.org/doc/tutorials/3.0/usingthymeleaf.pdf)
## 使用步骤：
1.  导入thymeleaf的名称空间在html标签中，这样就有语法提示了；
``` html
<html xmlns:th="http://www.thymeleaf.org">
```
2. controller传值
``` java 
    @RequestMapping("success")
    public String success(Map<String, Object> map){
        map.put("hello", "你好");
        return "success";
    }

```
3. 渲染页使用thymeleaf语法
``` html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
this is success page.
<p th:text="${hello}">这里显示默认信息。</p>
</body>
</html>
```

> 从输出结果可以看出，该页面完全可以独立于出来直接运行，其输出的结果不经过渲染只不过只会输出`这里是默认信息`这样的字段而已，做到了很好的前后端分离。

## 标签语法
改变当前元素的文本内容等，例如：`th：html属性` 其值都可以替换原生的元素对应的值。
相关的介绍参考官方文档；

## 标签语法详解
### th:each
参考文档`Iteration`部分。

该标签用于遍历数组数据。需要注意的是，该标签写在那个标签上，那个标签都会在每次遍历中生成一次。由此我们可以了解到，该标签经常会和表格行标签`<tr>`搭配使用。
``` html
<h1>Product list</h1>
<table>
<tr>
<th>NAME</th>
<th>PRICE</th>
<th>IN STOCK</th>
</tr>
<tr th:each="prod : ${prods}">
<td th:text="${prod.name}">Onions</td>
<td th:text="${prod.price}">2.41</td>
<td th:text="${prod.inStock}? #{true} : #{false}">yes</td>
</tr>
</table>
```

## 表达式语法
1. 简单表达式:
* Variable Expressions: ${...}
* Selection Variable Expressions: *{...}
* Message Expressions: #{...}
* Link URL Expressions: @{...}
* Fragment Expressions: ~{...}
2. Literals(字面量)
* Text literals: 'one text' , 'Another one!' ,…
* Number literals: 0 , 34 , 3.0 , 12.3 ,…
* Boolean literals: true , false
* Null literal: null
* Literal tokens: one , sometext , main ,…
3. Text operations（文本操作）
* String concatenation: +
* Literal substitutions: |The name is ${name}|
3. Arithmetic operations（数学运算）
* Binary operators: + , - , * , / , %
* Minus sign (unary operator): -
4. Boolean operations（布尔运算）
* Binary operators: and , or
* Boolean negation (unary operator): ! , not
5. Comparisons and equality（比较运算）
* Comparators: > , < , >= , <= ( gt , lt , ge , le )
* Equality operators: == , != ( eq , ne )
6. Conditional operators（条件操作）
* If-then: (if) ? (then)
* If-then-else: (if) ? (then) : (else)
* Default: (value) ?: (defaultvalue)
7. Special tokens（特殊标记-token:特征；记号）
* No-Operation: _


以上所有的片段都可以组合使用，例如：
``` html
'User is of type ' + (${user.isAdmin()} ? 'Administrator' : (${user.type} ?: 'Unknown'))
```
## 表达式语法详解
### ${...}
该表达式用于获取变量的值，使用的是OGNL语法：
1. 获取对象的属性、调用方法
2. 使用内置的基本对象
``` java
${session.user.id}
```
3. 内置的工具对象

### *{...}
和${...}的功能是一样的，不过有一个补充使用，即配合`<th:object>`使用，如下面的示例：
``` html
<div th:object="${session.user}">
<p>Name: <span th:text="*{firstName}">Sebastian</span>.</p>
<p>Surname: <span th:text="*{lastName}">Pepper</span>.</p>
<p>Nationality: <span th:text="*{nationality}">Saturn</span>.</p>
</div>
```
其等价于：
``` html
<div>
<p>Name: <span th:text="${session.user.firstName}">Sebastian</span>.</p>
<p>Surname: <span th:text="${session.user.lastName}">Pepper</span>.</p>
<p>Nationality: <span th:text="${session.user.nationality}">Saturn</span>.</p>
</div>
```
也就是说，用`*{}`可以省略公共的对象信息。当然，我们也可以在循环体内部混合使用这两种语法：
``` html
<div th:object="${session.user}">
<p>Name: <span th:text="*{firstName}">Sebastian</span>.</p>
<p>Surname: <span th:text="${session.user.lastName}">Pepper</span>.</p>
<p>Nationality: <span th:text="*{nationality}">Saturn</span>.</p>
</div>
```
### #{...}
该表达式用于获取国际化内容。

### @{...}
定义url。
``` html
<!-- Will produce 'http://localhost:8080/gtvg/order/details?orderId=3' (plus rewriting) -->
<a href="details.html"
th:href="@{http://localhost:8080/gtvg/order/details(orderId=${o.id})}">view</a>
<!-- Will produce '/gtvg/order/details?orderId=3' (plus rewriting) -->
<a href="details.html" th:href="@{/order/details(orderId=${o.id})}">view</a>
<!-- Will produce '/gtvg/order/3/details' (plus rewriting) -->
<a href="details.html" th:href="@{/order/{orderId}/details(orderId=${o.id})}">view</a>
```
如果需要添加多个参数的话，用逗号分隔即可。
```
@{/order/process(execId=${execId},execType='FAST')}
```
### ~{...}
片段引用表达式。
``` html
<div th:insert="~{commons :: main}">...</div>
```

## 行内表达式
参考文档`Inlining`部分。

很多时候，我们想显示的文本其实是单纯的文本节点，完全不想使用html标签包裹，这时候需要怎么写呢。我们显然不能这样写:
``` html
my name is ${$name}.
```
正确的写法应该使用行内表达式
```
my name is [[${name}]]!
```
关于行内式有两种标签写法：
* `[[...]]` 等价于`th:text`，会转义特殊字符，即按原样输出，`<h1>`标签会格式化内部文字；
* `[(...)]` 等价于`th:utext`，不会转义特殊字符，即按相应的标签格式输出，例如`<h1>`标签直接输出为`<h1>`。

> 转义这个有点绕，不小心把自己也绕进去了。简单一点的记法：想要有html标签格式化文本，用`text`(`[[...]]`)，想原样输出标签用`utext`，。

# 5.4 spring mvc自动配置
## 通过官方文档查阅

## 源码查阅
[查看文档](https://docs.spring.io/spring-boot/docs/2.1.1.RELEASE/reference/htmlsingle/#boot-features-developing-web-applications)

Spring boot 自动配置好了Spring mvc，以下是SB对spring mvc的默认配置，这些配置组件都可以在`WebMvcConfigurationSupport`类中查看相应源码：
1. 自动配置了ViewResoulver（视图解析器：根据方法的返回值得到视图对象(View)，视图对象决定如何渲染...转发、重定向）
    * `ContentNegotiatingViewResolver `: 组合所有的视图解析器。
    * 如何定制：我们可以自己给容器中添加一个视图解析器，他会自动的将其组合起来。

2. Support for serving static resources, including support for WebJars (covered later in this document))： 静态资源文件夹路径,webjars.
3. Automatic registration of Converter, GenericConverter, and Formatter beans.
    * Converter:转换器，类型转化
    * Formatter 格式化器：2017.1.1===Date;
4. Support for `HttpMessageConverters` (covered later in this document)
    * springMVC中用来转换http请求和响应的User===Json
    * HttpMessageConverters是从容器中确定获取所有的HttpMessageConver;自己给容器中添加赌赢的组件，只需要将自己的组件注册到容器中即可(@Bean，@Component)
5. Automatic registration of `MessageCodesResolver` (covered later in this document).
    * 定义错误代码的生成规则的；
6. Static `index.html` support.
    * 静态页面支持
7. Custom Favicon support (covered later in this document).
    * 图标支持
8. Automatic use of a `ConfigurableWebBindingInitializer` bean (covered later in this document).
    * 作用为初始化WebDataBinder的，例如请求数据JavaBean，就需要用到数据绑定器，里面牵涉到类型转化、格式化等等；
    * 我们可以配置一个ConfigurableWebBindingInitializer来替换默认的。

> SB对web的自动配置其实不止这个类中做了，其实还有其他的以***AutoConfiguration的类，都对web场景进行了一些配置。

# 5.5 修改SpringBoot的默认配置
模式：给容器中添加对应的自定义组件就可以了。
1. Spring Boot在自动配置很多组件的时候，都会先看容器中有没有用户自己配置(@Bean、@Component)，如果有就用用户配置的，如果没有就用Spring Boot自己默认配置的;但是如果组件可以有多个的话，则是将其所有配置的组合起来；
2. 仅靠Spring boot的默认配置还是不够的，我们还需要一些自己新的配置，那么我们则需要扩展以及全面接管springMVC的相关功能。如何做呢？见下一节。

# 5.6 扩展与全面接管SpringMVC
我们以前配置试图映射、拦截器都可以在springmvc.xml中进行配置，如下图所示：
``` xml
```xml
    <mvc:view-controller path="/hello" view-name="success"/>
    <mvc:interceptors>
        <mvc:interceptor>
            <mvc:mapping path="/hello"/>
            <bean></bean>
        </mvc:interceptor>
    </mvc:interceptors>
```

那在spring boot中该怎么做呢？

编写一个配置类(`@Configuration`)，是`WebMvcConfigurerAdapter`类型；不能标注`@EnableWebMvc`；
> 注意此处是1.x版本，2.x版本提示这个类准备移除了，我们不再需要继承`WebMvcConfigurerAdapter`,而是直接实现接口`WebMvcConfigurer`来写配置类即可。
``` java
@Configuration
public class MyConfig implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 浏览器发送/restweb也会来到hello页面.
        registry.addViewController("/restweb").setViewName("hello");
    }
}
```
该方式即保留了spring boot的所有自动配置，也能用我们的扩展配置。可以查看如下了解原理：
* WebMvcAutoConfiguration是springmvc的自动配置类；
* 再做其他自动配置时会导入，`@import(EnableWebMvcConfiguration.class)`

``` java
	@Autowired(required = false)
	public void setConfigurers(List<WebMvcConfigurer> configurers) {
		if (!CollectionUtils.isEmpty(configurers)) {
			this.configurers.addWebMvcConfigurers(configurers);
		}
	}
```
> spring boot 会将所有的WebMvcConfiguration相关配置一起调用
* 容器中所有的WebMvcConfigurer都会起作用，包括我们自己配置的；

### 全面接管SpringMVC
这种情况下，我们一般是不想要SpringBoot的所有配置，所有的都是由我们自己来指定。只需要在自定义配置类中添加一个配置`@EnableWebMvc`即可，这样之后所有的SpringMVC的自动配置都失效了。

`@EnableWebMvc`原理：
``` java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Documented
@Import(DelegatingWebMvcConfiguration.class)
public @interface EnableWebMvc {
}
```
注意其中的`DelegatingWebMvcConfiguration`，其源码如下：
``` java
@Configuration
public class DelegatingWebMvcConfiguration extends WebMvcConfigurationSupport {
```
我们再来看自动配置类的源码：
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
我们可以看到这一句
``` java
@ConditionalOnMissingBean({WebMvcConfigurationSupport.class})
```
其生效方式刚好就是若容器中没有`WebMvcConfigurationSupport`，由于前面的注解导致该组件导入了进来，因此自动配置类就不生效了。导入的`WebMvcConfigurationSupport`只是SpringMVC最基本的功能。

> 使用SpringBoot一般不推荐SpringMVC全面接管（那就没必要用SpringBoot了）

# 5.7 restweb制作
## 引入资源
添加entities包以及dao包，引入测试用例类以及静态资源，这里参考原视频教程配套代码。
添加thymeleaf场景包，springboot会自动启用该场景:
``` xml
  <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
        </dependency>
```

## 配置首页映射
我们已经将index.html放在了template文件夹下面，此时，我们为了将index.html映射到网站的首页，一般会写如下的控制方法:
``` java
@RequestMapping({"/","index.html"})
    public String index(){
        return "index";
    }
```
该控制器方法可以将请求路径`"/","index.html"`都映射为index.html的资源信息（thymeleaf渲染），还可以通过在配置类中配置映射的方式完成上述效果：
``` java
  @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 浏览器发送/restweb也会来到hello页面.
        registry.addViewController("/").setViewName("index");
       // registry.addViewController("/index.html").setViewName("index");
    }
```
再有，我们前面有讲到，springboot会将我们生成的所有组件添加到相应的组件族中，因此，我们这里也可以手动的创建一个WebMvcConfigurer，也同样生效（别忘了添加组件注解:`@Bean`，将组件注册到容器中）,上下两端代码完成的效果是一致的，当然也可以是互补的（映射不同的话）：
``` java
    @Bean
    public WebMvcConfigurer myWebMvcConfigurer(){
        return new WebMvcConfigurer() {
            @Override
            public void addViewControllers(ViewControllerRegistry registry) {
                registry.addViewController("/index").setViewName("index");
            }
        };
    }
```

## 通过webjars引入其他静态资源
``` xml
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>jquery</artifactId>
    <version>3.3.1-1</version>
</dependency>
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>bootstrap</artifactId>
    <version>4.1.3</version>
</dependency>
```
引入之后，则可以将之前的相对路径引入的静态资源替换掉了，找到index.html页面（改为login.html），使用`th:xxx`修改路径引入：
``` html
<link th:href="@{/webjars/bootstrap/4.1.3/css/bootstrap.css}" href="asserts/css/bootstrap.min.css" rel="stylesheet">
```
> `<html xmlns:th="http://www.thymeleaf.org">` 别忘了通过这个可以添加thymeleaf语法提示哦。

# 5.8 国际化
在springMVC中，我们需要：
1. 编写国际化配置文件;
2. 使用ResourcebundleMessageSource管理国际化资源文件;
3. 在页面使用fmt:message提取国际化内容。

步骤：
1. 编写国际化配置文件，抽去页面需要显示的国际化信息；
    * 在`/resource`目录下新建i18n文件夹
    * 在i18n下建立login文件夹
    * 创建login.properties代表默认显示、login_en_US.properties（英国）、login_zh_CN.properties（中国）；
    * 在编译器提供的国际化操作界面一次性写入相关的文本信息，如:login.username login.password等(在同一界面进行配置，手写比较繁琐。)。
2. 如果是SpringMVC的话，如上面步骤所示，我们还要配置使用`ResourcebundleMessageSource`管理国际化资源文件，在spring boot中，则不需要了（他已经帮我配置好了）。查看类`MessageSourceAutoConfiguration`中已经有该组件的配置了。
``` java
@Configuration
@ConditionalOnMissingBean(
    value = {MessageSource.class},
    search = SearchStrategy.CURRENT
)
@AutoConfigureOrder(-2147483648)
@Conditional({MessageSourceAutoConfiguration.ResourceBundleCondition.class})
@EnableConfigurationProperties
public class MessageSourceAutoConfiguration {
     @Bean
    @ConfigurationProperties(
        prefix = "spring.messages"
    )
    public MessageSourceProperties messageSourceProperties() {
        return new MessageSourceProperties();
    }
```
配置了组件
``` java
 @Bean
    public MessageSource messageSource(MessageSourceProperties properties) {
        ResourceBundleMessageSource messageSource = new ResourceBundleMessageSource();
        if (StringUtils.hasText(properties.getBasename())) {
            messageSource.setBasenames(StringUtils.commaDelimitedListToStringArray(StringUtils.trimAllWhitespace(properties.getBasename())));
        }

```
我们注意到这里
``` java
 String basename = context.getEnvironment().getProperty("spring.messages.basename", "messages");
```
也就是说，我们的配置文件可以直接放在类路径下叫messages.properties即可，但是这样做显然不是很好，因此我们只需要修改`spring.messages.basename`配置即可自定义国际化内容的存放位置。
``` properties
spring.messages.basename=i18n/login
```
> 再次提醒，这里2.x版本. 1.x版本这里似乎是不一样的写法都行`i18n.login`
3. 去页面获取国际化的值
还记得学习thymeleaf的时候讲过一个获取国际化值的标签吗？没错，就是他：
``` html
#{...}
```
部分源码如下：
``` html
<input type="text" class="form-control" th:placeholder="#{login.username}" placeholder="Username" required="" autofocus="">
```
## 区域信息对象
现在我们想通过点击下方的`中文``English`两个按钮切换国际化页面该怎么做呢？

国家化Locale（区域信息对象）；LocaleResolver获取区域信息对象,在`WebMvcAutoConfiguration`:
```java
@Bean
        @ConditionalOnMissingBean
        @ConditionalOnProperty(
            prefix = "spring.mvc",
            name = {"locale"}
        )
        public LocaleResolver localeResolver() {
            if (this.mvcProperties.getLocaleResolver() == org.springframework.boot.autoconfigure.web.servlet.WebMvcProperties.LocaleResolver.FIXED) {
                return new FixedLocaleResolver(this.mvcProperties.getLocale());
            } else {
                AcceptHeaderLocaleResolver localeResolver = new AcceptHeaderLocaleResolver();
                localeResolver.setDefaultLocale(this.mvcProperties.getLocale());
                return localeResolver;
            }
        }
```
默认的区域信息解析器就是根据请求头带来的区域信息进行的国际化。
```
Accept-Language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7 
```
因此，我们完全可以自己写一个区域化信息解析器来自己处理请求信息。
1. 修改切换按钮的链接信息:
``` html
<a class="btn btn-sm" th:href="@{/index.html(l='zh_CN')}">中文</a>
			<a class="btn btn-sm" th:href="@{/index.html(l='en_US')}">English</a>
```
2. 自定义一个区域信息解析器：
```java
package com.sunrun.emailanalysis.component;

import org.springframework.util.StringUtils;
import org.springframework.web.servlet.LocaleResolver;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Locale;

public class JoyLocaleResolver implements LocaleResolver {
    @Override
    public Locale resolveLocale(HttpServletRequest httpServletRequest) {
        // url have "l" param.
        String localName = httpServletRequest.getParameter("l");
        Locale locale = Locale.getDefault();
        if(!StringUtils.isEmpty(localName)){
            String[] split = localName.split("_");
            locale = new Locale(split[0], split[1]);
        }
        return locale;
    }

    @Override
    public void setLocale(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Locale locale) {

    }
}

```

别忘了添加该组件：
``` java
  @Bean
    public LocaleResolver localeResolver(){
        return new MyLocaleResolver();
    }
```
> 注意此处方法名必须写为`localResolver`，因为Spring会默认将其作为Bean的名字，而SB的默认区域解析器会以此作为是否生成的条件。

3. 点击链接，即可实现切换国际化。

# 5.9 拦截器
## 模板修改实时生效
模板引擎修改以后，若想实时生效，需要做如下操作：

（1） 禁用模板引擎缓存（开发过程中建议关闭，生产环境可开启）
```
spring.thymeleaf.cache=false
```
（2）idea编译器的话，按ctrl + F9，重新编译一下即可。

## 登录错误消息的提示
> #工具.工具方法 if标签的优先级比text高
``` html
<p style="color:red" th:text="{msg}" th:if="${not #strings.isEmpty(msg)}"></p>
```

## 重定向防止表单重复提交
``` java
return "redirect:/main.html"
```

## 拦截器
通过进行登录检查，即实现SpringMVC中的`HandlerIntercepter`拦截方法.

### LoginController 登录逻辑检测
``` java
@Controller
public class LoginController {
    @PostMapping(value = {"/user/login"})
    public String login(@RequestParam("username")String username,
                        @RequestParam("password") String password,
                        HttpSession session,
                        Map<String, Object> map){
        if(!StringUtils.isEmpty(username) && "123456".equals(password)){
            session.setAttribute("loginUser","admin");
            return "redirect:/index";
        }else{
            map.put("msg", "用户名或密码错误");
            return "login";
        }

    }
}
```
其中:
1. ` @PostMapping(value = {"/user/login","login"})` 等价于 
    `@RequestMapping(value={"/user/login","login"}, method = RequestMethod.POST)`;
2. `@RequestParam("username")` 强调该请求必须接受一个名为username的参数，否则会报400错误，并提示要求的参数不存在。
3. 如果我们直接返回`index`给模板引擎解析，显然当前是转发user/login请求，如果我们刷新页面，会出现表单的重复提交，并且，如果index.html中如果写的是相对路径，则其路径会误认为user是一个项目名称，导致资源全部引入失败。因此，我们需要将其重定向。
``` java
 return "redirect:/index";
```

### 视图解析器添加相关映射
``` java
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 浏览器发送/restweb也会来到hello页面.
        registry.addViewController("/login").setViewName("login");
        registry.addViewController("/").setViewName("index");
        registry.addViewController("/index").setViewName("index");
    }
```
其中：
```java
registry.addViewController("/login").setViewName("login");
```
就等价于我们写一个Controller进行映射:
``` java
@RequestMapping(value="/login")
public String login(){
    return "login";
}
```
因此，如果只是单纯的映射跳转而没有其他的**业务逻辑**的话，推荐在这里直接配置即可。

### 配置拦截器
首先，我们要编写一个拦截器组件：
``` java
public class LoginHandlerInterupter implements HandlerInterceptor {
    /**
     * 其他的方法由于java8的default，我们可以不实现了，专心写这部分代码进行登录检查即可
     * @param request
     * @param response
     * @param handler
     * @return
     * @throws Exception
     */
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        Object loginUser = request.getSession().getAttribute("loginUser");
        // 若登录，放行请求
        if(loginUser != null){
            return true;
        }
        request.setAttribute("msg","未登录，请先登录");
        System.out.println("this is is a preHandler method.");
        request.getRequestDispatcher("/login").forward(request, response);
        return false;
    }
}
```
注意：
* 自定义的拦截器都要实现`HandlerInterceptor`接口，通过查看该接口的源码可以发现：
``` java
	default boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
			throws Exception {

		return true;
	}
```
其所有的方法都用了java8新关键字`default`修饰了所有的接口方法，因此，在我们的实现类中，无需实现所有的方法（如果不了解的话，请参考java8相关书籍——推荐 **java8实战** ，大概就是default修饰的方法不需要实现类实现了，挑自己想覆盖的方法覆盖即可。）

* 我们这里实现preHandler方法，该方法会在所有的Http请求之前执行，也就是说，我们可以通过此方法对Session进行检索，从而判断用户此刻是否登录。若登录，我们放行请求；若未登录，则对请求惊醒拦截，并且将当前请求跳转到登录界面；

### 添加拦截器组件到容器
添加拦截器组件到容器中，并配置相关的参数：
``` java
    /**
     * 添加自定义拦截器到容器中，并配置相关参数
     * @param registry
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 视频中老师有讲到spring boot已经对静态资源做了映射，不过他是针对1.x版本这样解释，但是我2.0版本这里是不行的，还是得放行静态资源，所以加了/assert和webjars这两个静态资源路径的放行，不然静态资源还是会被拦截下来。请注意一下。
        registry.addInterceptor(new LoginHandlerInterupter()).addPathPatterns("/**")
                . excludePathPatterns("/login","/user/login","/asserts/**","/webjars/**");
    }
```
* 该覆盖方法配置在实现`WebMvcConfigurer`的配置类中，目前其完全代码如下所示：
``` java

@Configuration
public class MyConfig implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // 浏览器发送/restweb也会来到hello页面.
        registry.addViewController("/login").setViewName("login");
        registry.addViewController("/").setViewName("index");
        registry.addViewController("/index").setViewName("index");
    }

      /**
     * 添加自定义拦截器到容器中，并配置相关参数
     * @param registry
     */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // SB已经对静态资源 *.css , *.jss进行了映射，我们可以不加管理
        registry.addInterceptor(new LoginHandlerInterupter()).addPathPatterns("/**")
                . excludePathPatterns("/login","/user/login","/asserts/**","/webjars/**");
    }

    /**
     * 自定义本地解析器
     * @return
     */
    @Bean
    public LocaleResolver localeResolver(){
        return new MyLocaleResolver();
    }

```
可以看到，该配置类实现`WebMvcConfigurer`接口，用于修改spring mvc相关的默认配置，比如这里添加了视图控制器、拦截器，另外则是一个之前为了做本地化配置的自定义本地化解析器。
* `addPathPatterns("/**")` 表明该拦截器会拦截所有的请求
* `.excludePathPatterns("/login","/user/login")`表明`"/login","/user/login","/asserts/**","/webjars/**"`这四个请求，是特殊的、不拦截的，注意后两个是资源文件入口。

### 测试运行
测试运行正常的登录，一切运行正常。









