# 简介
Docker是一个开源的应用容器引擎；是一个轻量级容器技术；

Docker支持将软件编译成一个镜像；然后在镜像中各种软件做好配置，将镜像发布出去，其他使用者可以直接使用这个镜像；

运行中的这个镜像称为容器，容器启动是非常快速的。

# 核心概念
1. docker主机(Host) 安装了Docker程序的机器（Docker直接安装在操作系统之上）。
2. docker客户端(Client) 连接docker主机进行操作。
3. docker仓库(Registry) 用来保存各种打包好的软件镜像；
4. docker镜像(Images) 软件打包好的镜像；放在docker仓库中；
5. docker容器(Container) 镜像启动后的实例称为一个容器；容器是独立运行的一个或一组应用

# 使用Docker的步骤
使用docker的步骤很简单，一般只需：
1. 安装Docker
2. 去Docker仓库找到这个软件对应的镜像；
3. 使用Docker运行这个镜像，这个镜像就会生成一个Docker容器；
4. 对容器的启动停止就是对软件的启动停止；

# 安装Docker
## 安装linux虚拟机
这个相信大家都有自己的虚拟机，这个就不用多加说明了。
## 在linux虚拟机上安装docker
1. 检查内核版本，必须是3.10及以上
``` shell
# uname -r
```
2. 安装docker
``` shell
# yum install docker
```
3. 启动docker
``` shell
# systemctl start docker
# docker -v
```
4. 开机启动docker
``` shell
# systemctl enable docker
```
5. 停止docker
```
# systemctl stop docker
```

# Docker常用命令&操作

## 镜像操作

| 操作 | 命令                                            | 说明                                                     |
| - | ---------------- | ------- |
| 检索 | docker  search 关键字  eg：docker  search redis | 我们经常去docker  hub上检索镜像的详细信息，如镜像的TAG。 |
| 拉取 | docker pull 镜像名:tag                          | :tag是可选的，tag表示标签，多为软件的版本，默认是latest  |
| 列表 | docker images                                   | 查看所有本地镜像                                         |
| 删除 | docker rmi image-id                             | 删除指定的本地镜像                                       |

可前往：[官方网站](https://hub.docker.com/)查看相关信息。

## 容器操作

软件镜像（QQ安装程序）----运行镜像----产生一个容器（正在运行的软件，运行的QQ）；

> 在进行操作的时候，为了方便，先关闭防火墙(centos)systemctl stop firewalld 

步骤：
1. 搜索镜像
``` shell
docker search tomcat
```
2. 拉取镜像
``` shell
docker pull tomcat
```
3. 根据镜像启动容器
``` shell
docker run --name mytomcat -d tomcat:latest
```
4. 查看运行中的容器
``` shell
docker ps
```  
5. 停止运行中的容器
``` shell
docker stop 容器的id
```
6. 查看所有的容器
``` shell
docker ps -a
```
7. 启动容器
``` shell
docker start 容器id
```
8. 删除一个容器
``` shell
docker rm 容器id
```
9. 启动一个做了端口映射的tomcat
``` shell
docker run -d -p 8888:8080 tomcat
```
* -d：后台运行
* -p: 将主机的端口映射到容器的一个端口 *主机端口:容器内部的端口*


```
11. 查看容器的日志
``` shell
docker logs container-name/container-id
```

更多命令参看
[地址](https://docs.docker.com/engine/reference/commandline/docker/
) ，可以参考每一个镜像的文档

# 环境搭建

## 安装tomcat
安装tomcat，并映射主机8080端口
``` shell
# docker pull tomcat
# docker run -d -p 8080:8080 tomcat
```

## 安装Mariadb示例
1. 拉取镜像
```shell
# docker pull mariadb
```
2. 启动mysql
``` shell
# docker run -p --name mysql -e MYSQL_ROOT_PASSWORD=123456 -d mariadb
```
* 不要盲目的直接run，很多容器都是需要携带参数进行启动的，比如mysql（需要至少指定某个参数，例如此处的服务密码），使用的时候请参考该容器对应的官方文档进行操作；
* -p 指定端口映射:宿主机的端口和docker默认端口；
* -e 则是指定容器的某个参数信息，例如此处配置了mariadb的连接密码为123456；

## 安装elasticsearch
1. 拉取镜像
``` shell
# docker pull docker.elastic.co/elasticsearch/elasticsearch:6.5.3
```

2. 运行容器
``` shell
# docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:6.5.3
```

## 安装redis
1. 拉取镜像
``` shell
# docker pull redis
```

2. 运行容器
``` shell
# docker run --name redis -p 6379:6379  -d redis
```

## 安装rabbitmq
1. 拉取并运行容器
``` shell
# docker run -d --hostname my-rabbit --name rabbit -p 15672:15672 -p 5672:5672 rabbitmq:3-management
```
> 登录ipaddress:15672，由于这里没有指定登录账户和密码，则使用默认的guest:guest。

