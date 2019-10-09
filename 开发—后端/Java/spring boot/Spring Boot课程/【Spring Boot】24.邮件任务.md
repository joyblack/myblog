# 简介
在我们开发过程中，经常可以用到发送邮件的需求，这里我们来学习如何在springboot中集成邮件服务。

在使用邮箱模块之前我们需要了解邮件发送的原理，即用户A和B之间的邮箱传送过程是需要邮件服务器进行中转的，了解这一点之后我们开始邮件服务的集成。

# 集成邮件
1. 引入场景启动器
##### pom.xml
``` xml

```


2. 配置账户信息
##### application.yml
``` yml
spring:
  mail:
    username: 1016037677@qq.com
    password: aaauhkiqvqlpvbecf
    host: smtp.qq.com
```


> auhkiqvqlpvbecfd是授权码，你应该使用自己的账户去设置，从QQ邮箱的账户出配置邮件服务器的时候您都会了解到相关的东西。

> 同样的，可以通过自动配置类以及属性类了解可以配置的属性。

这样，我们就可以准备发送邮件测试了。

# 邮件发送

##  简单消息
我们就直接在controller里面发送邮件。

##### controller/HelloController.class
``` java
    @Autowired
    JavaMailSenderImpl javaMailSender;

    @GetMapping("/send")
    public String send(){
        SimpleMailMessage message = new SimpleMailMessage();
        // email set
        message.setSubject("通知");
        message.setText("这是发送给您的一封邮件");
        // send for
        message.setTo("1016037686@qq.com");
        // who send
        message.setFrom("1016037677@qq.com");
        // send
        javaMailSender.send(message);
        return "send success!";
    }
```

> 这样1016037686@qq.com账户就可以收到1016037677@qq.com账户发送的邮件信息了。如果您运行过程中发生了错误，可以尝试开启QQ安全连接设置:
``` yml
spring:
  mail:
    username: 1016037677@qq.com
    password: uauhkiqvqlpvbecf
    host: smtp.qq.com
    properties:
      smtp:
        ssl:
          enable: true
```

## 复杂消息邮件
``` java
@GetMapping("/send2")
    public String send2() throws MessagingException, IOException {
        MimeMessage message = javaMailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true);


        // email set
        helper.setSubject("通知");
        helper.setText("这是发送给您的一封邮件,请<span style='color:red'>圣诞节查收</span>.", true);

        // 添加附件：先放置自己的文件在项目中
        helper.addAttachment("1.jpg", new ClassPathResource("static/1.jpg").getFile());
        // send for
        helper.setTo("1016037686@qq.com");
        // who send
        helper.setFrom("1016037677@qq.com");
        // send
        javaMailSender.send(message);
        return "send success!";
    }

```
注意：

1. 我们使用MimeMessage作为被包装对象，MimeMessageHelper包装复杂类型邮件的发送；
2. MimeMessageHelper的第二个参数用于指定是否包含多附件；
3. setText的第二个参数用于标志是否是html代码，这可以保证你的邮件内容遵循html解析。


