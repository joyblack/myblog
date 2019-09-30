# 简介
1、安装scala地址：https://www.scala-lang.org/download/，通过s

2、在idea中编译运行。添加IDEA Scala（执行此操作后，pom文件中不用添加scala依赖，应为已经以lib库的方式加入）

进入Module Setting或者按F4进入界面，选择Gloabal Library，右键scala jar包，选择**Add to Modules...** 即可。

# 1、Scala解释器
配置好环境变量后，shell输入scala。

1、基本操作语句
```
scala> 3+4
res0: Int = 7

scala> 4*5+8
res1: Int = 28
```

2、Tab自动补全方法
```
scala> "hello,scala"
res2: String = hello,scala

scala> res2.to
to        toBoolean   toByte        toDouble   toIndexedSeq   toIterable   toList   toLowerCase   toSeq   toShort    toString        toUpperCase
toArray   toBuffer    toCharArray   toFloat    toInt          toIterator   toLong   toMap         toSet   toStream   toTraversable   toVector

scala> res2.sort
sortBy   sortWith   sorted

scala> res2.sorted
res3: String = ,aacehlllos
```

3、REPL模式(read-eval-print-loop)

4、查看命令行，以冒号开头的都是命令操作
```
scala> :help
All commands can be abbreviated, e.g., :he instead of :help.
:completions <string>    output completions for the given string
:edit <id>|<line>        edit history
:help [command]          print this summary or command-specific help
:history [num]           show the history (optional num is commands to show)
:h? <string>             search the history
:imports [name name ...] show import history, identifying sources of names
:implicits [-v]          show the implicits in scope
:javap <path|class>      disassemble a file or class name
:line <id>|<line>        place line(s) at the end of history
:load <path>             interpret lines in a file
:paste [-raw] [path]     enter paste mode or paste a file
:power                   enable power user mode
:quit                    exit the interpreter
:replay [options]        reset the repl and replay all previous commands
:require <path>          add a jar to the classpath
:reset [options]         reset the repl to its initial state, forgetting all session entries
:save <path>             save replayable session to a file
:sh <command line>       run a shell command (result is implicitly => List[String])
:settings <options>      update compiler options, if possible; see reset
:silent                  disable/enable automatic printing of results
:type [-v] <expr>        display the type of an expression without evaluating it
:kind [-v] <type>        display the kind of a type. see also :help kind
:warnings                show the suppressed warnings from the most recent line which had any
```

# 2、声明值和变量
1、val值不可变，var值可变。
```
scala> val answer = 1
answer: Int = 1

scala> var not = false
not: Boolean = false
```


2、必要的时候可以声明类型：变量:类型 = 值
```
scala> var greeting: String = null
greeting: String = null

scala> val s1,s2:String = "test"
s1: String = test
s2: String = test
```

# 3、常用类型
Byte Char Short Int Long Float Double

RichInt(Double、Char)

StringOps

# 4、算数和操作符重载
a 方法 b

a.方法(b)

不支持 ++ --

# 5、方法调用
如果没有参数，就不需要使用括号。

如果一个无参方法并不修改对象，调用时就可以不用写括号。

引入包的方式 _ 类似于java的*

可以直接使用半生对象的方法。

使用以scala开头的包时，可以省去scala的前缀。

# 6、apply方法
1、类似函数调用的语法：
```
s(i) <=> java中的s.charAt(i)，C++中的s[i]

scala> val s = "abc"
s: String = abc

scala> s(2)
res9: Char = c

scala> s[2]
<console>:1: error: identifier expected but integer literal found.
       s[2]
```
背后的实现逻辑：apply

2、同样，如下的操作都是背后调用了操作对象所属类的apply方法
```
scala> BigInt("123456")
res10: scala.math.BigInt = 123456

scala> BigInt.apply("123456")
res12: scala.math.BigInt = 123456

scala> Array(1,2,3)
res13: Array[Int] = Array(1, 2, 3)

scala> Array.apply(1,2,3)
res14: Array[Int] = Array(1, 2, 3)
```

# 7、Scala Doc
类似于JavaDoc一样的文档查看系统。

# L、练习
1、在scala中输入`3.`，会提示那些方法可以使用？
```scala
scala> 3.
!=   +   <<   >=    abs         compareTo     getClass     isNaN           isValidChar    isWhole     round        to               toDegrees     toInt           toShort   underlying
%    -   <=   >>    byteValue   doubleValue   intValue     isNegInfinity   isValidInt     longValue   self         toBinaryString   toDouble      toLong          unary_+   until
&    /   ==   >>>   ceil        floatValue    isInfinite   isPosInfinity   isValidLong    max         shortValue   toByte           toFloat       toOctalString   unary_-   |
*    <   >    ^     compare     floor         isInfinity   isValidByte     isValidShort   min         signum       toChar           toHexString   toRadians       unary_~
```

2、在Scala REPL中，计算3的平方根，然后再对该值求平方。现在，这个结果与3相差多少？
```scala
scala> import scala.math._
import scala.math._

scala> sqrt(3)
res15: Double = 1.7320508075688772

scala> pow(res15,2)
res16: Double = 2.9999999999999996

scala> 3 - res16
res18: Double = 4.440892098500626E-16
```

3、res变量是val还是var？
```
scala> res18 = res18 + 1
<console>:15: error: reassignment to val
       res18 = res18 + 1
```
显然是不可变的，即val。

4、Scala允许用数字乘以字符串，去REPL中试一下"crazy" * 3.这个操作做了什么？在ScalaDoc中如何找到这个操作？
```scala
scala> "crazy" * 3
res19: String = crazycrazycrazy
```
这个操作将字符串叠加了3次，形成一个新的字符串返回；在ScalaDoc中StringOps类中可以找到该方法
```scala
def *(n: Int): String
Return the current string concatenated n times.
```
5、 `10 max 2`的含义是什么？max定义在哪个类中？
含义为返回10和2中值最大的那一个。也可以写为10.max(2)、2.max(10)
```scala
scala> 10 max 2
res0: Int = 10
```
定义在Int类中
```scala
def max(that: Int): Int
Returns this if this > that or that otherwise.
```

6、用BigInt计算2的1024次方。
```scala
scala> BigInt(2).pow(1024)
res8: scala.math.BigInt = 179769313486231590772930519078902473361797697894230657273430081157732675805500963132708477322407536021120113879871393357658789768814416622492847430639474124377767893424865485276302219601246094119453082952085005768838150682342462881473913110540827237163350510684586298239947245938479716304835356329624224137216
```

7、为了在使用`probablePrime(100,Random)`获取随机质数时不在probablePrime和Radom之前使用任何限定符，需要引入什么？

```scala
// Random引用
scala> import scala.util._
import scala.util._

// probablePrime引用
scala> import scala.math.BigInt._
import scala.math.BigInt._

scala> probablePrime(100,Random)
res8: scala.math.BigInt = 960697016320705319171295980203
```

8、创建随机文件的方式之一生成一个随机的BigInt，然后将他转换成36进制，返回类似于"qsnvbevtomcj38o06kul"这样的字符串。查阅scala文档找到实现该逻辑的方法。
```scala
scala> val num = BigInt.probablePrime(100,Random)
num: scala.math.BigInt = 661712999120439539288883430513

scala> num.toString(36)
res9: String = 1s5jrbb731snvh11spdd
```

9、在scala中如何获取字符串的首字符和尾字符。
```scala
scala> var s9 = "abcde"
s9: String = abcde

scala> s9(0)
res10: Char = a

scala> s9.last
res10: Char = e
```

10、take、drop、takeRight和dropRight这些字符串方法是做什么用的？和substring相比，他们的优点和缺点有什么呢？
```
1. 在StringLike中
* take：Selects first n elements.（选择开头的n个字符）
* takeRight ：Selects last n elements.（选择末尾的n个字符）

2. StringOps
drop :Selects all elements except first n ones. (选择除了开头的n个字符)
dropRight：Selects all elements except last n ones. (选择除了末尾的n个字符)

substring： 选择子串,这个要构造一个新的字符串
```




