# 简介 
前面我们已经进行了一些前置的操作，比如配置本地化、登录验证等。这一节将会做一些稍微有点难度的操作。

# 6.1 拟定需求
我们接下来要做的要求如下：要满足RestFul开发风格，以Hppt方式区分对资源的CRUD操作:`URI: /资源名称/资源表示 `

||普通CURD（uri区别操作）|RestfulCRUD|
|-|-|-|
|查询|getEmp|emp---GET|
|添加|addEmp|emp---post|
|修改|updateEmp?id=xx&xxx=xx|emp/{id}---PUT|
|删除|deleteEmp?id=xx|emp/{id}---delete|

> *什么是Restful风格？* REST 指的是一组架构约束条件和原则。满足这些约束条件和原则的应用程序或设计就是 RESTful。
Web 应用程序最重要的 REST 原则是，客户端和服务器之间的交互在请求之间是无状态的。从客户端到服务器的每个请求都必须包含理解请求所必需的信息。如果服务器在请求之间的任何时间点重启，客户端不会得到通知。此外，无状态请求可以由任何可用服务器回答，这十分适合云计算之类的环境。客户端可以缓存数据以改进性能。

由此我们可以这样做:
||请求URI|请求方式|
|-|-|-|
|查询所有员工|emps|GET|
|查询某个员工(来到修改页面)|emp/{id}|GET|
|来到添加页面|emp|GET|
|添加员工|emp|POST|
|来到修改页面（查出员工信息进行信息回显）|emp/{id}|GET|
|修改员工|emp|PUT|
|删除员工|emp/{id}|DELETE|
按照此表进行如下的开发流程。

# 6.2 员工列表
1. 准备
创建员工类：
``` java
package com.zhaoyi.springboot.restweb.entities;

import java.util.Date;

public class Employee {

	private Integer id;
    private String lastName;

    private String email;
    //1 male, 0 female
    private Integer gender;
    private Department department;
    private Date birth;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Integer getGender() {
        return gender;
    }

    public void setGender(Integer gender) {
        this.gender = gender;
    }

    public Department getDepartment() {
        return department;
    }

    public void setDepartment(Department department) {
        this.department = department;
    }

    public Date getBirth() {
        return birth;
    }

    public void setBirth(Date birth) {
        this.birth = birth;
    }
    public Employee(Integer id, String lastName, String email, Integer gender,
                    Department department) {
        super();
        this.id = id;
        this.lastName = lastName;
        this.email = email;
        this.gender = gender;
        this.department = department;
        this.birth = new Date();
    }

    public Employee() {
    }

    @Override
    public String toString() {
        return "Employee{" +
                "id=" + id +
                ", lastName='" + lastName + '\'' +
                ", email='" + email + '\'' +
                ", gender=" + gender +
                ", department=" + department +
                ", birth=" + birth +
                '}';
    }
	
	
}

```
关联的部门类
``` java
package com.zhaoyi.springboot.restweb.entities;

public class Department {

	private Integer id;
	private String departmentName;

	public Department() {
	}
	
	public Department(int i, String string) {
		this.id = i;
		this.departmentName = string;
	}

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

	@Override
	public String toString() {
		return "Department [id=" + id + ", departmentName=" + departmentName + "]";
	}
	
}
```
部门数据仓库
``` java
package com.zhaoyi.springboot.restweb.dao;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import com.zhaoyi.springboot.restweb.entities.Department;
import org.springframework.stereotype.Repository;



@Repository
public class DepartmentDao {

	private static Map<Integer, Department> departments = null;
	
	static{
		departments = new HashMap<Integer, Department>();
		
		departments.put(101, new Department(101, "D-AA"));
		departments.put(102, new Department(102, "D-BB"));
		departments.put(103, new Department(103, "D-CC"));
		departments.put(104, new Department(104, "D-DD"));
		departments.put(105, new Department(105, "D-EE"));
	}
	
	public Collection<Department> getDepartments(){
		return departments.values();
	}
	
	public Department getDepartment(Integer id){
		return departments.get(id);
	}
	
}

```
员工数据仓库
``` java
package com.zhaoyi.springboot.restweb.dao;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import com.zhaoyi.springboot.restweb.entities.Department;
import com.zhaoyi.springboot.restweb.entities.Employee;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;


@Repository
public class EmployeeDao {

	private static Map<Integer, Employee> employees = null;
	
	@Autowired
	private DepartmentDao departmentDao;
	
	static{
		employees = new HashMap<Integer, Employee>();

		employees.put(1001, new Employee(1001, "E-AA", "aa@163.com", 1, new Department(101, "D-AA")));
		employees.put(1002, new Employee(1002, "E-BB", "bb@163.com", 1, new Department(102, "D-BB")));
		employees.put(1003, new Employee(1003, "E-CC", "cc@163.com", 0, new Department(103, "D-CC")));
		employees.put(1004, new Employee(1004, "E-DD", "dd@163.com", 0, new Department(104, "D-DD")));
		employees.put(1005, new Employee(1005, "E-EE", "ee@163.com", 1, new Department(105, "D-EE")));
	}
	
	private static Integer initId = 1006;
	
	public void save(Employee employee){
		if(employee.getId() == null){
			employee.setId(initId++);
		}

		employee.setDepartment(departmentDao.getDepartment(employee.getDepartment().getId()));
		employees.put(employee.getId(), employee);
	}
	
	public Collection<Employee> getAll(){
		return employees.values();
	}
	
	public Employee get(Integer id){
		return employees.get(id);
	}
	
	public void delete(Integer id){
		employees.remove(id);
	}
}
```

> `@Repository`将仓库类注册到容器中，我们需要用的时候使用`@Autowired`注入就可以了。

2. 修改`index.hmtl`的菜单栏标签请求地址，根据上表，我们知道应该改为`/emps`请求地址：
``` html
<a class="nav-link" th:href="@{/emps}">
```

2. 编写restful风格的响应方法。

> 注意将list.html放进`/resource/templates/emp/`下。如前面所说，默认情况下模板框架会对`classpath:/templates/emp/xx.html`进行渲染，其中`xx`即是我们返回的字符串视图信息；
3. 抽取thymeleaf的公共片段
我们改了index.html页面的连接，但是当我们跳转到list.html页面时，发现该页面的同样部位还是老样子，这就需要我们开发其他语言时所用到的模板概念了，所幸thymeleaf支持模板。也就是fragment相关知识。

* 抽取公共片段
``` html
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<body>
<div th:fragment="copy">
&copy; 2011 The Good Thymes Virtual Grocery
</div>
</body>
</html>
```
* 引入公共片段
``` html
<body>
...
<div th:insert="~{footer :: copy}"></div>
</body
```
方式1：`~{templatename::selector}`模板名：选择器

方式2：`~{templatename::fragmentname}` 模板名：片段名 显然这里是第二种写法。

> 其中，模板名会使用thymeleaf的前后缀配置规则进行解析。

三种引入功能片段的`th:xx`属性:
* th:insert 
* th:replace
* th:include 
``` html
<body>
...
<div th:insert="footer :: copy"></div>
<div th:replace="footer :: copy"></div>
<div th:include="footer :: copy"></div>
</body>
```
结果:
``` html
<body>
...
<div>
<footer>
&copy; 2011 The Good Thymes Virtual Grocery
</footer>
</div>

<footer>
&copy; 2011 The Good Thymes Virtual Grocery
</footer>

<div>
&copy; 2011 The Good Thymes Virtual Grocery
</div>
</body
```
因此可以总结如下：
* th:insert 公共片段插入到引入标签声明元素（`<div></div>`）的内部；
* th:replace 公共片段替换掉引入标签声明元素`<div></div>`；
* th:include 将被引入的公共片段的内容包含进标签中，即被引入的公共片段标签被舍去(`<foooter>`)

如果使用th:insert等属性进行引入，可以不用写~{...}，而行内写法需要加上:`[[~{}]]`、`[(~{})]`。

> 这里最好配置官方文档食用：`8 Template Layout`

按照上述知识就可以将我们的页面的公共部分抽去了。
* 抽取navar，顶部栏
``` html
<nav th:fragment="topbar" class="navbar navbar-dark sticky-top bg-dark flex-md-nowrap p-0">
```
去到重复的页面，将此处使用模板语法取代：
``` html
		<nav th:replace="index::topbar">
		</nav>
```

* 上面一种方法是用`~{templatename::fragmentname} 模板名：片段名`的方法替换了顶部栏的模板，接下来我们对菜单栏（左导航）使用`~{templatename::selector} 模板名：选择器`的方式进行操作：

提取
``` html
<nav class="col-md-2 d-none d-md-block bg-light sidebar" id="sidebar">
```
> 直接表明ID即可，无需任何`th:fragment`标签；

替换
``` html
<div th:replace="index::#sidebar"></div>
```
> 注意ID选择器的关键字`#`，不要写漏了哟。


### 抽取公共部分到common文件夹中
在实际开发中，我们一般是不会像之前那样做，即便使用了模板功能，你也会发现，太过繁琐，页面交互影响，非常难为维护，因此，我们需要将公共部分抽离出来，放在一个公共文件夹，这样方便管理。
于是，我们将所有的公共模板抽去出来，放在commons文件夹中，如下所示：
``` html
<!-- commons/bar.html -->
<!DOCTYPE html>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<!-- 顶部模块 -->
<nav class="navbar navbar-dark sticky-top bg-dark flex-md-nowrap p-0" id="topbar">
...
</nav>

<!-- 导航模块 -->
<nav class="col-md-2 d-none d-md-block bg-light sidebar" id="sidebar">
    ...
</nav>
</body>
</html>
```
> 此处我已经将其修改为相同的模式，即只需要用ID引入即可。省去了th代码块。

同时，删除index.html和list.html中的相关部分，都加入导入模块代码，他们应该由
``` html
<div th:replace="index::#sidebar"></div>
```
修改为
``` html
<div th:replace="commons/bar::#sidebar"></div>
```
这样的模式。

> 其中`commons/bar` 刚好对应于commons下的bar文件，sidebar对应引用对应模块的id。

### 菜单高亮参数化
我们还发现有一个问题，那就是菜单栏的菜单高亮问题，比如我们点击首页，应该dashboard菜单栏高亮，点击员工列表，员工列表高亮，我们观察html样式发现，其实就是他们是否具备`active`这个class与否的问题，这就需要我们做一件事，那就是在进行片段引入的时候，进行参数传递，告诉当前片段我是什么页面进行了引入，其实就是一个传递参数的过程，让当前片段根据参数的值生成具体的片段行为，查看thymeleaf官方文档了解相应的传参方式：

``` html
<div th:replace="::frag (twovar=${value2},onevar=${value1})">...</div>
```

在看看具体的片段（bar.html中的片段）接收参数的方式:
``` html
<div th:fragment="frag (onevar,twovar)">
<p th:text="${onevar} + ' - ' + ${twovar}">...</p>
</div>
```
另外，还可以不用特定的去写接受参数的方式，可以直接在片段里面直接引用变量即可。因此，我们可以这样写：

#### index.html
``` html
<div th:replace="commons/bar::#sidebar(activeUri='index')"></div>

```

#### list.html
``` html
<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
```

#### bar.html
``` html
...
<a class="nav-link active" th:class="${activeUri=='index'? 'nav-link active':'nav-link'}" th:href="@{/index}">
...

<a class="nav-link" th:class="${activeUri=='emps'? 'nav-link active':'nav-link'}" th:href="@{/emps}">
```
这样，就可以保证传递根据我们的不同页面，高亮对应的菜单模块了。

## 完善员工列表显示
在`list.html`页面中，将我们返回的emps列表显示，代码如下：
``` html
<div class="container-fluid">
			<div class="row">
				<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
				<main role="main" class="col-md-9 ml-sm-auto col-lg-10 pt-3 px-4">
					<h2><a class="btn btn-sm btn-primary">add</a></h2>
					<div class="table-responsive">
						<table class="table table-striped table-sm">
							<thead>
								<tr>
									<th>#</th>
									<th>lastName</th>
									<th>email</th>
									<th>gender</th>
									<th>department</th>
									<th>birth</th>
									<th>operate</th>
								</tr>
							</thead>
							<tbody>
								<tr th:each="emp:${emps}">
									<td th:text="${emp.id}"></td>
									<td th:text="${emp.lastName}"></td>
									<td th:text="${emp.email}"></td>
									<td th:text="${emp.gender} == 0? '男':'女'"></td>
									<td th:text="${emp.department.departmentName}"></td>
									<td th:text="${#dates.format(emp.birth, 'yyyy-MM-dd:HH:mm')}"></td>
									<td><a class="btn btn-sm btn-default">edit</a>
										<a class="btn btn-sm btn-warning">delete</a>
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</main>
			</div>
		</div>
```
其中:
1. `th:each` 属性会因为每一次遍历生成一次所在标签；
2. 我们最后还添加了一些操作按钮，为接下来的下一部分工作展开铺垫。

# 6.3 员工添加
## 来到员工添加页面
1. 我们首先修改跳转标签的跳转属性，注意要符合restful风格，参考之前的表格，修改如下：
``` java
@Controller
public class EmployeeController {

    @Autowired
    private EmployeeDao employeeDao;

    @RequestMapping("/emps")
    @GetMapping
    public String emps(Model model){
        model.addAttribute("emps", employeeDao.getAll());
        return "emp/list";
    }

    /**
     * 接收前往员工添加页面的请求，并跳转到添加页面emp/add.html
     * @return
     */
    @RequestMapping("/emp")
    @GetMapping
    public String toAddPage(){
        return "emp/add";
    }
}
```
2. 在emp下编写add.html，如下所示：
``` html
<!DOCTYPE html>
<!-- saved from url=(0052)http://getbootstrap.com/docs/4.0/examples/dashboard/ -->
<html xmlns:th="http://www.thymeleaf.org">

	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
		<meta name="description" content="">
		<meta name="author" content="">

		<title>Dashboard Template for Bootstrap</title>
		<!-- Bootstrap core CSS -->
		<link th:href="@{asserts/css/bootstrap.min.css}" rel="stylesheet">

		<!-- Custom styles for this template -->
		<link th:href="@{asserts/css/dashboard.css}" rel="stylesheet">
		<style type="text/css">
			/* Chart.js */
			
			@-webkit-keyframes chartjs-render-animation {
				from {
					opacity: 0.99
				}
				to {
					opacity: 1
				}
			}
			
			@keyframes chartjs-render-animation {
				from {
					opacity: 0.99
				}
				to {
					opacity: 1
				}
			}
			
			.chartjs-render-monitor {
				-webkit-animation: chartjs-render-animation 0.001s;
				animation: chartjs-render-animation 0.001s;
			}
		</style>
	</head>

	<body>
		<div th:replace="commons/bar::#topbar"></div>
		<div class="container-fluid">
			<div class="row">
				<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
				<main role="main" class="col-md-9 ml-sm-auto col-lg-10 pt-3 px-4">
					<form>
						<div class="form-group">
							<label>LastName</label>
							<input type="text" class="form-control" placeholder="zhangsan">
						</div>
						<div class="form-group">
							<label>Email</label>
							<input type="email" class="form-control" placeholder="zhangsan@atguigu.com">
						</div>
						<div class="form-group">
							<label>Gender</label><br/>
							<div class="form-check form-check-inline">
								<input class="form-check-input" type="radio" name="gender"  value="1">
								<label class="form-check-label">男</label>
							</div>
							<div class="form-check form-check-inline">
								<input class="form-check-input" type="radio" name="gender"  value="0">
								<label class="form-check-label">女</label>
							</div>
						</div>
						<div class="form-group">
							<label>department</label>
							<select class="form-control">
								<option>1</option>
								<option>2</option>
								<option>3</option>
								<option>4</option>
								<option>5</option>
							</select>
						</div>
						<div class="form-group">
							<label>Birth</label>
							<input type="text" class="form-control" placeholder="zhangsan">
						</div>
						<button type="submit" class="btn btn-primary">添加</button>
					</form>
				</main>
			</div>
		</div>

		<!-- Bootstrap core JavaScript
    ================================================== -->
		<!-- Placed at the end of the document so the pages load faster -->
		<script type="text/javascript" src="asserts/js/jquery-3.2.1.slim.min.js"></script>
		<script type="text/javascript" src="asserts/js/popper.min.js"></script>
		<script type="text/javascript" src="asserts/js/bootstrap.min.js"></script>

		<!-- Icons -->
		<script type="text/javascript" src="asserts/js/feather.min.js"></script>
		<script>
			feather.replace()
		</script>

		<!-- Graphs -->
		<script type="text/javascript" src="asserts/js/Chart.min.js"></script>
	</body>

</html>
```
完成之后运行我们还发现了一个问题，那就是部门选择哪个地方，其实是来源自我们后台的部门信息来生成因此，我们跳转到添加员工页面时，还应该将部门信息全部传递过来：
#### 修改过后的Controller:
``` java
	....
    @Autowired
    private DepartmentDao departmentDao;
	...
    /**
     * 接收前往员工添加页面的请求，并跳转到添加页面emp/add.html
     * @return
     */
    @RequestMapping("/emp")
    @GetMapping
    public String toAddPage(Model model){
        Collection<Department> departments = departmentDao.getDepartments();
        model.addAttribute("departments", departments);
        return "emp/add";
    }
}
```
#### 修改过后的add.html
``` html
<!DOCTYPE html>
<!-- saved from url=(0052)http://getbootstrap.com/docs/4.0/examples/dashboard/ -->
....
						<div class="form-group">
							<label>department</label>
							<select class="form-control">
								<option th:each="department:${departments}" th:value="${department.id}" th:text="${department.departmentName}"></option>
							</select>
						</div>

...
```




