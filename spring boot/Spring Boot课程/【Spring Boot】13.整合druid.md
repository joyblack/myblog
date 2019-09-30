# 简介
druid和hikari是一样的数据源连接池解决方案，其监控功能比较引入注目，下面把教程的内容贴一下，如果用到的话可以参考。

1. 导入druid数据源
#### pom.xml
``` xml
     <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid</artifactId>
            <version>1.1.12</version>
        </dependency>
```


2. 设置springboot使用的数据源
``` yml
server:
  port: 8086
spring:
  datasource:
    username: root
    password: 123456
    url: jdbc:mysql://10.21.1.47:3306/joyblack?characterEncoding=utf8&serverTimezone=GMT
    driver-class-name: com.mysql.cj.jdbc.Driver
    initialization-mode: always
    sql-script-encoding: utf-8
    schema:
      - classpath:schema.sql
    data:
      - classpath:data.sql
    type: com.alibaba.druid.pool.DruidDataSource
```

3. 配置druid连接属性
#### druid支持的配置
``` yml
    initialSize: 5
    minIdle: 5
    maxActive: 20
    maxWait: 60000
    timeBetweenEvictionRunsMillis: 60000
    minEvictableIdleTimeMillis: 300000
    validationQuery: SELECT 1 FROM DUAL
    testWhileIdle: true
    testOnBorrow: false
    testOnReturn: false
    poolPreparedStatements: true
#   配置监控统计拦截的filters，去掉后监控界面sql无法统计，'wall'用于防火墙  
    filters: stat,wall,log4j
    maxPoolPreparedStatementPerConnectionSize: 20
    useGlobalDataSourceStat: true  
    connectionProperties: druid.stat.mergeSql=true;druid.stat.slowSqlMillis=500
```
将其导入配置文件，目前配置文件如下所示:
#### application.yml
``` yml
server:
  port: 8086
spring:
  datasource:
    username: root
    password: 123456
    url: jdbc:mysql://10.21.1.47:3306/joyblack?characterEncoding=utf8&serverTimezone=GMT
    driver-class-name: com.mysql.cj.jdbc.Driver
    initialization-mode: always
    sql-script-encoding: utf-8
    schema:
      - classpath:schema.sql
    data:
      - classpath:data.sql
    type: com.alibaba.druid.pool.DruidDataSource

    initialSize: 5
    minIdle: 5
    maxActive: 20
    maxWait: 60000
    timeBetweenEvictionRunsMillis: 60000
    minEvictableIdleTimeMillis: 300000
    validationQuery: SELECT 1 FROM DUAL
    testWhileIdle: true
    testOnBorrow: false
    testOnReturn: false
    poolPreparedStatements: true
    #   配置监控统计拦截的filters，去掉后监控界面sql无法统计，'wall'用于防火墙
    filters: stat,wall,logback
    maxPoolPreparedStatementPerConnectionSize: 20
    useGlobalDataSourceStat: true
    connectionProperties: druid.stat.mergeSql=true;druid.stat.slowSqlMillis=500
```
编写配置文件将配置注入数据源配置中以及配置数据库监控等。

#### config/DruidConfig.class
``` java
package com.zhaoyi.jdbcweb.config;

import com.alibaba.druid.pool.DruidDataSource;
import com.alibaba.druid.support.http.StatViewServlet;
import com.alibaba.druid.support.http.WebStatFilter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

@Configuration
public class DruidConfig {
    @ConfigurationProperties(prefix = "spring.datasource")
    @Bean
    public DataSource druid(){
        return new DruidDataSource();
    }

    // 配置Druid的监控
    //1. 配置一个管理后台的Servlet
    @Bean
    public ServletRegistrationBean statViewServlet(){
        // 配置监控访问路径
        ServletRegistrationBean bean = new ServletRegistrationBean(new StatViewServlet(), "/druid/*");
        Map<String,String> initParams = new HashMap<>();

        // 设置监控数据库信息
        initParams.put("loginUsername","user");
        initParams.put("loginPassword","123456");
        //默认允许所有访问
        initParams.put("allow","");
        // 也可以配置禁止访问
        // initParams.put("deny","192.168.102.200");
        bean.setInitParameters(initParams);
        return bean;
    }


    //2. 配置一个web监控的filter
    @Bean
    public FilterRegistrationBean webStatFilter(){
        FilterRegistrationBean bean = new FilterRegistrationBean();
        bean.setFilter(new WebStatFilter());

        Map<String,String> initParams = new HashMap<>();
        initParams.put("exclusions","*.js,*.css,/druid/*");

        bean.setInitParameters(initParams);

        bean.setUrlPatterns(Arrays.asList("/*"));

        return  bean;
    }
}


```
> 如果运行过程中发现有提示注入(spring.datasource)之类的错误，一般是配置`filters: stat,wall,logback`这里所用的是logback，教程里面logback处用的是log4j，但是我们知道springboot默认整合的日志门面是`slf4j+logback`，当然，如果您使用的是另外的组合，当然就得加入log4j的依赖了。

``` xml
 <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.16</version>
            <scope>compile</scope>
 </dependency>
```

运行项目，访问127.0.0.1:8086/druid并登录前面配置的账户和密码(user:123456)即可查看监控信息.
