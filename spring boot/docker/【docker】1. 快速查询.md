
## 进入服务配置
``` shell
docker exec -it 容器名 /bin/bash
```

## 启动MQ插件
``` shell
rabbitmq-plugins enable rabbitmq_shovel rabbitmq_shovel_management
```

## 中国区镜像加速
``` shell
docker pull registry/docker-cn.com/library/xxx
```

