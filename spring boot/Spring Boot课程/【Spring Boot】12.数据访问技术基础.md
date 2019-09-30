# 简介
前面的铺垫工作，目前已经做得差不多了，接下来我们将要学习有关Spring boot的数据访问技术，包括:jdbc技术、MyBatis、Spring Data JPA，他着眼于整个JAVAEE。

对于数据访问层，无论是SQL还是NOSQL，springboot默认采用整合Spring Data的方式进行统一处理，添加大量自动配置，屏蔽了很多设置。引入各种xxxTemplate、xxxResitory来简化我们对数据访问层的操作。对我们来说只需要进行简单的设置即可。我们将在接下来的学习过程中学到SQL相关、NOSQL在缓存、消息、检索等章节相关的内容。

- JDBC
- MyBatis
- JAP

Spring Data相关文档：[前往](https://spring.io/projects/spring-data)


# 整合JDBC与数据源
通过springboot initializer创建一个选择了web、jdbc、mysql几个模块。
## 依赖引入
``` xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
        </dependency>

        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <scope>runtime</scope>
        </dependency>
```

可以看到，引入了一个jdbc的场景启动器，以及底层依赖mysql-connector-java，并且是运行时依赖`runtime`。

> 在此之前，请注意上一节有关docker的内容，安装好了mysql服务，我的地址是10.21.1.47:3306，其账号密码root:123456。如果您也在测试的话，请保证自己安装了mysql服务，并正常启动。

> 还要记得在mysql中创建一个自己的数据库，我这里创建了一个数据库，名为joyblack.

## 初步测试
我们在配置文件中配置连接数据库的配置：
#### application.yml
``` yaml
server:
  port: 8086
spring:
  datasource:
    username: root
    password: 123456
    url: jdbc:mysql://10.21.1.47:3306/joyblack?characterEncoding=utf8&serverTimezone=GMT
    driver-class-name: com.mysql.cj.jdbc.Driver
    initialization-mode: always
```

#### 测试类JdbcwebApplicationTests
``` java
@RunWith(SpringRunner.class)
@SpringBootTest
public class JdbcwebApplicationTests {

    @Autowired
    DataSource dataSource;
    @Test
    public void contextLoads() throws SQLException {
        System.out.println(dataSource.getClass());
        System.out.println(dataSource.getConnection());
    }

}
```

> com.mysql.jdbc.Driver 是 mysql-connector-java 5中的，com.mysql.cj.jdbc.Driver 是 mysql-connector-java 6中的。

结果：
* 默认使用的是`com.zaxxer.hikari.HikariDataSource`作为数据源，这是2.x版本哦，请留意。

由于视频这里是基于1.x版本的，有兴趣的同学就去参考一下，其实配置原理和之前讲的大同小异，不过2.0在某些地方则需要进一步研究，其引进了不少java8新特性。这里就不在阐述了。


## **DataSourceInitializer：ApplicationListener**；
我们观察源码：
``` java

/**
 * Initialize a {@link DataSource} based on a matching {@link DataSourceProperties}
 * config.
 */
class DataSourceInitializer {

	private static final Log logger = LogFactory.getLog(DataSourceInitializer.class);

	private final DataSource dataSource;

	private final DataSourceProperties properties;

	private final ResourceLoader resourceLoader;

	/**
	 * Create a new instance with the {@link DataSource} to initialize and its matching
	 * {@link DataSourceProperties configuration}.
	 * @param dataSource the datasource to initialize
	 * @param properties the matching configuration
	 * @param resourceLoader the resource loader to use (can be null)
	 */
	DataSourceInitializer(DataSource dataSource, DataSourceProperties properties,
			ResourceLoader resourceLoader) {
		this.dataSource = dataSource;
		this.properties = properties;
		this.resourceLoader = (resourceLoader != null) ? resourceLoader
				: new DefaultResourceLoader();
	}

	/**
	 * Create a new instance with the {@link DataSource} to initialize and its matching
	 * {@link DataSourceProperties configuration}.
	 * @param dataSource the datasource to initialize
	 * @param properties the matching configuration
	 */
	DataSourceInitializer(DataSource dataSource, DataSourceProperties properties) {
		this(dataSource, properties, null);
	}

	public DataSource getDataSource() {
		return this.dataSource;
	}

	/**
	 * Create the schema if necessary.
	 * @return {@code true} if the schema was created
	 * @see DataSourceProperties#getSchema()
	 */
	public boolean createSchema() {
		List<Resource> scripts = getScripts("spring.datasource.schema",
				this.properties.getSchema(), "schema");
		if (!scripts.isEmpty()) {
			if (!isEnabled()) {
				logger.debug("Initialization disabled (not running DDL scripts)");
				return false;
			}
			String username = this.properties.getSchemaUsername();
			String password = this.properties.getSchemaPassword();
			runScripts(scripts, username, password);
		}
		return !scripts.isEmpty();
	}

	/**
	 * Initialize the schema if necessary.
	 * @see DataSourceProperties#getData()
	 */
	public void initSchema() {
		List<Resource> scripts = getScripts("spring.datasource.data",
				this.properties.getData(), "data");
		if (!scripts.isEmpty()) {
			if (!isEnabled()) {
				logger.debug("Initialization disabled (not running data scripts)");
				return;
			}
			String username = this.properties.getDataUsername();
			String password = this.properties.getDataPassword();
			runScripts(scripts, username, password);
		}
	}

	private boolean isEnabled() {
		DataSourceInitializationMode mode = this.properties.getInitializationMode();
		if (mode == DataSourceInitializationMode.NEVER) {
			return false;
		}
		if (mode == DataSourceInitializationMode.EMBEDDED && !isEmbedded()) {
			return false;
		}
		return true;
	}

	private boolean isEmbedded() {
		try {
			return EmbeddedDatabaseConnection.isEmbedded(this.dataSource);
		}
		catch (Exception ex) {
			logger.debug("Could not determine if datasource is embedded", ex);
			return false;
		}
	}

	private List<Resource> getScripts(String propertyName, List<String> resources,
			String fallback) {
		if (resources != null) {
			return getResources(propertyName, resources, true);
		}
		String platform = this.properties.getPlatform();
		List<String> fallbackResources = new ArrayList<>();
		fallbackResources.add("classpath*:" + fallback + "-" + platform + ".sql");
		fallbackResources.add("classpath*:" + fallback + ".sql");
		return getResources(propertyName, fallbackResources, false);
	}

	private List<Resource> getResources(String propertyName, List<String> locations,
			boolean validate) {
		List<Resource> resources = new ArrayList<>();
		for (String location : locations) {
			for (Resource resource : doGetResources(location)) {
				if (resource.exists()) {
					resources.add(resource);
				}
				else if (validate) {
					throw new InvalidConfigurationPropertyValueException(propertyName,
							resource, "The specified resource does not exist.");
				}
			}
		}
		return resources;
	}

	private Resource[] doGetResources(String location) {
		try {
			SortedResourcesFactoryBean factory = new SortedResourcesFactoryBean(
					this.resourceLoader, Collections.singletonList(location));
			factory.afterPropertiesSet();
			return factory.getObject();
		}
		catch (Exception ex) {
			throw new IllegalStateException("Unable to load resources from " + location,
					ex);
		}
	}

	private void runScripts(List<Resource> resources, String username, String password) {
		if (resources.isEmpty()) {
			return;
		}
		ResourceDatabasePopulator populator = new ResourceDatabasePopulator();
		populator.setContinueOnError(this.properties.isContinueOnError());
		populator.setSeparator(this.properties.getSeparator());
		if (this.properties.getSqlScriptEncoding() != null) {
			populator.setSqlScriptEncoding(this.properties.getSqlScriptEncoding().name());
		}
		for (Resource resource : resources) {
			populator.addScript(resource);
		}
		DataSource dataSource = this.dataSource;
		if (StringUtils.hasText(username) && StringUtils.hasText(password)) {
			dataSource = DataSourceBuilder.create(this.properties.getClassLoader())
					.driverClassName(this.properties.determineDriverClassName())
					.url(this.properties.determineUrl()).username(username)
					.password(password).build();
		}
		DatabasePopulatorUtils.execute(populator, dataSource);
	}

}

```
​不难发现：
* `createSchema();`运行建表语句；
* `initSchema();` 运行插入数据的sql语句；

同时，默认只需要将文件命名为：
``` properties
schema-*.sql、data-*.sql
默认规则：schema.sql，schema-all.sql；
可以使用   
	schema:
      - classpath:department.sql
      指定位置
```

我们创建一个建表文件
#### resources/schema.sql
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

Date: 2018-12-19 14:03:49
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `user`
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL,
  `user_name` varchar(20) NOT NULL,
  `login_name` varchar(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of user
-- ----------------------------

```

将其放在资源目录下即可。运行项目，可以看到生成了具体的数据库表`user`;

接下来，我们放置初始化数据表的文件

#### resources/data.sql
``` sql
INSERT INTO `user` VALUES ('1', '阿库娅', 'akuya');
INSERT INTO `user` VALUES ('2', '克里斯汀娜', 'cristiner');
INSERT INTO `user` VALUES ('3', '惠惠', 'huihui');
```
同样将其放在资源目录下即可。运行项目，可以看到生成了具体的数据库表`user`的3条用户数据（为美好的明天献上祝福的女主角们）;

> `sql-script-encoding: utf-8` 在配置文件中配置此设置，保证中文不乱码，如果还发现乱码，请注意自己的连接url是否配置了`characterEncoding=utf8`；

> 若报出`The server time zone value '???ú±ê×??±??' is unrecognized...`这样的错误，请注意自己的连接url是否配置了`serverTimeZone=GMT`；

> 2.x版本的springboot必须指定`initialization-mode: always`配置，每次重启生成脚本才会执行;

另外，我们可以从源码中看到，该文件是可以配置位置的
``` java
  private List<Resource> getScripts(String propertyName, List<String> resources, String fallback) {
        if (resources != null) {
            return this.getResources(propertyName, resources, true);
        } else {
            String platform = this.properties.getPlatform();
            List<String> fallbackResources = new ArrayList();
            fallbackResources.add("classpath*:" + fallback + "-" + platform + ".sql");
            fallbackResources.add("classpath*:" + fallback + ".sql");
            return this.getResources(propertyName, fallbackResources, false);
        }
    }
```

如果我们配置了`this.properties.getData()`，则springboot会从该位置获取初始化文件，而该值根据我们前面讲过的模式，可以继续追溯，就是
#### package org.springframework.boot.autoconfigure.jdbc
``` java
@ConfigurationProperties(prefix = "spring.datasource")
public class DataSourceProperties implements BeanClassLoaderAware, InitializingBean {
    ...
    private List<String> schema;
    ...
```
也就是说，我们只需要配置一个`spring.datasource.schema`的数组对象，指明这些初始化文件的位置就可以了。

同理，另外一个则是`spring.datasource.data`，配置这两个参数就对应我们上述的两种文件了（初始化表结构；初始化表数据）。

我们可以随便测试一下：

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
      - classpath:schema1.sql
    data:
      - classpath:data1.sql
```

在此之前，记得复制两个文件为xx1.sql。

> 这里观察源码还发现两个操作方法都调用了`runScript`，也就是说，其底层都是一样的执行脚本方式，我们大可以将初始化表结构和添加数据的脚本混合成一个，但是可读性差了一些，当然也更加的方便管理，利弊见仁见智了。

# 原生JDBC操作数据库
这时候，我们就可以直接操作数据库的数据了，这里简单的演示一下查询操作，其他的操作也差不多是这样的模式。

我们创建一个controller查询数据

#### controller/HelloController.class
``` java
@RestController
public class IndexController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping("/query")
    public String index(){
        jdbcTemplate.execute("delete from user where id = 1");
        List<Map<String, Object>> maps = jdbcTemplate.queryForList("select * from user");
        
        return maps.toString();
    }
}
```

运行项目之后我们会发现数据库id为1的user表数据被删除，同事访问网站首页，可以得到如下的返回:
``` 
[{id=2, user_name=克里斯汀娜, login_name=cristiner}, {id=3, user_name=惠惠, login_name=huihui}]
```




