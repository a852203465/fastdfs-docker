# FastDFS Docker

## 1. Usage:

 `docker build -t registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0 .`
or
 `docker pull registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0`

## 2. FastDFS 部署

### 2.1  docker 主机模式
    
#### 2.1.1 stand-alone
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: tracker
    network_mode: host
    environment:
      - PORT=22122
    volumes:
      - .fdfs/tracker:/var/fdfs
  storage0:
    container_name: storage0
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: storage
    network_mode: host
    environment:
      - TRACKER_SERVER=ip:22122
      - PORT=23000
      - NGINX_PORT=8080
    volumes:
      - ./fdfs/storage0:/var/fdfs
```

#### 2.1.2 cluster
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: tracker
    network_mode: host
    environment:
      - PORT=22122
    volumes:
      - .fdfs/tracker:/var/fdfs

  # 130.13
  storage0:
    container_name: storage0
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: storage
    network_mode: host
    environment:
      - TRACKER_SERVER=ip:22122
      - PORT=23000
      - NGINX_PORT=8080
    volumes:
      - ./fdfs/storage0:/var/fdfs
  # 130.14
  storage1:
    container_name: storage1
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: storage
    network_mode: host
    environment:
      - TRACKER_SERVER=ip:22122
      - PORT=23000
      - NGINX_PORT=8080
    volumes:
      - ./fdfs/storage0:/var/fdfs
```

### 2.2 docker 容器网络模式

 - 使用docker 容器网络模式部署 fastdfs cluster/stand-alone 增加，减少容器即可
 - 方便访问集群中的图片，因此运行一个nginx 对所有的存储节点文件访问进行代理

#### 2.2.1 cluster
```yaml
version: '3'
services:
  proxy:
    image: nginx:1.14
    container_name: fdfs-proxy
    restart: always
    ports:
      - 9099:80
    volumes:
      - ./proxy:/etc/nginx/conf.d
      - ./logs:/var/log/nginx
    networks:
      - fastdfs_net

  tracker:
    container_name: tracker
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: tracker
    ports:
      - 22122:22122
    volumes:
      - ./fdfs/tracker:/var/fdfs
    networks:
      - fastdfs_net

  storage0:
    container_name: storage0
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: storage
    expose:
      - 8080
    ports:
      - 23000:23000
    environment:
      - TRACKER_SERVER=192.168.178.128:22122
      - GROUP_NAME=group1
      - PORT=23000
      - GROUP_COUNT=2
    volumes:
      - ./fdfs/storage0:/var/fdfs
    networks:
      - fastdfs_net

  storage1:
    container_name: storage1
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: storage
    expose:
      - 8080
    ports:
      - 23001:23001
    environment:
      - TRACKER_SERVER=192.168.178.128:22122
      - GROUP_COUNT=2
      - GROUP_NAME=group2
      - PORT=23001
    volumes:
      - ./fdfs/storage1:/var/fdfs
    networks:
      - fastdfs_net

networks:
  fastdfs_net:
    external: true

```
#### 2.3 monitor

`docker run -ti --network=host --name monitor -e TRACKER_SERVER=192.168.1.127:22122 registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0 monitor`

#### 2.4 ssh
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: registry.cn-shenzhen.aliyuncs.com/a852203465/fastdfs:1.0
    command: tracker
    network_mode: host
    ports:
      - 2222:22
      - 22122:22122
    environment:
      - PORT=22122
      - SSH_PASSWORD=123456
    volumes:
      - ./fdfs/tracker:/var/fdfs

```

## 3. 注意
    
### 1. docker安装fastdfs碰到storage的IP地址映射宿主地址问题 
 由于使用容器网络模式运行fastdfs client端 上传文件时会提示找不到存储节点，因此需要在client处理该问题
   
 - 客户端处理：
   该问题在java版本的com.github.tobato.fastdfs-client的jar中处理了该问题
 - 服务端处理：
    - 数据达到172.30.0.4的22122端口记录的源地址是 172.30.0.1，我们只需要修改iptables的NAT表规则，
        所有转发到172.30.0.4:22122的数据，源地址修改为宿主主机的地址：192.168.178.128，
        这样storage注册到tracker server时，tracker server获取到storage的ip地址为 192.168.178.128 
        而不是网关地址172.30.0.1
    - 使用iptables -L -t nat 查看22122端口的容器IP
    - 添加 iptables -t nat -A POSTROUTING -p tcp -m tcp --dport 22122 -d 172.30.0.4 -j SNAT --to 192.168.178.128 
    - 删除 iptables -t nat -D POSTROUTING 7(第几条)
    - 重启容器 （一定要）
    - 使用iptables -L -t nat 查看nat表规则
    - 重新执行fastdfs-client-java的工程，返回的storage的地址为 192.168.178.128 

### 2. tail: cannot open '/var/fdfs/logs/storaged.log' for reading: No such file or directory
    - 手动创建 vi /var/fdfs/logs/storaged.log 文件即可
 
 
 



