# 简介
在本章中，我们将会学到如何在scala中操作数组。

# 1、定长数组
```scala
// 初始化长度为10的定长数组，每一个元素的值为0
val nums = new Array[Int](10)
// nums: Array[Int] = Array(0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

// 初始化长度为10的定长数组，每一个元素的值为null
scala> val str2 = new Array[String](10)
str2: Array[String] = Array(null, null, null, null, null, null, null, null, null, null)


scala> val num3 = Array(1,2,3)
num3: Array[Int] = Array(1, 2, 3)

scala> num3(0) = 4

scala> num3
res5: Array[Int] = Array(4, 2, 3)
```

> 已经提供初始值的情况下，就不需要new操作符了。

在JVM中，Scala的Array以Java数组的方式实现。

# 2、变长数组
Java中有ArrayList，C++有vector，而Scala中为ArrayBuffer。
```scala
// 首先导入包
scala> import scala.collection.mutable.ArrayBuffer
import scala.collection.mutable.ArrayBuffer

scala> val a = ArrayBuffer[Int]()
a: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer()

scala> a += 1
res0: a.type = ArrayBuffer(1)

scala> a(0)
res2: Int = 1

scala> a += (2,3,4,5)
res4: a.type = ArrayBuffer(1, 2, 3, 4, 5)

// +=  追加元素
// ++= 追加集合
scala> a ++= Array(2,3,4)
res7: a.type = ArrayBuffer(1, 2, 3, 4, 5, 2, 3, 4)

// trimEnd 移除最后的5个元素
scala> a.trimEnd(5)

scala> a
res9: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer(1, 2, 3)
```
以上都是基于尾部的操作，是比较搞笑的操作方式。也可以在任意位置进行操作。

```scala
// 不用指定类型（类型推断）
scala> val a = ArrayBuffer(1,1,1)
// ArrayBuffer(1, 1, 1)

// 在下标2处插入100
scala> a.insert(2,100)
// ArrayBuffer(1, 1, 100, 1)

// 插入多个值
scala> a.insert(0,200,300,400)
// ArrayBuffer(200, 300, 400, 1, 1, 100, 1)

// 移除元素
scala> a.remove(0)
// ArrayBuffer(300, 400, 1, 1, 100, 1)

// 移除多个元素，第二个参数的意思是移除多少个元素
scala> a.remove(0,3)
// ArrayBuffer(1, 100, 1)
```

可变与不可变数组之间的转换
```scala
scala> a.toArray
res8: Array[Int] = Array(1, 100, 1)

scala> res8.toBuffer
res9: scala.collection.mutable.Buffer[Int] = ArrayBuffer(1, 100, 1)
```

# 3、遍历数组与数组缓冲
遍历数组与数组缓冲的代码都是一样的，不像java和C++一样需要区别对待。

```scala
scala> for(i <- 0 until res8.length) println(s"$i : ${res8(i)}")
0 : 1
1 : 100
2 : 1

scala> for(i <- 0 until res9.length) println(s"$i : ${res9(i)}")
0 : 1
1 : 100
2 : 1
-------------------------------
// 重新创建一个集合
scala> val b = Array(1,2,3,4)
b: Array[Int] = Array(1, 2, 3, 4)


// 跳步为2的遍历
scala> for(i <- 0 until b.length by 2) println(b(i))
1
3

// 尾端遍历
scala> for(i <- (0 until b.length).reverse) println(b(i))
4
3
2
1

// 直接获取数组元素遍历
scala> for(ele <- b) println(ele)
1
2
3
4
```
> `0 until b.length`相当于取0到length-1。

# 4、数组转换
```scala
// yield
scala> val c = Array(1,2,3,4)
c: Array[Int] = Array(1, 2, 3, 4)

scala> val result = for (ele <- c) yield 2 * ele
result: Array[Int] = Array(2, 4, 6, 8)

// 或者使用map
scala> val result2 = c.map(ele => ele * 2)
result2: Array[Int] = Array(2, 4, 6, 8)
```

# 5、常用算法
```scala

scala> val a = Array(1,2,4,3,5)
a: Array[Int] = Array(1, 2, 4, 3, 5)

// 一些常用操作
scala> a.sum
res28: Int = 15

scala> a.min
res30: Int = 1

scala> a.max
res31: Int = 5

// 排序
scala> a.sorted
res37: Array[Int] = Array(1, 2, 3, 4, 5)

// 指定方式排序(sortWith方法只可适用于变长数组)
scala> val s = ArrayBuffer(1,2,4,3,5)
s: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer(1, 2, 4, 3, 5)

scala> s.sortWith(_ > _)
res39: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer(5, 4, 3, 2, 1)

```

# 6、打印数组元素
```scala
scala> a.mkString(",")
res0: String = 1,2,3,4,5

// 重载方法，设置两边的字符
scala> a.mkString("<",",",">")
res1: String = <1,2,3,4,5>
```

# 7、解读Scaladoc

# 8、多维数组
和Java一样，都是通过数组的数组实现多维数组。ofDim方法。
```scala
scala> val matrix = Array.ofDim[Double](3,4)
matrix: Array[Array[Double]] = Array(Array(0.0, 0.0, 0.0, 0.0), Array(0.0, 0.0, 0.0, 0.0), Array(0.0, 0.0, 0.0, 0.0))

scala> matrix(0)(0)=1

scala> matrix
res4: Array[Array[Double]] = Array(Array(1.0, 0.0, 0.0, 0.0), Array(0.0, 0.0, 0.0, 0.0), Array(0.0, 0.0, 0.0, 0.0))
```

# 9、与Java的互操作
``` scala
val command = ArrayBuffer("ls","-al")
val pb = new ProcessBuilder(command) // Scala到Java的转换

val cmd: Buffer[String] = pb.command() // Java到Scala的转换
```

# L、练习
```scala
package com.zhaoyi.ch3

import java.util.TimeZone

import scala.util.Random

object Practice {

  // 练习1：编写一段代码，将a设置为n个随机整数组成的数组，要求随机数介于[0,n)之间。
  def exercise1(n: Int): Array[Int] ={
    val random = new Random()
    // scala.collection.immutable.IndexedSeq[Int]
    val result = for (i <- 0 to n) yield random.nextInt(n)
    result.toArray
  }

  // 练习2：编写一个循环，将整数数组中的相邻的元素置换。例如，Array(1,2,3,4,5)，经过置换之后变为(2,1,4,3,5)
  def exercise2(arr: Array[Int]): Array[Int] ={
    for (i <- 0 until arr.length - 1 by 2){
      // 相邻元素交换之
      val temp = arr(i);
      arr(i) = arr(i + 1);
      arr(i + 1) = temp;
    }
    arr
  }

  // 练习3：重复前一个练习，不过这一次生成一个新的值交换过的数组，使用 for/yield
  def exercise3(arr: Array[Int]): Array[Int] ={
    val newArr = for (i <- 0 until arr.length) yield {
      // 如果当前是置换对的第二个元素，那么当前位置的元素一定是旧数组的上一个元素
      if(i % 2 == 1){
        arr(i-1)
      } else{// 若这是置换对的第一个元素，那么他的值需要考虑两种情况：后面有没有元素：有的话，返回后面一个元素；没有的话，返回自己即可
        if(i == arr.length - 1) arr(i) else arr(i + 1)
      }
    }
    newArr.toArray
  }

  // 练习4：给定一个整数数组，产出一个新的数组，包含原数组中的所有正值，以原有的顺序输出；之后的元素所有的0和负值，以原有的顺序排列。
  def exercise4(arr: Array[Int]): Array[Int] ={
    arr.filter(num => num > 0).map(a => a) ++ arr.filter(num => num <= 0).map(a => a)
  }

  // 练习5：如何计算Array[Double]的平均值
  def exercise5(arr: Array[Double]): Double ={
    arr.sum / arr.length
  }

  // 练习6：如何重新组织Array[Int]的元素将他们以反序排列？对于ArrayBuffer[Int]又该怎么做呢？
  // 解答：Array[Int]可以直接调用sorted方法排序；而对于ArrayBuffer，则需要使用sortWith

  // 练习7：给定一个数组，产出数组中的所有值，去掉重复项。
  def exercise7(arr:Array[Int]): Array[Int] = {
    arr.distinct
  }

  // 练习8：给定一个缓冲数组，移除该数组除第一次出现的负数以外的所有负数。
  def exercise8(arr:Array[Int]): Array[Int] = {
    var first = true;
    arr.filter(num => {
      if(num >= 0 ) true
      else {
        if(first) {
          first = false
          true
        }else false
      }
    });
  }

  // 练习9：跳过

  // 练习10：创建一个由java.util.TimeZone.getAvailableIds返回的时区集合，判断条件是他们在美洲，去掉America/前缀并排序
  def exercise10(): Unit = {
    val prefix = "America/";
    val timeZone = TimeZone.getAvailableIDs();
    val AmericaZones = for (zone <- timeZone if zone.startsWith(prefix)) yield {
      // 去掉前缀America/
      zone.substring(prefix.length);
    }
    val soredZone = AmericaZones.sorted
    soredZone.foreach(z => println(z));
  }


  def main(args: Array[String]): Unit = {
    println("exercise 1(n = 10): " + exercise1(10).mkString(","))
    println("exercise 2(Array(1,2,3,4,5)): " + exercise2(Array(1,2,3,4,5)).mkString(","))
    println("exercise 3(Array(1,2,3,4,5)): " + exercise3(Array(1,2,3,4,5)).mkString(","))
    println("exercise 4(Array(-1,2,-3,4,5,0)): " + exercise3(Array(-1,2,-3,4,5,0)).mkString(","))
    println("exercise 5(Array(1,2,3,4,5,6,7,8,9,10)) mean is : " + exercise5(Array(1,2,3,4,5,6,7,8,9,10)))

    println("exercise 7(Array(1,1,2,2,2,3,3,4)) distinct is: " + exercise7(Array(1,1,2,2,2,3,3,4)).mkString(","))

    println("exercise 8(Array(5,4,3,2,1,0,-1,-2,-3,1,2,-1,-2)): " + exercise8(Array(5,4,3,2,1,0,-1,-2,-3,1,2,-1,-2)).mkString(","))

    println("exercise 10: " + exercise10())

  }
}
```





