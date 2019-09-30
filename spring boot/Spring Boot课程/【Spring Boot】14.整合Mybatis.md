# 简介
MyBatis前身是apache的一个开源项目iBatis，2010年这个项目由apache software foundation 迁移到了google code，并且改名为MyBatis2013年11月迁移到Github。

他是一个支持普通SQL查询，存储过程和高级映射的优秀持久层框架。他消除了几乎所有的JDBC代码和参数的手工设置以及对结果集的检索封装，支持简单的XML或注解用于配置和原始映射，将接口和Java的POJO（Plain Old Java Objects，普通的Java对象）映射成数据库中的记录。

这一节，我们将学习如何将mybatis整合到我们的项目中，辅助数据库操作。

# 演示项目
## 创建项目
同样采用SpringInitializer创建项目，选择如下模块：
* web 作为web启动
* MySQL 作为数据库驱动
* JDBC 为我们自动配置数据源(可不选择，mybatis会依赖)
* MyBatis 数据访问框架

引入mybatis只需引入依赖
##### pom.xml
``` xml
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>1.3.2</version>
        </dependency>
```
> 从其`artifactId`我们可以了解到，这不是官方包。

## 配置基本环境信息
我们按整合*jdbc与数据源*那一章节配置的方式将基础环境配置好。
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
      - classpath:sql/joyblack.sql
```

然后倒入我们创建数据库以及倒入数据的sql文件，为了偷懒，我们统一将其放在schema逻辑中。该脚本创建了两张表user以及department，分别代表用户信息以及用户所在的部门信息，并导入了3个冒险者用户以及2个工会部门。

#### sql/joyblack.sql
``` sql
/*
Navicat MySQL Data Transfer

Source Server         : docker
Source Server Version : 50505
Source Host           : 10.21.1.47:3306
Source Database       : joyblack

Target Server Type    : MYSQL
Target Server Version : 50505
File Encoding         : 65001

Date: 2018-12-20 09:45:44
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `department`
-- ----------------------------
DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
  `id` int(11) NOT NULL,
  `department_name` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of department
-- ----------------------------
INSERT INTO `department` VALUES ('1', '乡下冒险者公会');
INSERT INTO `department` VALUES ('2', '城市冒险者公会');

-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `login_name` varchar(20) NOT NULL,
  `deparment_id` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of user
-- ----------------------------
INSERT INTO `user` VALUES ('1', '阿库娅', 'akuya', '1');
INSERT INTO `user` VALUES ('2', '克里斯汀娜', 'crustina', '1');
INSERT INTO `user` VALUES ('3', '惠惠', 'huihui', '1');
```

我们接下来跑一下应用程序，初始化数据库信息。为了运行快速一点，之后我们应该把配置文件中的` schema:- classpath:sql/joyblack.sql`给注释掉，下次就不要在初始化了。

## 创建实体Bean
接下来我们创建对应的Bean，关联数据库表实体。
#### bean/User.class
``` java
package com.zhaoyi.mbweb.bean;

public class User {
    private Integer id;
    private String loginName;
    private String userName;
    private Integer departmentId;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getLoginName() {
        return loginName;
    }

    public void setLoginName(String loginName) {
        this.loginName = loginName;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Integer getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Integer departmentId) {
        this.departmentId = departmentId;
    }
}


```

#### bean/Department.class
``` java
package com.zhaoyi.mbweb.bean;

public class Department {
    private Integer id;
    private String departmentName;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }
}

```
准备工作完成了，我们可以准备使用mybatis了。

接下来我们就可以使用mybatis提供的便利操作数据库了，不过也有不同的操作方式，我们先一个一个的来。

# 使用mybatis：基于注解的方式
基于注解的方式无需指明任何配置，直接编写相关的注解语句即可，我们只专注自己的Mapper就可以了。

接下来我们测试一下怎么使用基于注解的方式操作数据库。我们新建一个Mapper接口，里面包括了基本的增删查改操作：

#### mapper/DepartMentMapper.class
``` java
package com.zhaoyi.mbweb.mapper;

import com.zhaoyi.mbweb.bean.Department;
import org.apache.ibatis.annotations.*;

@Mapper
public interface DepartmentMapper {

    // insert a derpartment.
    // @Options(useGeneratedKeys = true, keyProperty = "id") may you want get insert data generated id.
    @Insert("insert into department(id,department_name) values(#{id}, #{departmentName})")
    int insertDepartment(Department department);

    // delete a department by id.
    @Insert("delete from department where id = #{id}")
    int deleteDepartment(Integer id);

    // query a department by id.
    @Select("select * from department where id = #{id}")
    Department getDepartmentById(Integer id);

    // update a department information.
    @Update("update department set department_name=#{departmentName} where id=#{id}")
    int updateDepartment(Department department);
}
```

其中：
* `@Mapper` 指定这是一个操作数据库的Mapper；
* 如果你的表是自增类型的，想要获得返回id的信息，可以在插入语句上方加入注解`@Options(useGeneratedKeys = true, keyProperty = "id")`，这样，在插入后mybatis就会自动的将id属性回写到你的插入对象中了；
* 可以通过`#{xxx}`语法提取参数中传递的值；


然后，编写一个controller来测试这些操作，为了方便，我们就只测试查询和插入操作即可：
#### controller/DepartmentController.class
``` java
package com.zhaoyi.mbweb.controller;

import com.zhaoyi.mbweb.bean.Department;
import com.zhaoyi.mbweb.mapper.DepartmentMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class DepartmentController {
    @Autowired
    private DepartmentMapper departmentMapper;

    @GetMapping("/department/{id}")
    public Department getDepartment(@PathVariable("id") Integer id){
        return  departmentMapper.getDepartmentById(id);
    }

    @GetMapping("/department")
    public Department insertDepartment(Department department){
        departmentMapper.insertDepartment(department);
        return department;
    }

}

```
其中：
* `getDepartment`映射`/department/{id}`的请求，用于处理查询某个id的部门信息，id写在路径参数中；
* `insertDepartment`映射`/department?xxx=xxx`的请求，用于插入get传递的参数中指定的部门信息；


一切完毕，运行项目后，我们分别测试两个操作的结果：

1. 访问: `http://localhost:8086/department/2`，我们可以得到以下的输出：
``` json
{"id":2,"departmentName":null}
```
2. 访问：`http://localhost:8086/department?id=3&name=广州冒险者公会`，我们得到以下的输出:
``` json
{"id":3,"departmentName":"广州冒险者公会"}
```
并可以在数据库中看到该条数据。这就是基于注解的方式来使用mybatis操作数据库。

## 开启驼峰映射规则
细心的朋友应该会发现，查询的部门信息的时候返回的数据的`departmentName`的值为空。这显然是不对的，我们可以留意到在数据库中我们的命名方式是下划线的department_name，而bean中则是departmentName。这就需要我们开启驼峰映射规则，来提醒mybatis将数据库的下划线字段和bean的驼峰变量关联起来。

如何修改呢？


我们观察mybatis的自动配置类
``` java
@EnableConfigurationProperties({MybatisProperties.class})
@AutoConfigureAfter({DataSourceAutoConfiguration.class})
public class MybatisAutoConfiguration {
    ...
    
    @Bean
    @ConditionalOnMissingBean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean factory = new SqlSessionFactoryBean();
        factory.setDataSource(dataSource);
        factory.setVfs(SpringBootVFS.class);
        if (StringUtils.hasText(this.properties.getConfigLocation())) {
            factory.setConfigLocation(this.resourceLoader.getResource(this.properties.getConfigLocation()));
        }

        org.apache.ibatis.session.Configuration configuration = this.properties.getConfiguration();
        if (configuration == null && !StringUtils.hasText(this.properties.getConfigLocation())) {
            configuration = new org.apache.ibatis.session.Configuration();
        }

        // 从这里可以知道可以通过配置ConfigurationCustomizer来操作mybatis的配置
        if (configuration != null && !CollectionUtils.isEmpty(this.configurationCustomizers)) {
            Iterator var4 = this.configurationCustomizers.iterator();

            while(var4.hasNext()) {
                ConfigurationCustomizer customizer = (ConfigurationCustomizer)var4.next();
                customizer.customize(configuration);
            }
        }

        factory.setConfiguration(configuration);
        if (this.properties.getConfigurationProperties() != null) {
            factory.setConfigurationProperties(this.properties.getConfigurationProperties());
        }

        if (!ObjectUtils.isEmpty(this.interceptors)) {
            factory.setPlugins(this.interceptors);
        }

        if (this.databaseIdProvider != null) {
            factory.setDatabaseIdProvider(this.databaseIdProvider);
        }

        if (StringUtils.hasLength(this.properties.getTypeAliasesPackage())) {
            factory.setTypeAliasesPackage(this.properties.getTypeAliasesPackage());
        }

        if (StringUtils.hasLength(this.properties.getTypeHandlersPackage())) {
            factory.setTypeHandlersPackage(this.properties.getTypeHandlersPackage());
        }

        if (!ObjectUtils.isEmpty(this.properties.resolveMapperLocations())) {
            factory.setMapperLocations(this.properties.resolveMapperLocations());
        }

        return factory.getObject();
    }
    ...
}
```
可以发现，我们可以通过增加`ConfigurationCustomizer`类型的Bean，就可以修改mybatis的配置信息了。添加配置：

#### config/MyBatisConfig.class
``` java
package com.zhaoyi.mbweb.config;


import org.apache.ibatis.session.Configuration;
import org.mybatis.spring.boot.autoconfigure.ConfigurationCustomizer;
import org.springframework.context.annotation.Bean;

@org.springframework.context.annotation.Configuration
public class MyBatisConfig {

    @Bean
    public ConfigurationCustomizer configurationCustomizer(){
        return new ConfigurationCustomizer(){
            @Override
            public void customize(Configuration configuration) {
                // 开启驼峰映射规则
                configuration.setMapUnderscoreToCamelCase(true);
            }
        };
    }
}
```
接下来，我们重启项目，就可以发现，可以正常的获得部门信息了，继续访问刚才的地址`http://localhost:8086/department/2`，获取id为2的部门信息：
``` json
{"id":2,"departmentName":"城市冒险者公会"}
```

## 批量扫描Mapper接口
通过前面的介绍，我们需要留意一点，就是编写Mapper的时候要为其添加`@Mapper`注解，这样才能让mybatis识别这些mapper。但是在实际的开发过程中，Mapper肯定是一个不少的量的，至少，为了简洁考虑，您需要为每个数据表映射一个Mapper，有没有一种一劳永逸的方法呢？

有！

我们只需在MyBaticConfig加上扫描注解或者SpringBoot的启动类上添加`@MapperScan(value="your mapper packagePath")`，例如，我们可以在上面的mybatis配置类这样写：
#### config/MybatisConfig.class
``` java
// batch scan all mapper class.
@MapperScan(value = "com.zhaoyi.mbweb.mapper")
@org.springframework.context.annotation.Configuration
public class MyBatisConfig {
```

> `com.zhaoyi.mbweb.mapper` 是我的mapper所在的包名，请按您自己的包名进行填写。

# 使用mybatis：基于配置的方式
更多信息请参考: [官方文档](http://www.mybatis.org/mybatis-3/index.html)

前面我们使用了基于注解的方式对数据库进行了操作，现在，我们试试另外一种方式，通过配置文件的方式来使用mybatis操作数据库。为了方便，我们接下来的这种方式就来操作user表进行演示即可。


## 编写Mapper
首先，编写一个user的mapper
#### mapper/UserMapper.class
``` java
package com.zhaoyi.mbweb.mapper;

import com.zhaoyi.mbweb.bean.User;

public interface UserMapper {

    int insertUser(User user);

    int deleteUser(Integer id);

    User getUserById(Integer id);

    int updateUser(User user);
}
```
和之前的`DepartmentMapper`不同的是，我们这里并没有添加注解，因为，我们将会把他们写在对应的mybatis SQL映射文件中。

## 设置应用程序全局配置文件
接下来我们要指定Mybatis配置文件以及Mybatis SQL映射文件的路径，在配置文件中添加如下配置
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
    #schema:
    # - classpath:sql/joyblack.sql
mybatis:
  # mybatis配置文件
  config-location: classpath:mybatis/mybatis-config.xml
  # SQL映射文件路径，查看源码他是一个String数组，不过我们直接配置"*"通配符即可，代表所有的xml文件
  mapper-locations: classpath:mybatis/mapper/*.xml
```
## 配置Mybatis配置文件
在资源文件夹下创建mybatis文件夹，并放入mybatis-config.xml（和全局配置指定的路径一致）配置文件
#### resources/mybatis/mybatis-config.xml
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    <settings>
       <setting name="mapUnderscoreToCamelCase" value="true" />
    </settings>
</configuration>
```
里面配置一些相关配置，例如数据库连接信息等，但这些我们已经在数据源配置了，这里就无需配置。

如果我们没有在mybatis的主配置文件中配置`mapUnderscoreToCamelCase`，这时候我们去查询*部门*相关的信息，发现名字又为空了。因为当使用配置文件之后，我们的自定义配置中设置的驼峰式映射逻辑已经被配置文件的默认配置覆盖掉了。因此，我们需要在配置文件中指定驼峰时映射规则：
#### resources/mybatis/mybatis-config.xml
``` xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    <settings>
       <setting name="mapUnderscoreToCamelCase" value="true" />
    </settings>
</configuration>
```
可以发现，配置项`mapUnderscoreToCamelCase`和我们使用配置文件的属性名是一模一样的。

> 从这里可以看出，两种方式混用也是可以的，但是问题很明显，配置会冲突。所以大家在开发的时候最好还是选择其中一种方式，从始至终进行，避免管理上的复杂以及逻辑的混乱。


## 配置Mybatis SQL映射文件
对应配置文件创建一个mapper文件夹，用于放我们的SQL映射文件，在这里我们创建一个UserMapper.xml即可.

#### resources/mybatis/mapper/UserMapper.xml
``` xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.zhaoyi.mbweb.mapper.UserMapper">
    <!--     int insertUser(User user);

    int deleteUser(Integer id);

    User getUserById(Integer id);

    int updateUser(User user);-->
    <insert id="insertUser">
        insert into user(id, login_name, user_name, department_id) values (#{id}, #{loginName}, #{userName}, #{departmentId})
    </insert>

    <delete id="deleteUser">
        delete from user where id = #{id}
    </delete>

    <select id="getUserById" resultType="com.zhaoyi.mbweb.bean.User">
        select * from user where id = #{id}
    </select>

    <update id="updateUser">
        update user set user_name = #{userName} where id = #{id}
    </update>
</mapper>
```

接下来就是编写controller测试curd4个操作了。

#### controller/UserController.class
``` java
package com.zhaoyi.mbweb.controller;

import com.zhaoyi.mbweb.bean.User;
import com.zhaoyi.mbweb.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @Autowired
    private UserMapper userMapper;

    @RequestMapping("/user/insert")
    public User insertUser(User user){
        userMapper.insertUser(user);
        return user;
    }

    @RequestMapping("/user/delete/{id}")
    public Integer insertUser(@PathVariable("id") Integer id){
        return userMapper.deleteUser(id);
    }

    @RequestMapping("/user/select/{id}")
    public User getUser(@PathVariable("id") Integer id){
       return userMapper.getUserById(id);
    }

    @RequestMapping("/user/update")
    public User updateUser(User user){
        userMapper.updateUser(user);
        return user;
    }
}
```

测试：
1. 访问:http://localhost:8086/user/insert?id=4&loginName=youyou&userName=悠悠&departmentId=2，插入第4个主角的名字：
``` json
{"id":4,"loginName":"youyou","userName":"悠悠","departmentId":2}
```
这时候查看数据库，记录已经增加。
2. 访问:http://localhost:8086/user/update?id=4&userName=悠悠改，修改新增加的悠悠的信息
{"id":4,"loginName":null,"userName":"悠悠","departmentId":null}
因为我们返回的是传入的参数，所以其他两个字段的空值是正常的。

3. 访问:http://localhost:8086/user/delete/4，将新增加的主角悠悠记录删除：
``` json
1
```
返回的是操作影响的记录条数，显然是1条，并且数据库中记录已经被删除。

4. 访问http://localhost:8086/user/select/2，查询id为2的主角信息
``` json
{"id":2,"loginName":"crustina","userName":"克里斯汀娜","departmentId":1}
```

以上就是基于配置方式整合mybatis了，可以根据自己的需要，选择自己喜欢的开发方式。之前开发的项目差不多也是两种方式的混合体，但是时代在进步，既然用了springboot就不能少了JPA相关的理念，接下来，我们就学习JPA相关的东西，看看spring data还有什么有趣的内容。