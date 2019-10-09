# 简介
本章节进行一个案例，主要是数据处理的一个典型代表——多表合并。

# 1、需求
需求：当前图书馆有两个文件，分别对应书籍记录以及订单记录，目前想要将两个文件合并为1个。

## 1.1、数据文件
1、文件一参见项目根目录book_index.txt文件，分别代表书籍的编号、书籍名称
```
1001    灰与幻想的格林姆迦尔
1002    FATE GRAND ORDER
1003    FATE STAY NIGHT
1007    香水
1006    活着
1005    Maven实战
1004    来自新世界
```

2、文件二参见根目录的book_order.txt文件，分别代表订单编号、书籍ID以及购买数量
```
20150901    1001    50
20160429    1002    700
20151201    1006    80
20191002    1007    120
20170523    1003    23
20180604    1004    56
20160922    1005    70
```

## 1.2、输出需求
需要合并出来的结果：将订单表中的书籍ID替换为书籍名称。即：
```
20150901	灰与幻想的格林姆迦尔	50
20160429	FATE GRAND ORDER	700
20170523	FATE STAY NIGHT	23
20180604	来自新世界	56
20160922	Maven实战	70
20151201	活着	80
20191002	香水	120
```

# 2、处理方式一：reducer端合并

> 代码参见项目table-combine.

通过将关联条件作为map输出的key，将两表满足join条件的数据并携带数据所来源的文件信息，发往同一个reduce task，在reduce中进行数据的串联。

（1）序列化Bean
```java
package com.zhaoyi.table.combine;

import org.apache.hadoop.io.Writable;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

public class BookBean implements Writable {
    private String bookId;
    private String bookName;
    private String orderId;
    // 订单中对应书籍的购买数量
    private Integer buyNum;
    // 标记数据来源 book or order?
    private String beanSource;

    public BookBean() {
    }

    public BookBean(String bookId, String bookName, String orderId, Integer buyNum, String beanSource) {
        this.bookId = bookId;
        this.bookName = bookName;
        this.orderId = orderId;
        this.buyNum = buyNum;
        this.beanSource = beanSource;
    }

    @Override
    public String toString() {
        return orderId + '\t' + bookName + '\t' + buyNum;
    }

    public void write(DataOutput out) throws IOException {
        out.writeUTF(bookId);
        out.writeUTF(bookName);
        out.writeUTF(orderId);
        out.writeInt(buyNum);
        out.writeUTF(beanSource);
    }

    public void readFields(DataInput in) throws IOException {
        this.bookId = in.readUTF();
        this.bookName = in.readUTF();
        this.orderId = in.readUTF();
        this.buyNum = in.readInt();
        this.beanSource = in.readUTF();
    }

    public String getBookId() {
        return bookId;
    }

    public void setBookId(String bookId) {
        this.bookId = bookId;
    }

    public String getBookName() {
        return bookName;
    }

    public void setBookName(String bookName) {
        this.bookName = bookName;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public Integer getBuyNum() {
        return buyNum;
    }

    public void setBuyNum(Integer buyNum) {
        this.buyNum = buyNum;
    }

    public String getBeanSource() {
        return beanSource;
    }

    public void setBeanSource(String beanSource) {
        this.beanSource = beanSource;
    }
}
```
（2）Mapper
```java
package com.zhaoyi.table.combine;

import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;

import java.io.IOException;

public class BookMapper extends Mapper<LongWritable, Text, Text, BookBean> {
    BookBean bookBean = new BookBean();
    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        String line = value.toString();

        String[] strings = line.split("\t");

        // 区分不同的文件来源
        FileSplit inputSplit = (FileSplit)context.getInputSplit();

        // 根据两个文件的不同区分处理
        if(inputSplit.getPath().getName().startsWith(BeanSource.PREFIX_BOOK_FILE)){
            bookBean.setBeanSource("book_index");
            bookBean.setBookId(strings[0]);
            bookBean.setBookName(strings[1]);
            bookBean.setBuyNum(0);
            bookBean.setOrderId("0");
        }else{
            bookBean.setBeanSource("book_order");
            bookBean.setOrderId(strings[0]);
            bookBean.setBookId(strings[1]);
            bookBean.setBuyNum(Integer.valueOf(strings[2]));
            bookBean.setBookName("");
        }
        // 以书籍ID作为排序
        context.write(new Text(bookBean.getBookId()), bookBean);
    }
}
```
> FileSplit inputSplit = (FileSplit)context.getInputSplit();用于获取分片信息。我们这里是不同的小文件，可以据此获取输入文件的信息是属于书籍文件还是订单文件。

（3）Reducer
```java
package com.zhaoyi.table.combine;

import org.apache.commons.beanutils.BeanUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.List;

public class BookReducer extends Reducer<Text, BookBean, BookBean, NullWritable> {
    @Override
    protected void reduce(Text key, Iterable<BookBean> values, Context context) throws IOException, InterruptedException {
        List<BookBean> orderBeans = new ArrayList();
        String bookName = "书籍名称";
        for (BookBean value : values) {
            if(BeanSource.PREFIX_BOOK_FILE.equals(value.getBeanSource())){
                bookName = value.getBookName();
            }else{// order table
                // 保存每一条订单信息
                BookBean temp = new BookBean();
                try {
                    // copy bean.
                    BeanUtils.copyProperties(temp, value);
                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                } catch (InvocationTargetException e) {
                    e.printStackTrace();
                }
                orderBeans.add(temp);
            }
        }
        // 拼接双标并写入数据
        for (BookBean data : orderBeans) {
            data.setBookName(bookName);
            context.write(data,NullWritable.get());
        }
    }
}
```
（4）Driver
```java
package com.zhaoyi.table.combine;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;

public class BookDriver {
    public static void main(String[] args) throws Exception {
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(BookDriver.class);
        job.setMapperClass(BookMapper.class);
        job.setReducerClass(BookReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(BookBean.class);
        job.setOutputKeyClass(BookBean.class);
        job.setOutputValueClass(NullWritable.class);

        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true)? 1:-1);
    }
}
```
（5）辅助文件标志类
```java
package com.zhaoyi.table.combine;

public class BeanSource {
    public static final String PREFIX_BOOK_FILE = "book_index";
    public static final String PREFIX_ORDER_FILE = "book_order";
}
```

运行项目即可，如果需要输出更多的数据，可以通过toString()方法修改所需要输出的数据。
```
20150901	灰与幻想的格林姆迦尔	50
20160429	FATE GRAND ORDER	700
20170523	FATE STAY NIGHT	23
20180604	来自新世界	56
20160922	Maven实战	70
20151201	活着	80
20191002	香水	120
```

观察代码我们可以发现，订单表如果过大，reducer的压力真的太大了。这就是数据倾斜。

# 3、数据倾斜
如果是多张表的操作都是在reduce阶段完成，reduce端的处理压力太大，map节点的运算负载则很低，资源利用率不高，且在reduce阶段极易产生数据倾斜。

## 3.1、解决方案
在map端缓存多张表，提前处理业务逻辑，这样增加map端业务，减少reduce端数据的压力，尽可能的减少数据倾斜。

## 3.2、具体办法
采用distributedcache
* 在mapper的setup阶段，将小文件读取到缓存集合中
* 在驱动函数中加载缓存。
* 在驱动类中加载文件到task运行节点

```
job.addCacheFile(new URI("file:/yourFilePath"));// 缓存普通文件到task运行节点
```

观察Mapper类源码，我们可以将处理缓存文件的过程放置在Setup方法中
```java
    public void run(Mapper<KEYIN, VALUEIN, KEYOUT, VALUEOUT>.Context context) throws IOException, InterruptedException {
        this.setup(context);

        try {
            while(context.nextKeyValue()) {
                this.map(context.getCurrentKey(), context.getCurrentValue(), context);
            }
        } finally {
            this.cleanup(context);
        }
    }
```



## 3.2、优化项目
接下来我们针对order项目进行优化，具体代码详见模块order2.

现在我们先来看看，连接表的书籍文件比较小，因此我们可以考虑将其缓存到工作目录，直接从Mapper阶段进行连接，提升整体运行的效率。

（1）在Driver中缓存book_index.txt文件到工作目录
```java
package com.zhaoyi.order2;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.net.URI;

public class DriverOrder2 {
    public static void main(String[] args) throws Exception{
        Job job = Job.getInstance(new Configuration());

        job.setJarByClass(DriverOrder2.class);
        job.setMapperClass(Order2Mapper.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NullWritable.class);

        job.addCacheFile(new URI("file:/D:/hadoop/book_index.txt"));

        FileInputFormat.setInputPaths(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));
        System.exit(job.waitForCompletion(true)?1:-1);

    }
}

```

2、直接编写Mapper即可
```java
package com.zhaoyi.order2;

import com.sun.javafx.binding.StringFormatter;
import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class Order2Mapper extends Mapper<LongWritable, Text, Text, NullWritable> {

    private HashMap<String,String> books = new HashMap<>();

    @Override
    protected void setup(Context context) throws IOException {
        Files.lines(Paths.get(context.getCacheFiles()[0])).forEach(
                s -> {
                    String[] strings = s.split("\t");
                    // bookId and bookName
                    books.put(strings[0].trim(),strings[1]);
                }
        );
    }

    @Override
    protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
        // 接下来只需拼接书的名字到最后就可以了
        String line = value.toString();
        String[] params = line.split("\t");
        // 获取书籍ID
        String bookId = params[1];

        // 获取当前对应的书籍名称
        String bookName = books.get(bookId);

        System.out.println(bookId == "1001");
        System.out.println(bookName);

        // 输出  orderId bookName buyNum
        context.write(new Text(String.format("%s\t%s\t%s", params[0], bookName, params[2])),NullWritable.get());
    }
}

```



运行结果和之前的一致。
```
20150901	灰与幻想的格林姆迦尔	50
20151201	活着	80
20160429	FATE GRAND ORDER	700
20160922	Maven实战	70
20170523	FATE STAY NIGHT	23
20180604	来自新世界	56
20191002	香水	120
```

> 注意将book_index.txt文件移出input目录，现在已经不需要读取他的值，而由我们的setup方法发一次处理了。

> 使用BOM形式保存的文件使用IO读取注意一下，可能会出现意想不到的错误。
