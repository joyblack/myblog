# 简介
前面我们完成了基本的框架搭建，现在我们继续WEB的开发
## 员工添加
我们已经完成了跳转到员工添加页面的操作以及页面的制作，现在我们来完善员工添加页面：
#### add.html
``` html

	<body>
		<div th:replace="commons/bar::#topbar"></div>
		<div class="container-fluid">
			<div class="row">
				<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
				<main role="main" class="col-md-9 ml-sm-auto col-lg-10 pt-3 px-4">
					<form action="/emp" method="post">
						<div class="form-group">
							<label>LastName</label>
							<input name="lastName" type="text" class="form-control" placeholder="zhangsan">
						</div>
						<div class="form-group">
							<label>Email</label>
							<input name="email" type="email" class="form-control" placeholder="zhangsan@atguigu.com">
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
							<select name="department.id" class="form-control">
								<option th:each="department:${departments}" th:value="${department.id}" th:text="${department.departmentName}"></option>
							</select>
						</div>
						<div class="form-group">
							<label>Birth</label>
							<input name="birth" type="text" class="form-control" placeholder="zhangsan">
						</div>
						<button type="submit" class="btn btn-primary">添加</button>
					</form>
				</main>
			</div>
		</div>
        </body>
```
其中
* 我们应该按照restful风格定义提交页面，即post形式的emp地址；
* 接受处理的controller提供一个emp对象给我们传入，为了让spring mvc底层直接映射，需要将表单的`name`属性的值表述的和emp对应的属性一样；另外要注意部门属性那里，写为`department.id`这样进行内部对象的二次属性映射；

#### EmployeeController.class
``` java

@Controller
public class EmployeeController {

    @Autowired
    private DepartmentDao departmentDao;

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
    @GetMapping("/emp")
    public String toAddPage(Model model){
        Collection<Department> departments = departmentDao.getDepartments();
        model.addAttribute("departments", departments);
        return "emp/add";
    }

    @PostMapping("/emp")
    public String emp(Employee emp){
        // 添加员工到内存库
        employeeDao.save(emp);
        // 重定向到emps请求
        return "redirect:/emps";
    }
}
```


其中
* 日期格式springboot默认处理'yyyy/MM/dd'格式，如果我们需要修改的话在配置文件里配置属性:`spring.mvc.date-format`，如`spring.mvc.date-format=yyyy-MM-dd`将默认请求日期格式`yyyy/MM/dd`修改为`yyyy-MM-dd`，则此时我们提交的日期内容必须为`'2017-12-01'`这样的，否则会报错；
* 通过`@GetMapping`和`@PostMapping`处理相同地址但不同的请求方式的请求(`method=post or get`),`get`是默认形式，满足restful，此处是提交数据，因此我们处理的是`post`方式提交的`/emp`请求；
* 重定向(`redirect:`)、转发(`forward:`),`/`代表当前项目路径；
* 在controller的请求方法处直接添加对象参数，spring mvc会为我们自动的进行字段绑定，将表单数据和参数对象进行数据映射，前提是我们保证对应的字段名和表单name属性相等；

## 员工信息修改

### 点击编辑按钮来到修改页面
教程这里将添加和修改员工信息的页面进行了合成（`add.html`），其实整体看下来，这样做有些没必要，其优点是明显的，修改的时候可以同步进行。但是付出的代价太大了（太多的三元判断，代码可阅读性差），所以推荐还是新建一个edit.html页面好些。

首先我们修改编辑按钮的跳转链接
#### list.html
``` html
<a class="btn btn-sm btn-primary" th:href="@{/emp/} + ${emp.id}">edit</a>
```
注意拼接字符串的写法。然后需要控制台映射`/emp/{id}`进行处理，并跳转到员工信息修改的页面。


#### EmployeeController.class
``` java
    @GetMapping("/emp/{id}")
    public String toEditPage(@PathVariable(value = "id") Integer id,
                             Model model){
        Employee employee = employeeDao.get(id);
        Collection<Department> departments = departmentDao.getDepartments();
        model.addAttribute("departments", departments);
        model.addAttribute("emp", employee);
        return "emp/edit";
    }
```
其中：
* `toEditPage`方法映射了`/emp/{id}`路径，`{id}`是路径变量，我们可以通过添加参数，并注明注解`@PathVariable("id")`的方式获取到路径变量的值，即我们的请求一般是`/emp/1000`其中`1000`是员工的ID，通过此ID，我们就可以确定当前员工的信息了;

那么，接下来，复制add.html内容为新文件edit.html，并修改相应的信息。
#### edit.html
``` html
<div th:replace="commons/bar::#topbar"></div>
		<div class="container-fluid">
			<div class="row">
				<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
				<main role="main" class="col-md-9 ml-sm-auto col-lg-10 pt-3 px-4">
					<form action="/emp" method="post">
						<!-- put方式提交 -->
						<input type="hidden" name="_method" value="put"/>
						<!-- 提供ID属性 -->
						<input type="hidden" name="id" th:value="${emp.id}" />
						<div class="form-group">
							<label>LastName</label>
							<input name="lastName" type="text" class="form-control" th:value="${emp.id}">
						</div>
						<div class="form-group">
							<label>Email</label>
							<input name="email" type="email" class="form-control" th:value="${emp.email}">
						</div>
						<div class="form-group">
							<label>Gender</label><br/>
							<div class="form-check form-check-inline">
								<input class="form-check-input" type="radio" name="gender"  value="1" th:checked="${emp.gender == 1}">
								<label class="form-check-label">男</label>
							</div>
							<div class="form-check form-check-inline">
								<input class="form-check-input" type="radio" name="gender"  value="0" th:checked="${emp.gender == 0}">
								<label class="form-check-label">女</label>
							</div>
						</div>
						<div class="form-group">
							<label>department</label>
							<select name="department.id" class="form-control">
								<option th:selected="${emp.department.id == department.id}" th:each="department:${departments}" th:value="${department.id}" th:text="${department.departmentName}"></option>
							</select>
						</div>
						<div class="form-group">
							<label>Birth</label>
							<input name="birth" type="text" class="form-control" th:value="${#dates.format(emp.birth, 'yyy-MM-dd HH:mm')}">
						</div>
						<button type="submit" class="btn btn-primary">修改</button>
					</form>
				</main>
			</div>
		</div>
```

注意其中进行信息展示的代码，另外：
* 此处提交方式应该设置为`put`，但是表单提交是没有这种选择的，因此，我们需要走另外一种方式进行put方式提交。所幸springMvc配置了一个Filter，名叫`HiddenHttpMethodFilter`，他能将我们请求转化成指定的方式，并且SpringBoot已经将该过滤器自动的加载到了启动容器中，我们直接使用即可：在edit.html页面创建一个`post`表单，然后再创建一个`hidden`类型的`input`项，其`name`属性设置为我们指定的请求方式(`put`)即可；

接下来的工作就是处理这里提交的put请求，然后修改员工信息。

#### EmployeeController.class
``` java
    @PutMapping("/emp")
    public String updateEmp(Employee emp){
        // 修改员工信息
        employeeDao.save(emp);
        // 重定向到emps请求
        return "redirect:/emps";
    }
```

## 员工删除
首先，写一个映射方法，用于处理delete方式提交的请求:
#### EmployeeController.class
``` java
    @DeleteMapping("/emp/{id}")
    public  String deleteEmp(@PathVariable("id") Integer id){
        employeeDao.delete(id);
        return "redirect:/emps";
    }
```

在页面，对删除按钮进行操作，但这里同样需要修改其提交方式，我们可以每次生成delete按钮的时候创建一个表单，但这显然比较笨重。我们可以考虑将表单提出来，然后用其他的脚本将事件进行映射即可。

因此，我们不妨通过jquery进行一下按钮事件绑定，叫其行为进行修改，使页面更加的简洁。

#### list.html
``` html

	<body>
		<div th:replace="commons/bar::#topbar"></div>
		<div class="container-fluid">
			<div class="row">
				<div th:replace="commons/bar::#sidebar(activeUri='emps')"></div>
				<main role="main" class="col-md-9 ml-sm-auto col-lg-10 pt-3 px-4">
					<h2><a class="btn btn-sm btn-primary" th:href="@{/emp}">add</a></h2>
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
									<td th:text="${emp.gender} == 1? '男':'女'"></td>
									<td th:text="${emp.department.departmentName}"></td>
									<td th:text="${#dates.format(emp.birth, 'yyyy-MM-dd HH:mm')}"></td>
									<td><a class="btn btn-sm btn-primary" th:href="@{/emp/} + ${emp.id}">edit</a>
										<button class="btn btn-sm btn-warning" id="btnDelete" th:attr="uri=@{/emp/} + ${emp.id}">delete</button>
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</main>
			</div>
		</div>
		<form method="post" id="deleteForm">
			<input type="hidden" name="_method" value="delete" />
		</form>
		<!-- Bootstrap core JavaScript
    ================================================== -->
		<!-- Placed at the end of the document so the pages load faster -->
		<script type="text/javascript" src="/asserts/js/jquery-3.2.1.slim.min.js"></script>
		<script type="text/javascript" src="/asserts/js/popper.min.js"></script>
		<script type="text/javascript" src="/asserts/js/bootstrap.min.js"></script>

		<!-- Icons -->
		<script type="text/javascript" src="/asserts/js/feather.min.js"></script>
		<script>
			feather.replace()
		</script>
		<!-- Graphs -->
		<script type="text/javascript" src="/asserts/js/Chart.min.js"></script>

		<script>
			$(function(){
			    $("#btnDelete").click(function(){
					$("#deleteForm").attr("action", $(this).attr("uri")).submit();
				});
			})

		</script>
	</body>
```

> 至此为止，我们已经完成了一个基本的CURD网站，接下来，将学习更深层次的业务处理办法，比如，错误处理机制。
