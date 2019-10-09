# 简介
错误处理机制说起来是每个网站架构开发的核心部分，很多时候我们并没有去关注他们，其实错误在我们日常访问过程中时长出现，对错误机制进行了解也是开发一个好的网站所必备的技能之一。

# 默认错误反馈
spring boot默认会根据不同的请求客户端，返回不同的结果：
1、情况一：返回一个默认的错误页面
   
当我们使用web访问出错的时候，会跳到这样的错误页面，其信息如下所示：
```
Whitelabel Error Page
This application has no explicit mapping for /error, so you are seeing this as a fallback.

Mon Dec 17 14:50:33 CST 2018
There was an unexpected error (type=Bad Request, status=400).
Failed to convert value of type 'java.lang.String' to required type 'java.lang.Integer'; nested exception is java.lang.NumberFormatException: For input string: "aaa"
```

2、 情况二：返回json信息

当我们使用其他的客户端，例如postman模拟请求的时候，返回的信息则是json数据格式：
``` json
{
    "timestamp": "2018-12-17T06:59:00.851+0000",
    "status": 404,
    "error": "Not Found",
    "message": "No message available",
    "path": "/somepage"
}
```

> 这里要模拟一个`页面不存在的错误`错误，最好先把登录过滤器关掉，否则请求任何不存在的页面都会给你过滤到登录界面，不会出现错误信息。

# SpringBoot错误处理过程
我们开发网站过程中，显然不会使用这些默认方式，而是要自己去定制反馈结果的。但我们首先还是先去了解SpringBoot的默认错误处理过程，了解一下原理。

参考自动配置类`ErrorMvcAutoConfiguration`。我们看看该自动配置类为容器中添加了如下组件：
* DefaultErrorAttributes 记录错误相关的信息并将其共享；
* BasicErrorController
  

查看BasicErrorController源码
``` java
@Controller
@RequestMapping({"${server.error.path:${error.path:/error}}"})
public class BasicErrorController extends AbstractErrorController {
    
    @RequestMapping(
        produces = {"text/html"}
    )
    public ModelAndView errorHtml(HttpServletRequest request, HttpServletResponse response) {
        HttpStatus status = this.getStatus(request);
        Map<String, Object> model = Collections.unmodifiableMap(this.getErrorAttributes(request, this.isIncludeStackTrace(request, MediaType.TEXT_HTML)));
        response.setStatus(status.value());
        // 去哪个页面作为错误页面：包含页面的地址和内容
        ModelAndView modelAndView = this.resolveErrorView(request, response, status, model);
        return modelAndView != null ? modelAndView : new ModelAndView("error", model);
    }

    @RequestMapping
    public ResponseEntity<Map<String, Object>> error(HttpServletRequest request) {
        Map<String, Object> body = this.getErrorAttributes(request, this.isIncludeStackTrace(request, MediaType.ALL));
        HttpStatus status = this.getStatus(request);
        return new ResponseEntity(body, status);
    }
}
```

可以知道，该组件用于默认处理`/error`请求，其中需要留意：

* ErrorPageCustomizer 系统出现错误的时候来到error请求进行处理，类似于`error.xml`里配置的错误页面规则。
* DefaultErrorViewResolver

# 错误处理的流程
一旦系统出现4XX或者5XX之类的错误，ErrorPageCustomizer就会生效（定制错误的响应规则），使请求来到`/error`。这时候，BasicErrorController控制器会处理这个请求。

观看上述代码我们可以发现，之所以出现两种错误结果，无非就是对error进行处理的controller会根据不同的请求头：
* `Accept: text/html`
* `Accept:"*/*"`
  
这两者进行不同的反馈，前者返回错误页面信息，后者返回json数据。我们来看看错误响应页面的视图解析器：
``` java
    protected ModelAndView resolveErrorView(HttpServletRequest request, HttpServletResponse response, HttpStatus status, Map<String, Object> model) {
        Iterator var5 = this.errorViewResolvers.iterator();

        ModelAndView modelAndView;
        do {
            if (!var5.hasNext()) {
                return null;
            }

            ErrorViewResolver resolver = (ErrorViewResolver)var5.next();
            modelAndView = resolver.resolveErrorView(request, status, model);
        } while(modelAndView == null);

        return modelAndView;
    }
```
这段代码拿到了异常视图解析器（`ErrorViewResolvers`）类型来进行处理，当前我们注册的是`DefaultErrorViewResolver`，查看源码：
``` java
    public ModelAndView resolveErrorView(HttpServletRequest request, HttpStatus status, Map<String, Object> model) {
        ModelAndView modelAndView = this.resolve(String.valueOf(status.value()), model);
        if (modelAndView == null && SERIES_VIEWS.containsKey(status.series())) {
            //status.series() 状态码
            modelAndView = this.resolve((String)SERIES_VIEWS.get(status.series()), model);
        }
        
        return modelAndView;
    }

    private ModelAndView resolve(String viewName, Map<String, Object> model) {
        String errorViewName = "error/" + viewName;
        TemplateAvailabilityProvider provider = this.templateAvailabilityProviders.getProvider(errorViewName, this.applicationContext);
        return provider != null ? new ModelAndView(errorViewName, model) : this.resolveResource(errorViewName, model);
    }
```
默认spring boot会去找到某个页面：error/状态码.html。



# 定义错误页面
## 有模板引擎的情况下

跳转到模板页面：error/状态码，也就是说，我们如果想自定义错误页面的话，将错误页面命名为状态码.html，并放在模板文件夹（templates）的error文件夹下，发生此状态码的错误就会来到对应的页面；查看源码我们也可以发现，命名为4xx.html（5xx.html）则可以处理所有以4(5)开头的错误码错误，即都可以跳到该页面；不过spring boot会优先寻找直接对应的错误页面，如果404错误会优先选取404.html作为错误页面；

错误页面能获取到的信息(`DefaultErrorAttributes`)：
* timestamp 时间戳
* status 状态码
* error 错误提示
* exception 异常对象
* message 异常信息
* error JSR303数据校验的错误都在这里

即我们可以在错误页面里获取到错误信息，示例如下：
``` html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <h1>This is 4xx error page:</h1>
    <p>*timestamp: [[${timestamp}]]</p>
    <p>*status: [[${status}]]</p>
</body>
</html>
```

## 没有模板引擎的情况下
即我们没有对应的error错误文件夹，也可以放在静态资源文件夹下。

例如，放在static文件夹下，同样可以来到该页面，只不过不能被模板引擎渲染而已。

## 以上两种都不满足的情况下

这种情况会来到SpringBoot默认的错误提示页面，该视图对象的信息我们可以通过查看源码获悉，其位置位于`ErrorMvcAutoConfiguration`中:
``` java
    @Configuration
    @ConditionalOnProperty(
        prefix = "server.error.whitelabel",
        name = {"enabled"},
        matchIfMissing = true
    )
    @Conditional({ErrorMvcAutoConfiguration.ErrorTemplateMissingCondition.class})
    protected static class WhitelabelErrorViewConfiguration {
        private final ErrorMvcAutoConfiguration.StaticView defaultErrorView = new ErrorMvcAutoConfiguration.StaticView();

        protected WhitelabelErrorViewConfiguration() {
        }

        @Bean(
            name = {"error"}
        )
        @ConditionalOnMissingBean(
            name = {"error"}
        )
        public View defaultErrorView() {
            return this.defaultErrorView;
        }

        @Bean
        @ConditionalOnMissingBean
        public BeanNameViewResolver beanNameViewResolver() {
            BeanNameViewResolver resolver = new BeanNameViewResolver();
            resolver.setOrder(2147483637);
            return resolver;
        }
    }
```

# 定义错误信息
spring boot会根据请求头给予不同的返回类型数据。上一节讲到的是定义错误页面，还差一种方式：即其他客户端访问情况下返回json数据的问题，这一节，来处理这个问题。即如何定制错误的json数据。

## 自定义异常处理
我们先自定义一种异常，例如用户不存在的异常：

#### exception/UserNotExistException.class
``` java
package com.zhaoyi.springboot.restweb.exception;

public class UserNotExistException extends RuntimeException{
    public UserNotExistException(){
        super("用户不存在");
    }
}
```

然后在应用程序的某个地方抛出该异常：
#### controller/HelloController.class
``` java
    @RequestMapping({"user"})
    public String index(@RequestParam("user") String user){
        if(user.equals("aaa")){
            throw new UserNotExistException();
        }
       return "index";
    }
```
> 通过访问`/user?user=aaa`触发该异常。

显然，如果我们不做任何处理，SpringBoot会默认将错误处理到我们之前配置过的页面，运行时错误对应的是500，即会跳转到我们的5xx页面：
```
this is 5xx error page:
status ------ 500

message ------ 用户不存在
```

那么，我们该如何将此错误自定义呢，可以运用springMVC的知识，在controller下面定义个异常处理器:

#### controller/MyExceptionHandler.class
``` java
package com.zhaoyi.springboot.restweb.controller;

import com.zhaoyi.springboot.restweb.exception.UserNotExistException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
public class MyExcetionHandler {
    @ResponseBody
    @ExceptionHandler(UserNotExistException.class)
    public Map<String,Object> handlerException(Exception e){
        Map<String, Object> map = new HashMap<>();
        map.put("myCode", "custom code");
        map.put("message", e.getMessage());
        return map;
    }
}

```

我们在此访问同样的触发异常的地址，就可以如愿的得到自己想要的自定义错误信息了:
``` json
{"myCode":"custom code","message":"用户不存在"} 
```
但这种方式有点问题，没有自适应效果，也就是我们用浏览器也好，其他的客户端也好，返回的都是这段json数据。那么，我们如何想springboot那样做到异常返回的自适应呢？(浏览器返回错误页面，其他客户端返回json数据)。很简单，转发到`/error`，交由SpringBoot处理即可。
```

```
> 注意注释掉之前的处理代码。

这时候，我们如果换用不同的客户端访问就会得到相应的反馈了，比如用浏览器可以得到如下的返回数据：
``` html
<html>
<body>
<h1>Whitelabel Error Page</h1>
<p>This application has no explicit mapping for /error, so you are seeing this as a fallback.
</p>
<div id='created'>Mon Dec 17 16:15:30 CST 2018</div>
<div>There was an unexpected error (type=OK, status=200).</div><div>?????</div></body></html>
```

但是新的问题又出现了，即：我们自定义的页面并没有得到解析，springboot还是默认使用了之前分析过的，什么都没有定义的时候跳转到空白错误页面的情况。

仔细观察我们会发现，其实是错误状态码有问题，这里是错误码已经由500变为了200.问题出在哪里呢？出在我们在转发的时候，没有设置一个错误状态码：因此，我们还需要在转发之前*设置状态码*。如何设置，先来查看springboot相关处理错误信息的源码

#### BasicErrorController.class
``` java
    @RequestMapping(
        produces = {"text/html"}
    )
    public ModelAndView errorHtml(HttpServletRequest request, HttpServletResponse response) {
        // 通过此处获取错误码
        HttpStatus status = this.getStatus(request);
        Map<String, Object> model = Collections.unmodifiableMap(this.getErrorAttributes(request, this.isIncludeStackTrace(request, MediaType.TEXT_HTML)));
        response.setStatus(status.value());
        ModelAndView modelAndView = this.resolveErrorView(request, response, status, model);
        return modelAndView != null ? modelAndView : new ModelAndView("error", model);
    }
```

继续定位源码`this.getStatus(request);`:
#### AbstractErrorController.class
``` java
    protected HttpStatus getStatus(HttpServletRequest request) {
        Integer statusCode = (Integer)request.getAttribute("javax.servlet.error.status_code");
        if (statusCode == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        } else {
            try {
                return HttpStatus.valueOf(statusCode);
            } catch (Exception var4) {
                return HttpStatus.INTERNAL_SERVER_ERROR;
            }
        }
    }
```

因此，我们只需要在`request`域中添加一个`javax.servlet.error.status_code`属性，就可以以最优先的级别情况设置状态码了。所以，改造后的代码应该如下所示：
#### MyExcetionHandler
``` java
    @ExceptionHandler(UserNotExistException.class)
    public String handlerException(Exception e, HttpServletRequest request){
        Map<String, Object> map = new HashMap<>();
        request.setAttribute("javax.servlet.error.status_code", 500);
        map.put("myCode", "custom code");
        map.put("message", e.getMessage());
        return "forward:/error";
    }
```

这时候在运行发现可以调到我们自定义的5xx.html错误页面了。显示如下：
```
this is 5xx error page:
status ------ 500

message ------ 用户不存在

myCode ------ 
```

问题还是有，我们会发现，我们自定义的数据不见了(`myCode`)，错误页面只能获取到SpringBoot默认写入的信息。因此我们还得继续探索，如何才能既能调到自定义错误页面，又能携带我们自定义的错误数据。

我们知道，出现错误以后，会相应到/error请求，同时交由BasicErrorController进行处理，他在处理错误的时候进行了自适应处理，响应回来并可以获取的数据是`getErrorAttributes(是BasicErrorController的父类AbstractErrorController中定义的)`得到的。

我们则完全可以编写一个ErrorController的实现类（或者继承BasicErrorController），放在容器中。想想有点麻烦，当然，还有选择。

第二种办法，注意第一种方法的某句话`errorAttributes.getErrorAttributes....`，页面上能用的数据，或者是json返回能用的数据都是通过他来得到的。查看ErrorAttribute的来源：

#### ErrorMvcAutoConfiguration.class
``` java
    @Bean
    @ConditionalOnMissingBean(
        value = {ErrorAttributes.class},
        search = SearchStrategy.CURRENT
    )
    public DefaultErrorAttributes errorAttributes() {
        return new DefaultErrorAttributes(this.serverProperties.getError().isIncludeException());
    } 
```

容器中的DefaultErrorAttributes来进行数据处理的，所以，我们自己配置一个实现了ErrorAttributes类型接口这样的Bean就可以了，但是为了方便，我们最好继承spring boot默认使用的`DefaultErrorAttributes`来实现即可。

自定义ErrorAttribute，改变默认行为
#### componet/MyErrorAttributes.class
``` java
package com.zhaoyi.springboot.restweb.component;

import org.springframework.boot.web.servlet.error.DefaultErrorAttributes;
import org.springframework.boot.web.servlet.error.ErrorAttributes;
import org.springframework.web.context.request.WebRequest;

import java.util.Map;

@Componet
public class MyErrorAttributes extends DefaultErrorAttributes {
    @Override
    public Map<String, Object> getErrorAttributes(WebRequest webRequest, boolean includeStackTrace) {
        Map<String, Object> errorAttributes = super.getErrorAttributes(webRequest, includeStackTrace);
        // 这里随便写一个自己的
        errorAttributes.put("someCode", "attribute add atrribute");
        // 从request请求域中获取ext的值
        errorAttributes.put("ext", webRequest.getAttribute("ext", WebRequest.SCOPE_REQUEST));
        return errorAttributes;
    }
}
```

> 注意：这是一个组件，不要忘记添加`@Componet`注解，不然无法加入到容器中。

在这里我们使用request域传递信息，并且通过`WebRequest.getAttribute("param", SCOPE)`获取其信息，`WebRequest.SCOPE_REQUEST`的取值对应什么，点进WebRequest代码内容就可以看到对应信息了。这样，我们还需要修改异常处理器的代码，如下所示:

#### MyExceptionHandler.class
``` java
    @ExceptionHandler(UserNotExistException.class)
    public String handlerException(Exception e, HttpServletRequest request){
        Map<String, Object> map = new HashMap<>();
        request.setAttribute("javax.servlet.error.status_code", 500);
        map.put("myCode", "custom code");
        map.put("message", e.getMessage());
        request.setAttribute("ext", map);
        return "forward:/error";
    }
```

使用postman访问异常页面，返回结果如下：
``` json
{
    "timestamp": "2018-12-17T08:54:29.906+0000",
    "status": 500,
    "error": "Internal Server Error",
    "message": "用户不存在",
    "path": "/user",
    "someCode": "attribute add atrribute",
    "ext": {
        "myCode": "custom code",
        "message": "用户不存在"
    }
}
```

错误先关的知识就到这里为止了，我们还得继续往下探索，下面的内容会越来越有意思，他是什么呢？

—— 嵌入式Servlet容器配置修改。
