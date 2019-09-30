# 防火墙配置
1、开放端口
```
firewall-cmd --permanent --add-port=3306/tcp   # MariaDB
firewall-cmd --reload
```

2、查看防火墙，添加的端口也可以看到
```
firewall-cmd --list-all
```

# ssh无秘钥登录配置
```
# ssh-keygen -t rsa
# ssh-copy-id hostname
```