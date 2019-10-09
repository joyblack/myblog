# 简介
在开发中我们修改一个Java文件后想看到效果不得不重启应用，这导致大量时间花费，我们希望不重启应用的情况下，程序可以自动部署（热部署）。有以下四种情况，如何能实现热部署。

## 模板引擎

在Spring Boot中开发情况下禁用模板引擎的cache
页面模板改变ctrl+F9可以重新编译当前页面并生效

## Spring Loaded
Spring官方提供的热部署程序，实现修改类文件的热部署
下载Spring Loaded（项目地址https://github.com/spring-projects/spring-loaded）
添加运行时参数；
-javaagent:C:/springloaded-1.2.5.RELEASE.jar –noverify
## JRebel
收费的一个热部署软件
安装插件使用即可。

## Spring Boot Devtools
这是springboot官方推荐的官方插件
``` xml
<dependency>  
       <groupId>org.springframework.boot</groupId>  
       <artifactId>spring-boot-devtools</artifactId>   
</dependency> 
```
之后修改类文件之后，通过IDEA使用ctrl+F9进行热重启即可。
```
LiveReload server is running on port 35729
```


> 或做一些小调整 Intellij IEDA和Eclipse不同，Eclipse设置了自动编译之后，修改类它会自动编译，而IDEA在非RUN或DEBUG情况下才会自动编译（前提是你已经设置了Auto-Compile）。
设置自动编译（settings-compiler-make project automatically）
ctrl+shift+alt+/（maintenance）
勾选compiler.automake.allow.when.app.running
