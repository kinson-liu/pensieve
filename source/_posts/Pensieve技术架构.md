title: Pensieve技术架构
author: Kinson
tags:
  - Pensieve
categories:
  - 技术
  - 架构
  - ''
date: 2021-03-14 02:24:00
---
## 概览
![Pensieve 网络架构图](/images/pensieve_network.png)
如图所示，用户访问阿里云，通过内网穿透工具将请求转发到本地，本地使用Kong来进行流量转发。博客网站Pensieve使用Hexo的Melody主题，需要分享的资源用NextCloud进行永久存储。当然，所有软件皆使用Portainer进行管理。
## 硬件
- 云服务器：
阿里云的2核1G实例5年 ¥437 带宽按量付费 ¥0.08/GB
- 树莓派：
Raspberry 4B 8G 基础套餐 ¥600

## 软件
- [NPS&NPC](https://github.com/ehang-io/nps): 一款轻量级、高性能、功能强大的内网穿透代理服务器。支持界面配置
- [Kong](https://github.com/Kong/kong): Kong 是在客户端和（微）服务间转发API通信的API网关,配合 [Konga](https://github.com/pantsel/konga) 可以实现界面化配置。
- [Portainer](https://github.com/portainer/portainer): 一个可视化的容器镜像的图形管理工具
- [NextCloud](https://github.com/nextcloud/server): 一款开源免费的私有云存储网盘项目，支持多端访问(有自己的App)
- [Hexo](https://github.com/hexojs/hexo): 基于Nodejs 的静态博客网站生成器，简洁却不简单！


### 基础设施

- 容器编排  Kubernetes v1.21.5
- 操作界面  Kubesphere v3.2.1
- 存储类    Longhorn
- 外网访问  Nginx
- 流量治理  Istio
- S3存储    MinIO
- 代码管理  GitLab
- 自动化构建  Jenkins
- 邮箱      阿里云企业邮箱
- 监控报警  Kubesphere


