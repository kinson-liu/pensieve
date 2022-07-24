title: Pensieve 集群搭建
author: Kinson
tags:
  - Pensieve
categories:
  - 技术
  - 部署
date: 2021-10-10 09:00:36
---

## 机房搭建
![机房图片](/images/cluster_picture.jpg)
### 硬件设备
- 主机5台
- 树莓派2台
- 笔记本1台
- 交换机1台
- UPS一台
- 开机棒一个

## 系统安装
### Ubuntu
#### U盘制作

- 准备工作
  1. [Ubuntu-20.04.3](https://ubuntu.com/download/desktop)
  2. [UltraISO](https://www.jb51.net/softs/44650.html)
- 制作启动盘
  1. 写入硬盘映像
  ![写入硬盘映像](/images/write_to_hard_disk_image.png)
  2. 选择写入硬盘
  ![选择硬盘](/images/select_hard_disk.png)

#### LVM 磁盘

安装系统时，为便于之后维护，请使用 LVM 安装Ubuntu。

> 具体LVM相关 请参考本网站相关文章：[LVM学习笔记](https://www.kinson.fun/2021/06/15/lvm-xue-xi-bi-ji/)。

![选择硬盘](/images/use_lvm_install.png)

## 集群搭建

### 基础环境

### K3S
#### Master
**安装脚本：**
```shell
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn sh -
```
运行此安装后：
1. K3s 服务将被配置为在节点重启后或进程崩溃或被杀死时自动重启。
2. 将安装其他实用程序，包括`kubectl、crictl、ctr、k3s-killall.sh` 和 `k3s-uninstall.sh`。
3. 将kubeconfig文件写入到/etc/rancher/k3s/k3s.yaml，由 K3s 安装的 kubectl 将自动使用该文件

#### Node
**安装脚本：**
```shell
curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```
- 设置`K3S_URL`参数会使 K3s 以 worker 模式运行。K3s agent 将在所提供的 URL 上向监听的 K3s 服务器注册。
- `K3S_TOKEN`存储在你的服务器`/var/lib/rancher/k3s/server/node-token`下
> 每台计算机必须具有唯一的主机名。如果您的计算机没有唯一的主机名，请传递K3S_NODE_NAME环境变量，并为每个节点提供一个有效且唯一的主机名。

#### 测试
执行 `kubectl get nodes` 获取节点信息
![节点信息](/images/cluster_success.png)

### longhorn
#### 依赖
```shell
apt install open-iscsi jq curl util-linux -y
apt-get install nfs-common -y
```
#### 安装
```
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
```
### Helm
``` shell
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```


### Rancher
``` shell
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=rancher.kinson.fun --set ingress.tls.source=secret
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

## 应用安装
### Docker

因为Kubernetes 从v1.20后不再使用 使用 Containerd 替代 Docker，作为默认的容器运行时(CRI)
但 Containerd没有构建镜像的功能，因此如果需要构建镜像的话，仍需安装Docker

``` shell
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

