
# 简介
从本章节你可以学习到:
1. hadoop的三大运行模式的简单介绍。
2. 本地模式下的两个经典案例。

# 1、hadoop的运行模式
（1）本地模式（local(standaolne) mode）：不需要启用任何守护进程，所有程序都在同一个JVM上执行。在独立模式下测试和调试MapReduce程序都很方便，解压之后直接可以运行。非常适合我们进行测试和开发使用。

（2）伪分布式模式(Pseudo-Distributed Mode)：等同于完全分布式，但所有的守护进程只运行在一台机器上，通过启动不同的守护进程模拟集群节点。

（3）完全分布式模式(Full-Distributed Mode)：Hadoop的守护进程运行在多台机器上（集群）。

# 2、本地模式运行hadoop案例
## 2.1 grep匹配案例
grep案例是用来进行单词匹配的案例。我们按照官方教程来走一遍具体流程。

1、在hadoop-2.7.2文件下面创建一个input文件夹，并将hadoop的xml配置文件复制到里面:
```
# cd /opt/module/hadoop-2.7.2
# mkdir input
# cp etc/hadoop/*.xml input/
```
2、可以看到input目录下拥有差不多5个xml文件，现在我们想要知道在这些文件夹中究竟有多少个以dfs开头并至少还有一个其他的字母的单词，例如dfsu。只需执行官方为我们提供的参考jar包结合hadoop命令即可:
```
hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar grep input output 'dfs[a-z.]+'
```
其中:
* hadoop是bin/hadoop，由于我们之前配置的环境变量，可以直接使用
* jar后跟指定需要运行的jar包，grep在官方的share案例文件夹下面。
* grep传入参数，告诉jar包中程序运行参数为grep，使用grep模块计算
* input为输入文件夹的信息
* output为输出结果的文件夹
* 'dfs[a-z.]+' 为grep所需的正则匹配参数

3、运行之后，我们会发现在当前目录下生成了一个output文件夹，进入后发现有2个文件其中一个大小为0，表名运行是否正确，你会看到其名字为'_SUCCESS'，另外一个，就是我们想要的输出结果了。查看输出结果：
```
# cat part-r-00000
```
输出
```
1  dfsadmin
```
即匹配结果单词有'dfsadmin'，匹配次数为1次。

## 2.2 wordcount单词统计案例
接下来我们在测试一个简单的统计单词的案例，和grep案例一样，我们先构建一个输入文件夹，往里面放多个文件，随意的放入各种单词信息。

1、构建输入
```
# cd /opt/module/hadoop-2.7.2
# mkdir winput
# cd winput
# touch 1.txt
# touch 2.doc
# touch 3.xml
```
> 别忘了往文件里随便写些单词（有空格分离）

2、执行命令
```
# hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.2.jar wordcount winput/ woutput
```
* winput指定我们需要统计的输入文件夹的路径
* woutput则是输出结果的位置

3、执行完成之后，同样来到输出结果的文件夹woutput，查看统计结果：
```
beautiful	1
best	1
for	1
good	1
haha	3
is	2
item	1
learn.	1
my	1
place.	1
this	2
to	1
```
可以看到我们写入的单词的统计信息。



通过以上两个例子，相信你获得了不少经验，比如
1. 输入文件夹和输出文件夹可以随意命名，但是在运行实例的时候，要确保output处指定的文件夹不存在，否则会出错。
2. hadoop-mapreduce-examples-2.7.2.jar中包含了不少的功能案例，通过传入不同的参数提供不同的服务，例如wordcount等。
3. 确保输入路径不包含多级目录，也就是说，多个文件必须保持只在input一级目录下才行，否则也会出错。难道hadoop不支持深度遍历，当然是可以的，只不过我们需要添加参数而已，在wordcount之后添加参数`-Dmapreduce.input.fileinputformat.input.dir.recursive=true`即可。
> -Dmapreduce.input.fileinputformat.input.dir.recursive=true只在2.0之后生效。

# 参考
1. http://hadoop.apache.org/
2. https://archive.apache.org/dist/hadoop/common/hadoop-2.7.2/
3. http://hadoop.apache.org/docs/r2.7.2/