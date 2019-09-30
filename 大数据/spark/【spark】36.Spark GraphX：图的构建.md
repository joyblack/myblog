# 简介
前面讲解了图的基本组件，接下来我们学习如何在应用程序中构建图。

# 1、构建图
构建图的过程很简单，分为三步，它们分别是：
1. 构建边EdgeRDD
2. 构建顶点VertexRDD
3. 生成Graph对象。

下面分别介绍这三个步骤。

## 1.1、构建边EdgeRDD
1、对于`RDD[Edge[ED]]`这种版本：
```scala
val relationships: RDD[Edge[String]] = sc.parallelize(Array(Edge(3L, 7L, "collab"),    Edge(5L, 3L, "advisor"),Edge(2L, 5L, "colleague"), Edge(5L, 7L, "pi")))
```

2、对于`EdgeRDD[ED]`这种版本：也是边的优化版本。
```scala
val relationships1:EdgeRDD[String] = EdgeRDD.fromEdges(relationships)
```

## 1.2、构建顶点
1、对于`RDD[(VertexId, VD)]`这种版本：
```scala
val users: RDD[(VertexId, (String, String))] = sc.parallelize(Array((3L, ("rxin", "student")), (7L, ("jgonzal", "postdoc")),(5L, ("franklin", "prof")), (2L, ("istoica", "prof"))))
```

2、对于`VertexRDD[VD]`这种版本：是上面版本的优化版本。
```scala
val users1:VertexRDD[(String, String)] = VertexRDD[(String, String)](users)
```

## 1.3、构建Graph对象
使用上述构建的edgeRDD和vertexRDD，通过
```scala
new GraphImpl(vertices, new ReplicatedVertexView(edges.asInstanceOf[EdgeRDDImpl[ED, VD]])) 
```
就可以生成Graph对象。ReplicatedVertexView是点和边的视图，用来管理运送(shipping)顶点属性到EdgeRDD的分区。当顶点属性改变时，我们需要运送它们到边分区来更新保存在边分区的顶点属性。 

> 注意，在ReplicatedVertexView中不要保存一个对边的引用，因为在属性运送等级升级后，这个引用可能会发生改变。

```scala
class ReplicatedVertexView[VD: ClassTag, ED: ClassTag](var edges: EdgeRDDImpl[ED, VD], var hasSrcId: Boolean = false, var hasDstId: Boolean = false)
```


# L、总结
=== 1、构建顶点的方式 ===

1、对于`RDD[(VertexId, VD)]`这种版本：
```scala
val users: RDD[(VertexId, (String, String))] = sc.parallelize(Array((3L, ("rxin", "student")), (7L, ("jgonzal", "postdoc")),(5L, ("franklin", "prof")), (2L, ("istoica", "prof"))))
```

2、对于`VertexRDD[VD]`这种版本：是上面版本的优化版本。
```scala
val users1:VertexRDD[(String, String)] = VertexRDD[(String, String)](users)
```
也就说将第一个版本的对象作为参数传入构建VertexRDD的构建方式，VertexRDD是`RDD[(VertexId, VD)]`的一个子类。

=== 2、构建边的方式 ===

1、对于`RDD[Edge[ED]]`这种版本：
```scala
val relationships: RDD[Edge[String]] = sc.parallelize(Array(Edge(3L, 7L, "collab"),    Edge(5L, 3L, "advisor"),Edge(2L, 5L, "colleague"), Edge(5L, 7L, "pi")))
```

2、对于`EdgeRDD[ED]`这种版本：也是边的优化版本。
```scala
val relationships1:EdgeRDD[String] = EdgeRDD.fromEdges(relationships)
```

=== 3、对于图的构建 ===
1、通过Graph类的apply方法进行构建：`Graph[VD: ClassTag, ED: ClassTag]`
```scala
val graph = Graph(vertices,edges);
```

2、通过Graph类提供fromEdges方法来构建，对于顶点的属性是使用提供的默认属性。
```scala
val graph2 = Graph.fromEdges(relationships,defaultUser)
```

3、通过Graph类提供的fromEdgeTuples方法类构建，对于顶点的属性是使用提供的默认属性，对于边的属性是相同边的数量。
```scala
val relationships: RDD[(VertexId,VertexId)] = sc.parallelize(Array((3L, 7L),(5L, 3L),(2L, 5L), (5L, 7L)))
      val graph3 = Graph.fromEdgeTuples[(String,String)](relationships,defaultUser)
```