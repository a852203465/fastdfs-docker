# FastDFS Docker

Usage:

`docker build -t a852203465/fastdfs .`
or
`docker pull a852203465/fastdfs`

# FastDFS 部署

## docker 主机模式
    
### stand-alone
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: a852203465/fastdfs
    command: tracker
    network_mode: host
    environment:
      - PORT=22122
    volumes:
      - .fdfs/tracker:/var/fdfs
  storage0:
    container_name: storage0
    image: a852203465/fastdfs
    command: storage
    network_mode: host
    environment:
      - TRACKER_SERVER=ip:22122
      - PORT=23000
      - NGINX_PORT=8080
    volumes:
      - ./fdfs/storage0:/var/fdfs
```

### cluster
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: a852203465/fastdfs
    command: tracker
    network_mode: host
    environment:
      - PORT=22122
    volumes:
      - .fdfs/tracker:/var/fdfs

  # 130.13
  storage0:
    container_name: storage0
    image: a852203465/fastdfs
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
    image: a852203465/fastdfs
    command: storage
    network_mode: host
    environment:
      - TRACKER_SERVER=ip:22122
      - PORT=23000
      - NGINX_PORT=8080
    volumes:
      - ./fdfs/storage0:/var/fdfs
```

## docker 容器网络模式

 - 使用docker 容器网络模式部署 fastdfs cluster/stand-alone 增加，减少容器即可
 - 方便访问集群中的图片，因此运行一个nginx 对所有的存储节点文件访问进行代理

### cluster
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
    image: a852203465/fastdfs
    command: tracker
    ports:
      - 22122:22122
    volumes:
      - ./fdfs/tracker:/var/fdfs
    networks:
      - fastdfs_net

  storage0:
    container_name: storage0
    image: a852203465/fastdfs
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
    image: a852203465/fastdfs
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
## monitor

`docker run -ti --network=host --name monitor -e TRACKER_SERVER=192.168.1.127:22122 a852203465/fastdfs monitor`

## ssh
```yaml
version: '3'
services:
  tracker:
    container_name: tracker
    image: a852203465/fastdfs
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


# 注意

 由于使用容器网络模式运行fastdfs client端 上传文件时会提示找不到存储节点，因此需要在client处理该问题
    - 该问题在java版本的com.github.tobato.fastdfs-client的jar中处理了该问题
  
 
 
 



