# 指定构建的基础镜像
FROM ubuntu:latest as builder
# 修改源
RUN sed -i s#http://*.*ubuntu.com#http://mirrors.aliyun.com#g /etc/apt/sources.list
# 更新源
RUN apt-get update
# 安装相关依赖包
RUN apt-get -y install wget curl jq git
# 下载 HUGO
RUN set -ex \
    && export FRP_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases |jq -r .[].tag_name | head -n 1 | sed 's/v//') \
    && export FRP_DOWN=$(curl -s https://api.github.com/repos/fatedier/frp/releases |jq -r .[].assets[].browser_download_url| grep -i 'linux_amd64'| head -n 1) \
    && wget --no-check-certificate $FRP_DOWN | tar zxvf frp_${FRP_VERSION}_linux_amd64.tar.gz -C /tmp 
	&& mv /tmp/frp_${FRP_VERSION}_linux_amd64 /tmp/frp
	 

# 指定创建的基础镜像
FROM alpine:latest
# 作者描述信息
MAINTAINER danxiaonuo
# 语言设置
ENV LANG zh_CN.UTF-8
# 时区设置
ENV TZ=Asia/Shanghai
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 更新源
RUN apk upgrade
# 同步时间
RUN apk add -U tzdata \
&& ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
&& echo ${TZ} > /etc/timezone

# 创建 FRPS 配置文件路径
RUN mkdir -p mkdir -p /etc/frp
# 拷贝 FRP 二进制文件至安装路径
COPY --from=builder /tmp/frp/frps /usr/bin/frps
COPY --from=builder /tmp/frp/frps_full.ini /etc/frp/frps.ini

# 设置 FRPS 环境变量
ENV PATH /usr/bin/frps:$PATH

# 增加文件权限
RUN chmod a+x /usr/bin/frps /etc/frp/frps.ini
# 命令执行入口
ENTRYPOINT /usr/bin/frps -c /etc/frp/frps.ini
