# 基础镜像
FROM centos:7

# 作者
MAINTAINER rong.jia 852203465@qq.com

# 环境变量
ENV FASTDFS_PATH=/opt/fdfs \
    FASTDFS_BASE_PATH=/var/fdfs \
    LIBFASTCOMMON_VERSION=V1.0.47 \
    FASTDFS_NGINX_MODULE_VERSION=V1.22 \
    FASTDFS_VERSION=V6.07 \
    NGINX_VERSION="1.18.0" \
    NGINX_PORT=8080 \
    PORT= \
    GROUP_NAME= \
    TRACKER_SERVER= \
    GROUP_COUNT= \
    SSH_PASSWORD= 

# 安装依赖
RUN yum install -y git gcc make wget pcre pcre-devel zlib zlib-devel perl openssh-server net-tools

# 创建目录
RUN mkdir -p ${FASTDFS_PATH}/libfastcommon \
    && mkdir -p ${FASTDFS_PATH}/fastdfs \
    && mkdir -p ${FASTDFS_PATH}/fastdfs-nginx-module \
    && mkdir -p ${FASTDFS_BASE_PATH} \
    && mkdir -p ${FASTDFS_PATH}/nginx \
    && mkdir -p /root/.ssh

#compile the libfastcommon
WORKDIR ${FASTDFS_PATH}/libfastcommon

RUN git clone -b ${LIBFASTCOMMON_VERSION} --depth=1 https://github.com/happyfish100/libfastcommon.git ${FASTDFS_PATH}/libfastcommon \
    && ./make.sh \
    && ./make.sh install

#compile the fastdfs
WORKDIR ${FASTDFS_PATH}/fastdfs

RUN git clone -b ${FASTDFS_VERSION} --depth=1 https://github.com/happyfish100/fastdfs.git ${FASTDFS_PATH}/fastdfs \
    && ./make.sh \
    && ./make.sh install

#compile the nginx
WORKDIR ${FASTDFS_PATH}/nginx

RUN git clone -b ${FASTDFS_NGINX_MODULE_VERSION} --depth=1 https://github.com/happyfish100/fastdfs-nginx-module.git \
    && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxvf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure --prefix=/usr/local/nginx --add-module=${FASTDFS_PATH}/nginx/fastdfs-nginx-module/src \
    && make

WORKDIR /root

RUN cd ${FASTDFS_PATH}/libfastcommon \
    && ./make.sh install \
    && cd ${FASTDFS_PATH}/fastdfs \
    && ./make.sh install \
    && cd ${FASTDFS_PATH}/nginx/nginx-${NGINX_VERSION} \
    && make install \
    && rm -rf ${FASTDFS_PATH}/*

# ssh
#修改/etc/ssh/sshd_config
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
ADD ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
ADD ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub
ADD authorized_keys /root/.ssh/authorized_keys

EXPOSE 22122 23000 ${NGINX_PORT} 22
VOLUME ["$FASTDFS_BASE_PATH", "/etc/fdfs","usr/local/nginx/conf"]

COPY conf/*.* /etc/fdfs/

COPY conf/nginx.conf /usr/local/nginx/conf/

COPY start.sh /usr/bin/

#make the start.sh executable
RUN chmod 777 /usr/bin/start.sh

# 设置工作目录为nginx目录
WORKDIR /usr/local/nginx

ENTRYPOINT ["/usr/bin/start.sh"]
CMD ["tracker"]
















