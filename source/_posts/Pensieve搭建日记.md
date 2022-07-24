title: Pensieve搭建日记
author: Kinson
tags:
  - 服务器
  - 部署
  - Pensieve

categories:
  - 运维
  - 技术
  - K8S

date: 2021-10-10 09:00:36
---


## 机房

### 服务器设备搭建

之前就使用过树莓派搭建过k3s，但效果并不是很好（公寓经常断网断电）。现在工作了几年，终于在老家有了自己的一套房子，终于有条件搭建自己的机房了。
不过就和买车一样，作为年轻人肯定还是要专注性价比的嘛！于是上网好个找，最开始找了几个不错的，联想小机箱，空间不大，性价比很高。
但看着看着，突然有个想法冒了出来：我为什么非要买机箱呢？直接裸奔多Cool啊！于是果断放弃了机箱方案。最终花了1300块大洋，买了4台2核4G的做worker，一台4核8G的做master。外加配套电源、主板、硬盘。机房搭建之路开始！

机器是有了，那该放哪儿呢，服务器机架咱又买不起，那买个什么架呢？？？…………鞋，鞋架？ 想到这，我被我的机智惊艳到了。没错！就用鞋架！！！经过各种测量，最终买了两个鞋架。一个放机房，一个放PC和路由器，上面放上钢化玻璃作为桌面，正好可以放自己的一些小工具。完美！

大致框架有了，接着又买了其他细枝末节的东西（交换机，网线，束带，铜柱等等），经过漫长的组装，最终成品如下：

接下来，准备给主机安装系统

#### 设备清单
- 主机5台
  - master: 4核8G 200G固态
  - worker: 2核4G 500G机械
- 树莓派2台
  - GitLab
  - HomeAssistant
- 笔记本1台
  - JFrog
- 交换机1台
  - 100M
- UPS一台
  - 2000WH
- 开机棒一个
  - 自研ESPHome硬件

#### 服务器机房图

### 系统安装

机房硬件组装完了，接下来就要安装系统了。CentOS和Ubuntu都是很棒的操作系统，一个保守一个激进，对于年轻人来讲，装Ubuntu的人还是要比CentOS的人多一些的。
说什么CentOS更稳定的，内核用的都是一样的，都是敲命令行，能敲出什么花来？ 况且应用基本都跑在docker上，不像之前还要分配端口、执行脚本等乱七八糟的事情。
而且RedHat说之后就不专门维护CentOS了，RedHat公司坦言，CentOS并没有给公司带来那么大的经济效益，反而，还要不断地耗费人力去维护他（白嫖党太多了，哈哈）。

Ubuntu分Desktop版和Server版。但其实没多大差别，只是Desktop版多了GUI和一些常用软件而已。有命令行恐惧症的人可以选择Desktop版。这里我选择的Server，都一样的。

[Ubuntu Server 20.04.3](https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso)

#### U盘装机
U盘装机的话这里就不赘述了，网上教程多得很，等有机会我把我所有的装机经验系统总结下，分享给大家。

### 结尾

至此，一个像模像样的机房便搭建完毕了。总预算不到2000块，还有UPS提供保护，性价比高到绝绝子。

## K8S

### 什么是K8S

K8S——容器自动化编排工具。什么是容器呢？容器可以理解为房东用隔断分出一个个小间，每个小间都是一个家，
事实上，容器利用了各种资源隔离技术（CGroup 网络隔离 进程隔离等等），将一个大主机拆分成一个个小主机，
每个小主机都运行各自的系统，跑着各自的程序。同时K8S又将内部的网络整合，所有小容器都可以彼此找到对方。
一旦某个容器挂了，会在短时间内在别处重新拉起一个，这就是所谓的自动化编排。
也就是说，用户从顶层下达了一个命令，要启动某个容器，用户不管你具体部署到哪台机器上，你已经是个成熟的编排工具了，
你自己安排去。用户只是要K8S保证，当我访问K8S的时候，你能自己找到这个服务并将数据返回给我。

### K8S对传统运维方式的冲击

按照上面所述，K8S已经成熟到类似一个黑盒了，你定义资源，我启服务；你发起请求，我吐数据。
如果不发生设备问题、资源不足问题、性能问题的话，那么K8S基本是处于可控的状态。这样的话，一个人就可以管理一堆机器了。这为企业节约的人力成本，和带来的效率，可以说是巨大的。

那么传统的运维方式是如何实现这些功能的呢？

其实个人认为，大型企业基本早就把类似K8S的功能实现了，对于大企业来讲，使用K8S会降低学习成本，更加规范，更有效率。
比如脚本实现滚动更新、Nginx实现负载均衡、脚本实现自动安装服务等等…… 都是可以实现的。

相比之下，受益更多的反而是中小企业，因为他们相关的运维体系并没有那么完善，K8S来了，反而把现有的运维体系直接淘汰了。
用更成熟的方式去运维，在人力成本低的前提下，可以发挥最大的效率。

### 合理的使用K8S

那么如何合理的使用K8S，以至于不会让他轻易的失控呢？前文说到，如果不发生设备问题、资源不足问题、性能问题的话，K8S基本是处于可控的状态。
因此将这三个问题做到可控，那也就意味着K8S基本可控。

对于设备问题，K8S本身就是个集群，某个节点突然出现问题并不会造成太大的影响。当然，要是硬盘出现问题，那就另当别论了。
大企业可以组RAID来实现磁盘冗余，云运维更不需要担心这个，自建机房可以考虑使用支持冗余及备份的StorageClassProvider来实现这一功能(比如longhorn)。

对于资源不足的问题，可以通过搭建监控与报警系统来实现这块儿功能，监测到资源不足执行扩容操作。尤其是磁盘，LVM 永远的神！

对于性能问题，我之前看过一篇文章，讲阿里万级规模的K8S集群是如何实现的，起初觉得哇真牛逼，研究的这么深。后来细想，感觉学了也用不上啊。
阿里云是搞云平台的，搞一个万级规模的K8s很正常。但我作为一个公司的运维，也用不到这些知识啊。
多搭几套K8s集群不香吗，Rancher Kubesphere 等k8s管理平台是支持多集群的呀。把生产环境和其他环境分割开来，要想达到瓶颈，也是挺有难度的。

### K8S搭建

搭建K8s的话有很多种方式，什么KubeAdmin、MiniKube、Sealyun、Rancher、Kubesphere甚至是Ansible PlayBook，更牛逼的直接手搓，等等等等……方式多种多样

经过调研，我最终选择了尝试使用Kubesphere，原因如下：
1. 有界面，还挺好看
2. 便捷的初始化集群方式和扩缩容方式
3. 支持多集群
4. 支持查看CRD资源


#### 安装前准备
1. docker 一定要login, 否则会有请求限制
2. 更改docker镜像源 https://9wewa5zr.mirror.aliyuncs.com
3. /etc/hostname 设置短名称 /etc/hosts 设置长名称  127.0.0.1 kubcm-001.kinson.fun kubcm-001
4. 查看官方文档[安装文档](https://v3-1.docs.kubesphere.io/zh/docs/quick-start/all-in-one-on-linux/)
#### 创建K8s集群

``` shell
# 选择国内镜像源
export KKZONE=cn
# 仅创建k8s集群
kk create cluster --with-kubernetes v1.21.5
```

#### 添加节点
[添加节点](https://v3-1.docs.kubesphere.io/zh/docs/installing-on-linux/cluster-operation/add-new-nodes/)
./kk create config --from-cluster
此命令会生成sample.yaml

根据实际情况修改节点信息
``` yaml
apiVersion: kubekey.kubesphere.io/v1alpha1
kind: Cluster
metadata:
  name: sample
spec:
  hosts: 
  ##You should complete the ssh information of the hosts
  - {name: kubcm-001, address: 192.168.3.101, internalAddress: 192.168.3.101, user: root, password: lqs4568349}
  - {name: kubwo-001, address: 192.168.3.102, internalAddress: 192.168.3.102, user: root, password: lqs4568349}
  - {name: kubwo-002, address: 192.168.3.103, internalAddress: 192.168.3.103, user: root, password: lqs4568349}
  - {name: kubwo-003, address: 192.168.3.104, internalAddress: 192.168.3.104, user: root, password: lqs4568349}
  roleGroups:
    etcd:
    - kubcm-001
    master:
    - kubcm-001
    worker:
    - kubwo-001
    - kubwo-002
    - kubwo-003
```

kk add nodes -f sample.yaml

#### 创建默认存储类(longhorn)

[安装文档](https://longhorn.io/docs/1.2.2/deploy/install/install-with-helm/)
``` shell
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn --namespace longhorn-system --create-namespace
```
#### 安装 Kubesphere
kk create cluster --with-kubesphere v3.2.1

## Istio

Pensieve最终使用了Kubesphere提供的Istio，因为不愿在监控报警，日志收集这儿浪费太多的时间。
有能力的话可以自行研究。
监控报警我觉得可以深入的地方有很多，但个人并不喜欢往这条路上走，感觉路会走窄。

### 安装Istio
下面是部署Istio的两种方式：
[部署文档 Istioctl](https://istio.io/latest/docs/setup/getting-started/)
[部署文档 Helm](https://istio.io/latest/docs/setup/install/helm/)



## Traefik

### 安装Traefik

Traefik 只是简单部署了下，毕竟已经有Istio了。
``` shell
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm pull traefik/traefik
# 创建之前根据自身需要更改设置
tar -zxvf traefik-* && cd traefik 
vim values.yaml
helm install traefik traefik -n traefik --create-namespace
```


#### TroubleShooting
- 安装完成后，无法访问dashboard，报404错误。可能是因为没有配置`--api.insecure`造成的。另外 ingressRoute.dashboard.annotations 也要设置成 kubernetes.io/ingress.class: "traefik" [参考链接](https://github.com/traefik/traefik-helm-chart/issues/150)


#### 添加Ingress

使用Kubesphere创建应用路由，根据实际情况修改规则

#### K8S外服务设置Service

``` yaml
kind: Service
apiVersion: v1
metadata:
  name: gitlab
  namespace: external
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
kind: Endpoints
apiVersion: v1
metadata: 
  name: gitlab
  namespace: external
subsets:
- addresses:
  - ip: 192.168.3.99
  ports:
  - port: 80
```


## Puppet

### 安装puppet
[安装文档] https://puppet.com/docs/puppet/7/installing_and_upgrading.html

##



