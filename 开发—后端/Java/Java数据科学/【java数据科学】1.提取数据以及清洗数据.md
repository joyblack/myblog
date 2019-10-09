# 简介
该系列主要总结了使用java处理数据过程中使用到的工具以及一些可以起到启发性的代码。通过本章节你可以学习到：
* 如何递归遍历文件目录
* 如何访问各种各样的数据源
  
# 1、遍历文件
## 1.1、使用基本方法列出目录下的所有文件
```java
import java.io.File;
import java.util.HashSet;
import java.util.Set;

public class ListFilesWithSimple {
    public static void main(String[] args) {
        // 1.使用java从分层目录中提取所有文件名
        Set<File> files = ListFilesWithSimple.listFiles(new File("D:/hadoop"));
        for (File file : files) {
            System.out.println(file.getPath());
        }
    }

    // 1. 从分层目录中提取所有文件名(注意不包含文件夹)
    public static Set<File> listFiles(File rootDir){
        Set<File> fileSet = new HashSet<File>();
        // when file is null or file is not a directory.
        if(rootDir == null || rootDir.listFiles() == null){
            return fileSet;
        }
        for (File file : rootDir.listFiles()) {
            if(file.isFile()){
                fileSet.add(file);
            }else{
                fileSet.addAll(listFiles(file));
            }
        }
        return fileSet;
    }
}
```

## 1.2、使用Apache Commons IO 从多层目录中提取所有文件
引入依赖
```xml
<!-- https://mvnrepository.com/artifact/commons-io/commons-io -->
<dependency>
    <groupId>commons-io</groupId>
    <artifactId>commons-io</artifactId>
    <version>2.6</version>
</dependency>
```
```java
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.filefilter.TrueFileFilter;

import java.io.File;
import java.util.List;

public class ListFilesWithCommonIo {
    public static void main(String[] args) {
        List<File> files = ListFilesWithCommonIo.listFiles(new File("D:/hadoop"));
        for (File file : files) {
            System.out.println(file.getAbsolutePath());
        }

    }

    public static List<File> listFiles(File rootDir){
        return (List<File>)FileUtils.listFiles(rootDir, TrueFileFilter.INSTANCE, TrueFileFilter.INSTANCE);
        // 若需要返回目录
        //return (List<File>)FileUtils.listFilesAndDirs(rootDir, TrueFileFilter.INSTANCE, TrueFileFilter.INSTANCE);
    }
}
```
# 2、读取内容
## 2.1、使用java8按行读取
```java
package read;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.stream.Stream;

public class Java8Read {
    public static void main(String[] args) {
        // 文件
        String file = "锦瑟.poetry";
        try {
            Stream<String> lines = Files.lines(Paths.get(file));
            // 显示每一行数据
            lines.forEach(line -> System.out.println(line));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

## 2.2、使用Commons IO一次性读取
```java
package read;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;

public class CommonIORead {
    public static void main(String[] args) {
        String file = "天净沙-秋思.poetry";
        try {
            String content = FileUtils.readFileToString(new File(file), "UTF-8");
            System.out.println(content);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

## 2.3、使用Apache Tika提取PDF文本
导入依赖
```xml
<dependency>
    <groupId>org.apache.tika</groupId>
    <artifactId>tika-parsers</artifactId>
    <version>1.20</version>
</dependency>
```
```java
package read;

import org.apache.tika.metadata.Metadata;
import org.apache.tika.parser.AutoDetectParser;
import org.apache.tika.parser.ParseContext;
import org.apache.tika.sax.BodyContentHandler;

import java.io.FileInputStream;
import java.io.InputStream;

public class TiKaRead {
    public static void main(String[] args) {
        String content = readPDF("他不懂.pdf");
        System.out.println(content);
    }

    public static String readPDF(String fileName){
        InputStream inputStream = null;
        String content = "";
        try {
            inputStream = new FileInputStream(fileName);
            // 创建一个自动解析器
            AutoDetectParser parser = new AutoDetectParser();
            // 使用-1表示不对文件内容的大小进行限制
            BodyContentHandler handler = new BodyContentHandler(-1);
            Metadata metaData = new Metadata();
            parser.parse(inputStream, handler, metaData, new ParseContext());
            System.out.println(metaData);
            // 调用Handler对象的toString获取正文内容
            content = handler.toString();
        } catch (Exception e) {
            e.printStackTrace();
        }finally {
            if(inputStream != null){
                try{
                    inputStream.close();
                }catch (Exception e){
                    System.out.println("Error Closing input stream.");
                }
            }
        }
        return content;
    }
}
```

# 3、清洗文件
## 3.1、使用正则表达式清洗ASCII文本
```java
package filter;

import com.sun.media.jfxmedia.track.Track;

import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;

public class FilterASCII {
    public static void main(String[] args) {
        try {
            System.out.println(cleanText("this s a 赵义    text."));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static String cleanText(String text){
        // 1.去除所有非ASCII字符
        text = text.replaceAll("[^\\p{ASCII}]","");
        // 2.去除多余的空格
        text = text.replaceAll("\\s+"," ");
        // 3.清除ASCII控制字符
        text = text.replaceAll("[\\p{Cntrl}]","");
        // 4.清除非打印字符
        text = text.replaceAll("[^\\p{Print}]","");
        return text;
    }
}
```
# 4、解析文件
## 4.1、使用Univocity解析CSV文件
引入依赖
```xml
<dependency>
    <groupId>com.univocity</groupId>
    <artifactId>univocity-parsers</artifactId>
    <version>2.8.1</version>
</dependency>
```
有很多采用Java编写的csv文件解析器。不过，Univocity是相对比较快的一种。
```java
package parser;

import com.univocity.parsers.common.processor.RowListProcessor;
import com.univocity.parsers.csv.CsvParser;
import com.univocity.parsers.csv.CsvParserSettings;

import java.io.File;
import java.util.Arrays;
import java.util.List;


public class UnivocityTest {
    public static void main(String[] args) throws Exception{
        String fileName = "模块表.csv";
        parseCSV(fileName);
    }

    public static void parseCSV(String fileName) throws Exception {
        // 创建一个配置对象，并配置
        CsvParserSettings csvParserSettings = new CsvParserSettings();
        // 自动检测输入中的分隔符序列
        csvParserSettings.setLineSeparatorDetectionEnabled(true);
        // 指定把每个解析的行存储在列表中，写入配置：使用rowListProcessor配置解析器，用来对每个解析行的值进行处理
        RowListProcessor processor = new RowListProcessor();
        csvParserSettings.setProcessor(processor);
        // 若CSV文件包含标题头，则可以把第一行看做文件中每个列的标题;否则无需设置。
        //csvParserSettings.setHeaderExtractionEnabled(true);
        // 使用给定的配置创建一个parser实例
        CsvParser csvParser = new CsvParser(csvParserSettings);
        csvParser.parse(new File(fileName));

        // 默认将第一行看做头
        String[] headers = processor.getHeaders();
        System.out.println(Arrays.asList(headers));

        List<String[]> rows = processor.getRows();
        for (String[] row : rows) {
            System.out.println(Arrays.asList(row));
        }
    }
}
```

## 4.2、使用Univocity解析TSV文件
TSV和CSV几乎是同一类文件，只不过是TAB分隔不同列。
```java
package parser;

import com.univocity.parsers.tsv.TsvParser;
import com.univocity.parsers.tsv.TsvParserSettings;

import java.io.File;
import java.util.Arrays;
import java.util.List;


public class UnivocityTest2 {
    public static void main(String[] args) {
        String fileName = "模块表.tsv";
        parseTSV(fileName);
    }

    public static void parseTSV(String fileName){
        // 创建一个配置对象，并配置
        TsvParserSettings settings = new TsvParserSettings();
        // 设置行分隔符
        settings.getFormat().setLineSeparator("\n");
        // 使用配置创建一个parser
        TsvParser parser = new TsvParser(settings);
        // 将文件内容一次性解析出来
        List<String[]> rows = parser.parseAll(new File(fileName));
        for (String[] row : rows) {
            System.out.println(Arrays.asList(row));
        }

    }
}
```

## 4.3、使用JDOM解析XML文件
导入依赖
```xml
<!-- https://mvnrepository.com/artifact/org.jdom/jdom2 -->
<dependency>
    <groupId>org.jdom</groupId>
    <artifactId>jdom2</artifactId>
    <version>2.0.6</version>
</dependency>
```
```java
package parser;

import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;

import java.io.File;
import java.io.IOException;
import java.util.List;

public class JDomTester {
    public static void main(String[] args) {
        parserXML("类型.xml");
    }

    public static void parserXML(String fileName){
        File file = new File(fileName);
        SAXBuilder builder = new SAXBuilder();
        try {
            // 创建一个Document对象，代表访问的XML文件
            Document doc = builder.build(file);
            // 获取根元素
            Element rootEle = doc.getRootElement();
            // 获取根元素下的所有数据
            List<Element> records = rootEle.getChildren("RECORD");
            // 遍历节点
            for (Element record : records) {
                System.out.println("====== record ======");
                System.out.println("id:" + record.getChildText("type_id"));
                System.out.println("name:" + record.getChildText("type_name"));
                System.out.println("state:" + record.getChildText("state"));
                System.out.println("create time:" + record.getChildText("create_time"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

## 4.4、使用JSON.simple与JSON文件交互（写入和读取）
引入依赖
```xml
<!-- https://mvnrepository.com/artifact/com.googlecode.json-simple/json-simple -->
<dependency>
    <groupId>com.googlecode.json-simple</groupId>
    <artifactId>json-simple</artifactId>
    <version>1.1.1</version>
</dependency>
```

```java
package parser;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import java.io.FileReader;
import java.io.FileWriter;

public class JsonTester {
    public static void main(String[] args) throws Exception{
        String fileName = "书籍.json";
        writeJSONFile(fileName);
        readJSONFile(fileName);
    }

    public static void writeJSONFile(String fileName){
        // 创建JSON对象
        JSONObject obj = new JSONObject();
        obj.put("name","来自新世界");
        obj.put("author","贵志佑介");
        obj.put("introduce", "一部畅想未来的架空世界观的小说，不同于大多数科幻作品的风格，作者对未来展现的不是高科技时代，而是看起来甚至是比现在还要倒退一千年的时代...");
        // 添加3个书籍评论
        JSONArray comments = new JSONArray();
        comments.add("这是一本可以打满分的书。");
        comments.add("这是一本可以打90分的书。");
        comments.add("这是一本一般般的书。");
        obj.put("comments", comments);

        // 写入json文件
        FileWriter writer = null;
        try {
            writer = new FileWriter(fileName);
            System.out.println(obj.toJSONString());
            writer.write(obj.toJSONString());
            writer.flush();
            writer.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void readJSONFile(String fileName) throws Exception {
        // 创建一个JSON解析器
        JSONParser parser = new JSONParser();
        // 解析
        JSONObject object = (JSONObject)parser.parse(new FileReader(fileName));

        System.out.println("====== book info =======");
        System.out.println("name:" + object.get("name"));
        System.out.println("author:" + object.get("author"));
        System.out.println("introduce:" + object.get("introduce"));
        System.out.println("comments:" + object.get("comments"));
    }
}
```
还有一个工具包叫做fastjson，同样是google出品。

## 4.5、使用JSoup从一个URL中提取Web数据
jsoup是一个不错的解析工具，其解析速度非常之快。究其原因，主要是不需要对网页进行动态解析，也不支持对网页就行任何动态操作，而是直接解析第一次访问获得的内容。因此，在使用jsoup的时候如果有其他需求，例如想要调用按钮点击事件、触发远程调用等，应该考虑使用其他的工具，例如python一个很出名的爬虫框架**selenium**，该工具在java也有一个对应的工具包。

引入依赖
```xml
<!-- https://mvnrepository.com/artifact/org.jsoup/jsoup -->
<dependency>
    <groupId>org.jsoup</groupId>
    <artifactId>jsoup</artifactId>
    <version>1.11.3</version>
</dependency>
```

```java
package parser;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import java.io.IOException;

public class JSoupTester {
    public static void main(String[] args) {
        extractDataByJSoup("https://www.baidu.com/");
    }

    public static void extractDataByJSoup(String url){
        try {
            Document doc = Jsoup.connect(url).timeout(10 * 1000).ignoreHttpErrors(true).get();
            if(doc == null){
                System.out.println("This url is null.");
                return;
            }
            // 提取网址标题
            System.out.println("====== The Web Info ======");
            System.out.println("title:" + doc.title());
            // 提取正文内容
            System.out.println("body content:" + doc.body().text());
            // 获取所有超链接：css选择器的写法
            System.out.println("all href:" + doc.select("a[href]"));

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```
## 4.6、使用Selenium WebDriver从网站中提取Web数据
使用这些工具的时候还需要在所在的服务器上安装对应的浏览器包，这里就不一一介绍了。

# 5、从MySQL数据库读取表格数据
读取mysql数据的方式相信只要是一个开发者，都掌握了各种五花八门的方式了，甚至编写了自己的访问框架。这里我们就学习一下比较原始的访问方式，不去深究一些主流框架的使用。

引入依赖
```xml
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <version>8.0.13</version>
</dependency>
```

```java
package visit;

import com.mysql.cj.jdbc.MysqlDataSource;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class MySQLTester {
    public static void main(String[] args) throws Exception {
        visitMysqlData();
    }

    public static void visitMysqlData() throws Exception {
        MysqlDataSource dataSource = new MysqlDataSource();
        dataSource.setUser("root");
        dataSource.setPassword("your_database_password");
        // 这里输入您的数据库地址，例如本机localhost
        dataSource.setServerName("10.21.1.242");

        // 建立连接
        Connection connection = dataSource.getConnection();
        Statement statement = connection.createStatement();

        // 获取查询数据:sunrun_sdfs是库名，sdfs_user是表明
        ResultSet resultSet = statement.executeQuery("select * from sunrun_sdfs.sdfs_user limit 5");

        while (resultSet.next()){
            System.out.println("====== user info ======");
            System.out.println("id: " + resultSet.getString("user_id"));
            System.out.println("name: " + resultSet.getString("user_name"));
            System.out.println("login name: " + resultSet.getString("login_name"));
        }
        resultSet.close();
        statement.close();
        connection.close();
    }
}
```