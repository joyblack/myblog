## 查看帮助
```
mysql --help|grep
```
--help获取帮助文档的方式基本大多数linux工具命令都支持。

## 查看服务信息
```
# ps -ef|grep mysqld
```
此方式可以列出大部分服务的配置信息、端口信息等，一般输出如下
```
root      1224     1  0 Sep10 ?        00:00:00 /bin/sh /usr/bin/mysqld_safe --datadir=/var/lib/mysql --pid-file=/var/lib/mysql/DFS242.pid
mysql     1317  1224  0 Sep10 ?        00:02:10 /usr/sbin/mysqld --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib64/mysql/plugin --user=mysql --log-error=/var/lib/mysql/DFS242.err --pid-file=/var/lib/mysql/DFS242.pid --port=3306
root      5897  5879  0 08:10 pts/0    00:00:00 grep --color=auto mysqld
```

## 查看默认配置文件位置
```
mysql --help|grep my.cnf
```

## 进入mysql控制台
```
mysql -u用户名 -p回车
输入密码
```
该方式可由linux的shell转到mysql的控制台，登录成功之后输出如下所示：
```
Your MariaDB connection id is 57
Server version: 10.1.34-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> 
```
此处是使用的是mariadb 10.1.34版本，其实就是mysql比较高的版本了。另外命令行模式下前面的提示信息变为`MariaDB [(none)]> `，如果是低版本的话，则类似`Mysql [(none)]> `，之后的命令如果是`MariaDB [(none)]>`开头的，则都需要登录mysql之后才能够使用。

## 查看数据库所在路径
```
mysql> show variables like 'datadir';\G
```