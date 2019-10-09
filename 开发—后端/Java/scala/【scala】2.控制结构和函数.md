# 简介
在Java或者C++中，我们把表达式和语句看做两种不同的东西。表达式有值，而语句执行动作。

在Scala中，几乎所有构造出来的语法结构都是有值的。这个特性使得程序更加的精简，也更易读。

# 1、条件表达式
```scala
scala> val x = 1
x: Int = 1

scala> val res = if(x == 1) 1 else 0
res: Int = 1

scala> var res = if(x == 1) "hello" else 3
res: Any = hello
```

# 2、语句终止
Scala的语句无需添加类似Java和C++的分号`;`表示结尾，编译器会自动判断。当然，如果单行下存在多个语句，那么则需要用分号隔开前面的n-1个语句：
```scala
if ( x > 1) { r = r * n; n = n -1 }
```

# 3、块表达式和赋值
1、**块表达式**

`{ }`表示一系列表达式，其结果也是一个表达式。块中最后一个表达式的值就是块的值。
```scala
val distance = { val dx = x - x0; val dy = y - y0; sqrt(dx *dx + dy * dy)} 
```
可以看到，这样的语法可以很干净的让dx、dy等对外部不可见了。

2、**赋值语句**

一个以赋值语句结束的块，返回的是Unit类型的值。因此，类似于这样的操作可能和java中的不一样
```scala
x = y = 1
```
显然 x 的值为`y = 1`，即()，也是Unit类型。前面我们提到过一次性初始化的方式
```scala
scala> val x, y = 1;
x: Int = 1
y: Int = 1
```

# 4、输入和输出
1、**普通输出**
``` scala
scala> print("I love you.")
I love you.
scala> println("I love you too.")
I love you too.
换行
```

2、**字符串插值输出**
```scala
scala> val name = "akuya"
name: String = akuya

scala> print(f"I love $name!")
I love akuya!
```
格式化的字符串是Scala类库定义的三个字符串插值器之一。通过不同的前缀采取不同的输出策略：
* s: 字符串可以包含表达式但不能有格式化指令；
* row：转义序列不会被求值。例如 raw"\n love." 其中的`\n`会原样输出
* f：带有C风格的格式化字符串的表达式。

3、**控制台读取**

可以使用scala.io.StdIn的readLine方法从控制台读取一行输入。

# 5、循环
1、**while** 

和java的使用一致

2、**for**

和java的使用有所区别，其使用方式如下所示
```scala
for(i <- 表达式)
```
例如
``` scala
scala> for(i <- 1 to 10) println(i)
1
2
3
...
```
可以看到中间的特殊符号 `<-` 表示让变量i遍历(<-)右边的表达式的所有值。至于这个遍历具体的执行方式，则取决于后面的表达式的类型。对于集合而言，他会让i依次取得区间中的每个值。例如：
```scala
scala> for(i <- "abcde") print(s" $i")
 a b c d e
```

# 6、高级for循环

**生成器**： `>-` 后面的表达式。

**守卫**：每个生成器都可以带上守卫，一个以if开头的Boolean表达式
```scala
scala> for(i <- 1 to 3; j <- 1 to 3 if(i != j)) print(f"(i=$i,j=$j) ")
(i=1,j=2) (i=1,j=3) (i=2,j=1) (i=2,j=3) (i=3,j=1) (i=3,j=2)
```
> 注意在if之前没有分号，多个生成器之间需要分号

**定义**：在循环中对变量赋值，从而引入变量。
```scala
scala> for(i <- 1 to 3; j <- 1 to 3;home = i) print(f"(i=$i,j=$j,home=$home) ")
(i=1,j=1,home=1) (i=1,j=2,home=1) (i=1,j=3,home=1) (i=2,j=1,home=2) (i=2,j=2,home=2) (i=2,j=3,home=2) (i=3,j=1,home=3) (i=3,j=2,home=3) (i=3,j=3,home=3)
```
其中`home = i`就是一个定义。

**yield**：如果for循环的循环体以yield关键字开始，则该循环会构造出一个集合，每次迭代生成集合中的一个值：
```scala
scala> val vec = for (i <- 1 to 20) yield i % 2
vec: scala.collection.immutable.IndexedSeq[Int] = Vector(1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0)
```

# 7、函数
注意与类的方法进行区分。

在Java中函数只能用类的静态方法来模拟。

定义函数
```scala
def abs(x:Double) = if(x >= 0) x else -x
```

如果函数不是递归的，就不需要指定返回值类型。

同样，块中的最后一个表达式的值就是函数的值。

如果是递归函数，则需要定义返回值类型
```scala
def fac(n: Int): Int = {...}
```

# 8、默认参数和带名参数
调用某些函数时可以不必显式的给出所有参数值，对于这些函数我们可以使用默认参数。
```scala
def decorate(str: String, left: String = "[", right: String = "]"){...}

// 调用
decorate("hello")

// 调用2
decorate("hello","(",")")
```

# 9、变长参数
```scala
def sum(args: Int*) = {...}
```

# 10、过程
Scala对于不返回值的函数有特殊的表示法。如果函数体包含在花括号中但没有前面的`=`，那么返回类型就是Unit。这样的函数被称为**过程**。

```scala
// 省略了=号
def box(s: String) {...} 
```
当然，既然返回值是Unit类型，那么过程也可以用如下的方法定义
```scala
def box(s: String): Unit = {...}
```

# 11、懒值
当val被生命为lazy时，他的初始化将会被推迟，直到我们首次对他取值。很像Linq或者Spark RDD等许多数据处理框架的**惰性原理**。
```scala
scala> lazy val words = scala.io.Source.fromFile("/noexist.file")
words: scala.io.BufferedSource = <lazy>

scala> words.toString
java.io.FileNotFoundException: \noexist.file (系统找不到指定的文件。)
```
可以看到，即便我们一开始的words取的是一个不存在的文件，也没有立即报错，而是在我们对words进行取值之后才出现了错误。

可以把懒值理解为val和def的中间状态。

# 12、异常
Scala和java不一样，不支持“受检异常”。

throws表达式有特殊的类型Nothing。

如果一个分支的类型是Nothing，那么`if/else`表达式的类型就是另一个分支的类型。

捕获异常的语法采用的是模式匹配语法。


# L、练习
1、一个数字如果为正数，则他的signum为1；如果是负数，则signum为-1，；如果是0，则signum为0.编写一个函数来计算这个值。
```scala
package com.zhaoyi.c2

object Practice2 {

  def signum(x: Int): Int = {
    if(x > 0){
      1
    } else if( x == 0){
      0
    }else{
      -1
    }
  }

  def main(args: Array[String]): Unit = {
    println("signum(100) = " + signum(100));
    println("signum(0) = " + signum(0));
    println("signum(-100) = " + signum(-100));

    // 或者使用系统函数
    println("use system signum(10) = " + BigInt(10).signum);
  }
}
```
输出结果：
```
signum(100) = 1
signum(0) = 0
signum(-100) = -1
use system signum(10) = 1
```

2、一个空的块表达式`{}`的值是什么？类型是什么？
```
scala> var s = {}
s: Unit = ()
```
Unit表示无值，和其他语言中void等同。用作不返回任何结果的方法的结果类型。Unit只有一个实例值，写成()。

3、指出在scala中何种情况下赋值语句 `x = y = 1`是合法的。

显然，只需要有“需要x的值为()”的时候，这样的需求是合法的。

4、针对下列Java循环编写一个Scala版的程序。
```java
for(int i = 10;i>=0;i--){
       System.out.println(i);
}
```

scala版：
```scala
for(i <- 1 to 10 reverse) println(i)
```

5、编写一个过程`countdown(n: Int)`，打印从n到0的数字。
```scala
  def answer5(n: Int): Unit ={
    for(i <- 0 to n reverse){
      print(i + " ")
    }
  }
```

6、编写一个for循环，计算字符串中所有字母的Unicode代码的乘积。
```scala
  def answer6(str: String): Long = {
    var res: Long = 1
    for(c <- str){
      res *= c.toLong
    }
    println(s"$str count value is: " + res)
    res
  }

  def main(args: Array[String]): Unit = {
    answer6("Hello")
  }
```

7、同样是问题6，但这次不允许使用循环语句。

查找到
```scala
def foreach(f: (A) ⇒ Unit): Unit
[use case] Applies a function f to all elements of this string.
```
因此可以考虑使用foreach方法计算。
```scala
  def answer7(str: String): Long = {
    var res: Long = 1
    str.foreach(c => res *= c.toLong)
    println(s"$str count value is: " + res)
    res
  }

  def main(args: Array[String]): Unit = {
    answer7("Hello")
  }
```

8、编写一个函数product(s: String)，计算前面练习中提到的乘积。
```scala
  def product(str: String): Long = {
    var res: Long = 1
    str.foreach(c => res *= c.toLong)
    println(s"$str count value is: " + res)
    res
  }
```

9、把前一个练习中的函数改造为递归函数
```scala
  def answer9(str: String): Long = {
    if(str.length == 1){
      str(0).toLong
    }else{
      // 选择第0个元素，返回除了第0个元素的其他元素
      str(0).toLong * answer9(str.drop(1))
    }
  }

  def main(args: Array[String]): Unit = {
    val ans = answer9("Hello")
    print(ans)
  }
```

其中Doc文档：
```scala
// 返回除了前n个节点的元素
def drop(n: Int): String
Selects all elements except first n ones.

// 并没有用到此方法
def take(n: Int): String
Selects first n elements.

// 默认方法 apply
def apply(index: Int): Char
Return element at index n
```

10、编写函数计算$x^n$，其中n是整数，使用如下的递归定义
* $x^n=y*y$，如果n是正偶数的话，这里的$y=x^{\frac{n}{2}}$；
* $x^n=x*x^(n-1)$，如果n是正奇数的话；
* $x^0=1$
* $x^n=\frac{1}{x^{-n}}$，如果n是负数的话。

```scala
 def answer10(x: Double, n: Int): Double = {
    if(n == 0) 1
    else if (n > 0 && n % 2 == 0) answer10(x,n/2) * answer10(x,n/2)
    else if (n > 0 && n % 2 == 1) x * answer10(x,n - 1)
    else 1 / answer10(x, -n)
  }

  def main(args: Array[String]): Unit = {
    val ans = answer10(2,2)
    print(ans)
    // 4.0
  }
```






