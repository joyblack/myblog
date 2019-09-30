# 简介
安全是我们开发中一直需要考虑的问题，例如做身份认证、权限限制等等。市面上比较常见的安全框架有：
* shiro
* spring security

shiro比较简单，容易上手。而spring security功能比较强大，但是也比较难以掌握。springboot集成了spring security，我们这次来学习spring security的使用。

# spring security
应用程序的两个主要区域是“认证”和“授权”（或者访问控制）。这两个主要区域是Spring Security 的两个目标。

- “认证”（Authentication），是建立一个他声明的主体的过程（一个“主体”一般是指用户，设备或一些可以在你的应用程序中执行动作的其他系统）。

- “授权”（Authorization）指确定一个主体是否允许在你的应用程序执行一个动作的过程。为了抵达需要授权的店，主体的身份已经有认证过程建立。

> 这个概念是通用的而不只在Spring Security中。


Spring Security是针对Spring项目的安全框架，也是Spring Boot底层安全模块默认的技术选型。他可以实现强大的web安全控制。对于安全控制，我们仅需引入spring-boot-starter-security模块，进行少量的配置，即可实现强大的安全管理。需要注意几个类：
* WebSecurityConfigurerAdapter：自定义Security策略
* AuthenticationManagerBuilder：自定义认证策略
* @EnableWebSecurity：开启WebSecurity模式

# 测试使用
## 搭建基本测试环境
1. 引入thymeleaf和security场景启动器
``` xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
        </dependency>
```

2. 编写几个简单的html页面，我们将其分别放在不同的模板文件夹子目录user,admin以及super中，预备给我们的3种不同的角色访问适用。
```
++template
----index.html
++++user
------user1.html
------user2.html
------user3.html
++++admin
------admin1.html
------admin2.html
------admin3.html
++++super
------super1.html
------super2.html
------super3.html
```
每个html都写一点简单的内容，类似于this is xxxx.html。例如admin/admin3.html的内容如下：
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>admin-3</title>
</head>
<body>
this is admin-3 file.
</body>
</html>
```

> 为了方便查看，你也可以将title标签体内容修改为一致的名称，如admin-3

3. 编写controller，对我们的访问路径进行映射：
``` java
package com.example.dweb.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class IndexController {
    @GetMapping("/")
    public String user1(){
        return "/index";
    }

    @GetMapping("/user/user1")
    public String user1(){
        return "/user/user1";
    }
    @GetMapping("/user/user2")
    public String user2(){
        return "/user/user2";
    }
    @GetMapping("/user/user3")
    public String user3(){
        return "/user/user3";
    }


    @GetMapping("/admin/admin1")
    public String admin1(){
        return "/admin/admin1";
    }
    @GetMapping("/admin/admin2")
    public String admin2(){
        return "/admin/admin2";
    }
    @GetMapping("/admin/admin3")
    public String admin3(){
        return "/admin/admin3";
    }


    @GetMapping("/super/super1")
    public String super1(){
        return "/super/super1";
    }
    @GetMapping("/super/super2")
    public String super2(){
        return "/super/super2";
    }
    @GetMapping("/super/super3")
    public String super3(){
        return "/super/super3";
    }
}

```
4. 运行项目，测试我们对各个页面的访问是否正常。在运行项目之前，先在pom文件中将spring-security场景启动器删除，避免security对我们进行访问拦截：
``` xml
    <!--<dependency>-->
        <!--<groupId>org.springframework.boot</groupId>-->
        <!--<artifactId>spring-boot-starter-security</artifactId>-->
    <!--</dependency>
```
> 默认情况下，springsecurity会生成登录页面要求用户进行登录，默认用户名为user，密码为启动项目时控制台info级别打印出的一串uuid，可查看源码了解`String password = UUID.randomUUID().toString()`。

# 安全配置编写
配置编写过程可以参考官方网站文档：[前往](https://docs.spring.io/spring-boot/docs/2.1.1.RELEASE/reference/htmlsingle/#boot-features-security-mvc)，以及springsecurity的官方文档：[前往](https://docs.spring.io/spring-security/site/docs/5.2.0.BUILD-SNAPSHOT/reference/htmlsingle/)；

> 注意版本号，这里是2.1.x版本的适用文档。

1. 停止项目，将我们之前注释掉的springsecutiry场景启动器源码还原.
```xml
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
```

2. 编写配置类config/MySecurityConfig控制请求的访问权限
``` java
package com.example.dweb.config;

import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

@EnableWebSecurity
public class MySecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
       // super.configure(http);
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/user/**").hasAnyRole("user","admin","super")
                .antMatchers("/admin/**").hasAnyRole("admin","super")
                .antMatchers("/super/**").hasRole("super");
    }
}

```
可以看到，我们定制了如下的访问规则：
* 对于首页，允许任何人访问
* /user/** 这样的请求，只有角色为user、admin以及super的人才能访问；
* /admin/** 这样的请求，角色类型为admin和super的可以访问
* /super/** 这样的请求，角色类型为super的可以访问

> 假设认证用户只有这三种角色类型的话，那么super拥有最高的访问权限，admin次之，而user最小。

> 别忘了为该配置类添加@EnableWebSecurity注解.
接下来我们启动项目，访问/可以正常访问，但是我们访问/user/user1等之后会报错：
```
...
There was an unexpected error (type=Forbidden, status=403).
Access Denied
```
权限禁止，达成了我们的目的。

## 登录
1. 接下来我们通过用户登录，来实现对不同角色的访问限制。我们前面注释掉了`super.configure(http);`这样的代码，这里是默认的安全配置，其中就指定了默认的登录界面。我们可以自己来开启自动配置的登录功能（`http.formLogin();`）。看其源码:
``` java
/**
	 * Specifies to support form based authentication. If
	 * {@link FormLoginConfigurer#loginPage(String)} is not specified a default login page
	 * will be generated.
	 *
	 * <h2>Example Configurations</h2>
	 *
	 * The most basic configuration defaults to automatically generating a login page at
	 * the URL "/login", redirecting to "/login?error" for authentication failure. The
	 * details of the login page can be found on
	 * {@link FormLoginConfigurer#loginPage(String)}
	 *
	 * <pre>
	 * &#064;Configuration
	 * &#064;EnableWebSecurity
	 * public class FormLoginSecurityConfig extends WebSecurityConfigurerAdapter {
	 *
	 * 	&#064;Override
	 * 	protected void configure(HttpSecurity http) throws Exception {
	 * 		http.authorizeRequests().antMatchers(&quot;/**&quot;).hasRole(&quot;USER&quot;).and().formLogin();
	 * 	}
	 *
	 * 	&#064;Override
	 * 	protected void configure(AuthenticationManagerBuilder auth) throws Exception {
	 * 		auth.inMemoryAuthentication().withUser(&quot;user&quot;).password(&quot;password&quot;).roles(&quot;USER&quot;);
	 * 	}
	 * }
	 * </pre>
	 *
	 * The configuration below demonstrates customizing the defaults.
	 *
	 * <pre>
	 * &#064;Configuration
	 * &#064;EnableWebSecurity
	 * public class FormLoginSecurityConfig extends WebSecurityConfigurerAdapter {
	 *
	 * 	&#064;Override
	 * 	protected void configure(HttpSecurity http) throws Exception {
	 * 		http.authorizeRequests().antMatchers(&quot;/**&quot;).hasRole(&quot;USER&quot;).and().formLogin()
	 * 				.usernameParameter(&quot;username&quot;) // default is username
	 * 				.passwordParameter(&quot;password&quot;) // default is password
	 * 				.loginPage(&quot;/authentication/login&quot;) // default is /login with an HTTP get
	 * 				.failureUrl(&quot;/authentication/login?failed&quot;) // default is /login?error
	 * 				.loginProcessingUrl(&quot;/authentication/login/process&quot;); // default is /login
	 * 																		// with an HTTP
	 * 																		// post
	 * 	}
	 *
	 * 	&#064;Override
	 * 	protected void configure(AuthenticationManagerBuilder auth) throws Exception {
	 * 		auth.inMemoryAuthentication().withUser(&quot;user&quot;).password(&quot;password&quot;).roles(&quot;USER&quot;);
	 * 	}
	 * }
	 * </pre>
	 *
	 * @see FormLoginConfigurer#loginPage(String)
	 *
	 * @return the {@link FormLoginConfigurer} for further customizations
	 * @throws Exception
	 */
	public FormLoginConfigurer<HttpSecurity> formLogin() throws Exception {
		return getOrApply(new FormLoginConfigurer<>());
	}
```
注释已经说明了一切，我们可以总结一下：
* /login 请求可以来到登录页面;
* 若登录错误，会重定向到login?error;
* 其他的我们可以根据自己的需求查询，还算是比较全面的；

2. 现在我们的配置类如下所示:
``` java
       // super.configure(http);
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/user/**").hasAnyRole("user","admin","super")
                .antMatchers("/admin/**").hasAnyRole("admin","super")
                .antMatchers("/super/**").hasRole("super");

        // open auto login
        http.formLogin();
```

3. 启动项目，再次访问受限的页面如/user/user1，这一次，系统将会将页面定向到登录页面了。现在系统提供的只是一个位于内存中默认用户名为user，密码为一串随即UUID的账户。显然这对于实际开发没有什么意义，因此我们一般是连接数据库等进行用户数据对比的。

接下来，我们可以自定义用户的认证过程，但为了演示方便，我们就使用内存账户进行认证了。

4. 要定制自定义用户认证过程
``` java
package com.example.dweb.config;

import org.springframework.context.annotation.Bean;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@EnableWebSecurity
public class MySecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
       // super.configure(http);
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/user/**").hasAnyRole("user","admin","super")
                .antMatchers("/admin/**").hasAnyRole("admin","super")
                .antMatchers("/super/**").hasRole("super");

        // open auto login
        http.formLogin();
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
//        super.configure(auth);
        String password = "123456";
        auth.inMemoryAuthentication()
                .withUser("user").password(password).roles("user")
                .and()
                .withUser("admin").password(password).roles("admin")
                .and()
                .withUser("super").password(password).roles("super");

    }

    // use my password encoder, it like original password.
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new PasswordEncoder() {
            @Override
            public String encode(CharSequence rawPassword) {
                return rawPassword.toString();
            }

            @Override
            public boolean matches(CharSequence rawPassword, String encodedPassword) {
                return encodedPassword.equals(rawPassword);
            }
        };
    }

}

```

我们定义了3个账户，其用户名和角色名一致，密码都为123456.

启动项目，我们试试测试效果。

可以看到，访问结果和我们预期的一样。
* 若登录用户是user，则只能访问`/user/**`
* 若登录用户是admin，则能访问`/admin/**`以及`/user/**`;
* 若登录账户是super，则能访问所有页面；

如果你使用的是高版本（5.X）的spring security 可能会遇到`java.lang.IllegalArgumentException: There is no PasswordEncoder mapped for the id "null"`这样的错误，解决方案就是使用密码编码器，即PasswordEncorder实例，因此，我们需要在此处提供PasswordEncorder类型的bean passwordEncorder，spring security提供了不少实例供我们使用，可以自己去查看，例如`BCryptPasswordEncoder`等等，不过要注意有不少已经标注了`@Deprecated`，比如`LdapShaPasswordEncoder`、`StandardPasswordEncoder`，使用之前参考一下源代码好些。我这里为了偷懒，自己用了一个明文验证的PasswordEncoder。

NoOpPasswordEncoder也是一个spring security 提供的PasswordEncorder，但是请注意，他已经被标注`@Deprecated`，即不推荐使用的注解。所以如果需要明文验证，自己定义一个PasswordEncoder的bean就可以了。

## 注销
注销和登录一样，我们需要先卡其自动配置的注销功能：
``` java
    @Override
    protected void configure(HttpSecurity http) throws Exception {
       // super.configure(http);
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/user/**").hasAnyRole("user","admin","super")
                .antMatchers("/admin/**").hasAnyRole("admin","super")
                .antMatchers("/super/**").hasRole("super");

        // open auto login function.
        http.formLogin();
        // open auto logout function.
        http.logout();
    }
```

查看该方法的源码：
``` java

	/**
	 * Provides logout support. This is automatically applied when using
	 * {@link WebSecurityConfigurerAdapter}. The default is that accessing the URL
	 * "/logout" will log the user out by invalidating the HTTP Session, cleaning up any
	 * {@link #rememberMe()} authentication that was configured, clearing the
	 * {@link SecurityContextHolder}, and then redirect to "/login?success".
	 *
	 * <h2>Example Custom Configuration</h2>
	 *
	 * The following customization to log out when the URL "/custom-logout" is invoked.
	 * Log out will remove the cookie named "remove", not invalidate the HttpSession,
	 * clear the SecurityContextHolder, and upon completion redirect to "/logout-success".
	 *
	 * <pre>
	 * &#064;Configuration
	 * &#064;EnableWebSecurity
	 * public class LogoutSecurityConfig extends WebSecurityConfigurerAdapter {
	 *
	 * 	&#064;Override
	 * 	protected void configure(HttpSecurity http) throws Exception {
	 * 		http.authorizeRequests().antMatchers(&quot;/**&quot;).hasRole(&quot;USER&quot;).and().formLogin()
	 * 				.and()
	 * 				// sample logout customization
	 * 				.logout().deleteCookies(&quot;remove&quot;).invalidateHttpSession(false)
	 * 				.logoutUrl(&quot;/custom-logout&quot;).logoutSuccessUrl(&quot;/logout-success&quot;);
	 * 	}
	 *
	 * 	&#064;Override
	 * 	protected void configure(AuthenticationManagerBuilder auth) throws Exception {
	 * 		auth.inMemoryAuthentication().withUser(&quot;user&quot;).password(&quot;password&quot;).roles(&quot;USER&quot;);
	 * 	}
	 * }
	 * </pre>
	 *
	 * @return the {@link LogoutConfigurer} for further customizations
	 * @throws Exception
	 */
	public LogoutConfigurer<HttpSecurity> logout() throws Exception {
		return getOrApply(new LogoutConfigurer<>());
	}
```
非常详细，我们大致可以了解到：
1. 访问/logout会清空session以及所有的认证信息。
2. 注销成功后会跳转到页面/login?success

我们给首页添加一个退出按钮：

``` html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>index</title>
</head>
<body>
this is index file.

<form th:action="@{/logout}" method="post">
<input type="submit" value="注销" />
</form>
</body>
</html>
```

运行项目之后我们登录之后进入首页，点击退出按钮，发现来到了登录界面。

这是默认的，我们也可以定制退出页面的位置，只需如下设置即可。
``` java
http.logout().logoutSuccessUrl("/");
```

> 点击注销感觉还是没反应（其实是刷新了一下），因为当前页面和退出页面是一样的。

# thymeleaf整合安全模块
我们有时候有很多需求需要和用户的角色绑定，例如管理员会显示一些多余的菜单等等，有一种解决方案就是通过thymeleaf和spring security的整合模块来完成。

``` xml
<dependency>
            <groupId>org.thymeleaf.extras</groupId>
            <artifactId>thymeleaf-extras-springsecurity5</artifactId>
            <version>3.0.4.RELEASE</version>
        </dependency>
```

官方文档可以查看地址：[文档](https://github.com/thymeleaf/thymeleaf-extras-springsecurity)

现在我们来完善一下之前的注销按钮的问题，他应该出现在已登录账户的页面才是，而不应该出现在未登录的用户的首页。

``` html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head>
    <meta charset="UTF-8">
    <title>index</title>
</head>
<body>
<div sec:authorize="isAuthenticated()">
    <h1><span sec:authentication="name"></span>，您好，您的角色是<span sec:authentication="principal.authorities"></span></h1>
    <form th:action="@{/logout}" method="post">
        <input type="submit" value="注销" />
    </form>
</div>
<hr>
<div sec:authorize="!isAuthenticated()">
    你好，您当前未登录，请预先<a th:href="@{/login}">登录</a>
</div>

<hr>
this is index file.

</body>
</html>
```

> 注意sec:authorize以及sec:authentication的区别。

其实该插件基本都是操作一些内置对象，例如`authentication`等的，因此，有的地方也可以用thymeleaf的基础语法直接访问。
例如以下两端代码输出是一样的：
``` html
<h1 th:text="${#authentication.getName()}"></h1>
<h1 sec:authentication="name"></h1>
```
# 记住我
记住我功能也是比较常用的登录便利条款，开启记住我只需这样配置：
``` java
http.rememberMe();
```

现在我们的配置类如下所示:
``` java
package com.example.dweb.config;

import org.springframework.context.annotation.Bean;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@EnableWebSecurity
public class MySecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
       // super.configure(http);
        http.authorizeRequests().antMatchers("/").permitAll()
                .antMatchers("/user/**").hasAnyRole("user","admin","super")
                .antMatchers("/admin/**").hasAnyRole("admin","super")
                .antMatchers("/super/**").hasRole("super");

        // open auto login function.
        http.formLogin();
        // open auto logout function.
        http.logout().logoutSuccessUrl("/");
        // open remember me function.
        http.rememberMe();
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
//        super.configure(auth);
        String password = "123456";
        auth.inMemoryAuthentication()
                .withUser("user").password(password).roles("user")
                .and()
                .withUser("admin").password(password).roles("admin")
                .and()
                .withUser("super").password(password).roles("super");

    }

    // use my password encoder, it like original password.
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new PasswordEncoder() {
            @Override
            public String encode(CharSequence rawPassword) {
                return rawPassword.toString();
            }

            @Override
            public boolean matches(CharSequence rawPassword, String encodedPassword) {
                return encodedPassword.equals(rawPassword);
            }
        };
    }

}

```

重启项目之后来到登录页面，会发现自动为我们添加了带有文本`Remember me on this computer`的复选框按钮，通过勾选该按钮之后登录，即便我们关掉浏览器，访问我们的网站的时候就无需再次登录了，相当于记住了我们的认证信息。

我们来探究一下其实现原理：
打开浏览器的控制台（我使用的是google），找到application选项卡的Cookies菜单栏，会发现里面有两个数据
* JSESSIONID
* remember-me

有效时间14天左右，浏览器通过remember-me和服务器进行交互，检查之后就无需登录了。

当我们点击注销按钮，则会删除这个Cookie。

# 定制登陆页
正常情况下我们肯定是不能依靠springboot为我们提供的login页面的，需要自己定制，定制方式也很简单，在开启登录功能的地方定制即可。
``` java
    // open auto login function.
    http.formLogin().loginPage("/login");
```

在模板目录下放置一个登录界面:
``` html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head>
    <meta charset="UTF-8">
    <title>index</title>
</head>
<body>
<form method="post" action="@{/userLogin}">
    <input type="text" name="username" value="user"/>
    <input type="text" name="password" value="123456"/>
    <input type="submit" value="login">
</form>

</body>
</html>
```

IndexController中添加对login的映射:
``` java
@GetMapping("/login")
public String login(){
    return "/login";
}
```

默认情况下post形式的/login代表处理登录，默认证字段就是username和password，当然，你也可以修改
``` java
// open auto login function.
http.formLogin().loginPage("/login").usernameParameter("username").passwordParameter("password");
```

留意loginPage的源码注释部分：
``` java
	 * If "/authenticate" was passed to this method it update the defaults as shown below:
	 *
	 * <ul>
	 * <li>/authenticate GET - the login form</li>
	 * <li>/authenticate POST - process the credentials and if valid authenticate the user
	 * </li>
	 * <li>/authenticate?error GET - redirect here for failed authentication attempts</li>
	 * <li>/authenticate?logout GET - redirect here after successfully logging out</li>
	 * </ul>
```

也就说，一旦我们定制了登录页面，那么其他的规则也会受到影响，大致就是
* /page Get 处理前往登录页面
* /page post 处理登录请求
* /page?success GET 登陆成功请求
* /page?error GET 登陆失败请求

当然，我们也可以修改处理登录页面的地址:
``` java
        http.formLogin().loginPage("/login").usernameParameter("username").passwordParameter("password").loginProcessingUrl("/login");
```

注意是post方式。

同样的，rememberme也支持自定义配置。
``` java
 // open remember me function.
http.rememberMe().rememberMeParameter("remember-me");
```

name我们设置为默认的就好，这样就无需配置了，查看源码可以知道默认是什么：
``` java
private static final String DEFAULT_REMEMBER_ME_NAME = "remember-me";
```

这样，我们在登陆页面添加rememberme按钮
``` html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head>
    <meta charset="UTF-8">
    <title>index</title>
</head>
<body>
<form method="post" th:action="@{/login}">
    <input type="text" name="username" value="user"/>
    <input type="text" name="password" value="123456"/>
    <input th:type="checkbox" name="remember-me"> 记住我
    <input type="submit" value="login">
</form>

</body>
</html>
```

然后测试其效果，应该和默认的登录界面是一模一样的。




