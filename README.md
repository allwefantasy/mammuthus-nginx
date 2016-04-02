# MammuthusNginx

## 前言
 
 MammuthusNginx 是一个简单的Nginx伴生组件。主要是为了实现Yarn动态调度容器时，
 动态调整Nginx负载均衡器的后端服务。
 该项目提供了Rest接口操作Nginx配置文件，
 并且进行reload的功能。目前只支持两个两个接口,主要是为负载均衡添加或者删除ip。
 未来可根据需要添加更多API.
 
 
 
## 接口说明


以如下例子说明：

```
 
   upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;    
    }
   
```

### 添加后端服务器

```
http://[dns/ip]:8001/add/servers/to/upstream?name=&ips=
```

name 参数为前面的upstream name,也就是`backend`

ips 以逗号为分隔符的ip或者域名列表，如果带上端口号，则以`:` 分割即可。
 

```
curl -XPOST http://[dns/ip]:8001/add/servers/to/upstream -d 'name=backend&ips=backup3.example.com:8080,backup4.example.com:8080'
```

则结果为：

```
 
   upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server backend3.example.com:8080;
    server backend4.example.com:8080;
}
```


## 删除后端服务器

```
http://[dns/ip]:8001/remove/servers/from/upstream?name=&ips=
```

name 参数为前面的upstream name,也就是`backend`

ips 以逗号为分隔符的ip或者域名列表，如果带上端口号，则以`:` 分割即可。

```
curl -XPOST http://[dns/ip]:8001/remove/servers/from/upstream -d 'name=backend&ips=backend2.example.com'

``` 
  
结果为：
 
```
 
   upstream backend {
    server backend1.example.com       weight=5;    
    server backend3.example.com:8080;
    server backend4.example.com:8080;
}
```  


  









