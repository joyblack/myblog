# 简介
项目开发中经常需要执行一些定时任务，比如需要在每天凌晨时候，分析一次前一天的日志信息。Spring为我们提供了异步执行任务调度的方式，提供TaskExecutor 、TaskScheduler 接口。

> 两个注解：@EnableScheduling、@Scheduled

# cron表达式
cron表达式是定时任务中比较重要的定义字符串，我们需要了解其特点才能更好的使用异步任务。

在springboot中，cron表达式是空格分离的6位时间串，分别对应如下：
```
second, minute, hour, day of month, month and day of week
```
即“秒 分 时 天 月 星期”。

## 字段涵义
|字段|	允许值	|允许的特殊字符
|--|--|--|
|秒	|0-59	|, - * /
|分	|0-59	|, - * /
|小时|	0-23	|, - * /
|日期|	1-31	|, - * ? / L W C
|月份|	1-12	|, - * /
|星期|	0-7或SUN-SAT |0,7是SUN	, - * ? / L C #
||||

## 特殊字符
|特殊字符	|代表含义|
|-|-|
|,|	枚举|
|-|	区间|
|*|	任意|
|/|	步长|
|?|	日/星期冲突匹配|
|L|	最后|
|W|	工作日|
|C|	和calendar联系后计算过的值|
|#|	星期，4#2，第2个星期四|

## 星期缩写的英文单词对照表
||英文|缩写|
|-|-|-|
|星期一| Monday|      Mon
|星期二| Tuesday|       Tues
|星期三| Wednesday| Wed
|星期四| Thursday  |  Thur/Thurs
|星期五| Friday     |    Fri
|星期六| Saturday    |  Sat
|星期日| Sunday       | Sun

> 如果觉得缩写不好记住，也可以使用0-7来表示星期范畴：0和7代表星期日，1-6代表星期一至星期六。

# 使用方式
1. 开启定时任务注解@EnableScheduling
2. 为方法添加定时任务注释@Scheduled

# 测试
我们写一个service方法，让其每秒都打印一个在控制台dingdong字符串:
##### service/HelloService.class
``` java
    @Scheduled(cron = "* * * * * *")
    public void dingDong(){
        System.out.println("ding dong...");
    }
```

> 别忘了在启动类处开启定时任务注解@EnableScheduling.

以下列出一些常用的cron表达式提供参考
``` java
// 任意：每秒执行
@Scheduled(cron = "* * * * * *")
// 星期：周一至周五每分钟执行
@Scheduled(cron = "0 * * * * WED-FRI")
// 枚举：每分钟的0,1,2,3秒执行
@Scheduled(cron = "0,1,2,3 * * * * *")@
// 区间：每分钟的0,1,2,3秒执行
@Scheduled(cron = "0-3 * * * * *")
// 步长：每隔4秒执行一次
@Scheduled(cron = "0/4 * * * * *")
// 每个月的周一至周六12:30执行一次
@Scheduled(cron = "0/4 30 12 ? * 1-6")
// 每个月的最后一周周六凌晨2点执行一次
@Scheduled(cron = "0 0 2 ? * 6L")
// 每个月的最后一个工作日凌晨2点执行一次
@Scheduled(cron = "0 0 2 LW * ?")
// 每个月的第一个周一凌晨2点到4点间，每个整点执行一次
@Scheduled(cron = "0 0 2-4 ? * 1#1")
// 更多的业务需求慢慢完善
```