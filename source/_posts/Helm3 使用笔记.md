title: Helm3使用笔记
author: Kinson
tags:
  - Helm
categories:
  - 技术
  - 云原生
date: 2021-6-10 16:38:52

---

## 关于 Helm

### 什么是 Helm？

Helm 是一个简化安装和管理 Kubernetes 应用程序的工具，可以将其视为 Kubernetes 的 `apt/yum/homebrew`
Helm 是用于管理 Charts 的工具，Charts 是预先配置的 Kubernetes 资源的软件包。
官网：https://helm.sh

### 用途

1. 查找并使用 Helm Charts 将应用程序部署在 Kubernetes 上
2. 通过 Helm Charts 将应用程序共享
3. 对 Kubernetes 应用程序实现可重复构建
4. 简便管理 Kubernetes 清单文件
5. 管理 Helm 包的发布

### 概念

Chart： Helm 应用(package)，包括对资源的定义及相关镜像的引用，还有模板文件、Values 文件等
Repository： Chart 仓库，http/https 服务器，Chart 的程序包放在这里
Release： Chart 的部署实例，每个 Chart 可以部署一个或多个 Release

### 版本

- 在 Helm 2 中，Tiller 是作为一个 Deployment 部署在 kube-system 命名空间中，很多情况下，我们会为 Tiller 准备一个 ServiceAccount ，这个 ServiceAccount 通常拥有集群的所有权限。
  用户可以使用本地 Helm 命令，自由地连接到 Tiller 中并通过 Tiller 创建、修改、删除任意命名空间下的任意资源。

- 在 Helm 3 中，Tiller 被移除了。新的 Helm 客户端会像 kubectl 命令一样，读取本地的 kubeconfig 文件，使用我们在 kubeconfig 中预先定义好的权限来进行一系列操作。

## Helm 安装

### 安装

```shell
# tar包安装
mkdir /software cd /software
wget https://get.helm.sh/helm-v3.3.0-linux-amd64.tar.gz
tar xf helm-v3.3.0-linux-amd64.tar.gz
cp linux-amd64/helm /usr/local/bin/helm

# 脚本安装
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# 源码安装
git clone https://github.com/helm/helm.git
cd helm && make

# 命令补全插件
apt install bash-completion -y
source /usr/share/bash-completion/bash_completion
echo "source <(helm completion bash)" >> ~/.bash_profile
source !$
```

### 查看版本

```shell
helm version
version.BuildInfo{Version:"v3.5.4", GitCommit:"1b5edb69df3d3a08df77c9902dc17af864ff05d1", GitTreeState:"clean", GoVersion:"go1.15.11"}
```

## Helm 使用

```shell
completion       生成自动补全脚本
create           创建一个给定名称的chart
dependency       管理chart的依赖关系
env              helm环境信息
get              获取给定release的扩展信息
help             命令帮助
history          获取release历史
install          部署chart
lint             对chart进行语法检查
list             releases列表，list可简写为ls
package          打包chart
plugin           install、list、uninstall Helm插件
pull             从repo中下载chart并（可选）将其解压到本地目录
repo             add、list、remove、update、index Helm的repo
rollback         回滚release到一个以前的版本
search           查询在charts中的关键字
show             显示chart的信息
status           显示给定release的状态
template         本地渲染模板
test             测试运行release
uninstall        删除release
upgrade          升级release
verify           验证给定路径的chart是否已签名且有效
version          显示helm的版本信息
```

### 添加 Repo 源

```shell
helm repo add stable http://mirror.azure.cn/kubernetes/charts
helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com
helm repo list
helm repo update

helm search repo stable                                 #查询stable repo可用的charts
helm repo remove incubator                              #删除incubator repo
```

### 查看 Chart 信息

```shell
helm show chart stable/mysql
helm show all stable/mysql
```

### 安装 Chart

```shell
helm install redis stable/redis -n default              #部署chart到k8s
helm ls                                                 #查看所有release
NAME 	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART       	APP VERSION
redis	default  	1       	2020-08-18 15:37:32.388925542 +0800 CST	deployed	redis-10.5.7	5.0.7

helm status redis                                       #查看release状态
helm uninstall redis                                    #删除release
```

### 最佳实践

Charts 除了可以在 repo 中下载，还可以自己自定义，创建完成后通过 helm 部署到 k8s。

#### 拉取

```shell
helm pull stable/mysql
ls
  mysql-1.6.6.tgz
tar xf mysql-1.6.6.tgz
tree mysql
  mysql
  ├── Chart.yaml
  ├── README.md
  ├── templates
  │   ├── configurationFiles-configmap.yaml
  │   ├── deployment.yaml
  │   ├── _helpers.tpl
  │   ├── initializationFiles-configmap.yaml
  │   ├── NOTES.txt
  │   ├── pvc.yaml
  │   ├── secrets.yaml
  │   ├── serviceaccount.yaml
  │   ├── servicemonitor.yaml
  │   ├── svc.yaml
  │   └── tests
  │       ├── test-configmap.yaml
  │       └── test.yaml
  └── values.yaml
  2 directories, 15 files
```

可以看到，一个 chart 包就是一个文件夹的集合，文件夹名称就是 chart 包的名称。
chart 是包含至少两项内容的 helm 软件包：
一个或多个模板，其中包含 Kubernetes 清单文件：

- NOTES.txt: chart 的“帮助文本”，在用户运行 helm install 时显示给用户
- deployment.yaml: 创建 deployment 的基本 manifest
- service.yaml: 为 deployment 创建 service 的基本 manifest
- ingress.yaml: 创建 ingress 对象的资源清单文件
- \_helpers.tpl: 放置模板助手的地方，可以在整个 chart 中重复使用

#### 创建

以 nginx 为例，创建自定义的 chart。

```shell
helm create nginx
tree nginx

  nginx
  ├── charts
  ├── Chart.yaml
  ├── templates
  │   ├── deployment.yaml
  │   ├── _helpers.tpl
  │   ├── hpa.yaml
  │   ├── ingress.yaml
  │   ├── NOTES.txt
  │   ├── serviceaccount.yaml
  │   ├── service.yaml
  │   └── tests
  │       └── test-connection.yaml
  └── values.yaml

  3 directories, 10 files

```

```shell
cat nginx/templates/deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "nginx.fullname" . }}
  labels:
    {{- include "nginx.labels" . | nindent 4 }}
spec:
{{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
{{- end }}
  selector:
    matchLabels:
      {{- include "nginx.selectorLabels" . | nindent 6 }}
  template:
    metadata:
    {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
    {{- end }}
      labels:
        {{- include "nginx.selectorLabels" . | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "nginx.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

在`templates`目录下`yaml`文件中的变量，是在`nginx/values.yaml`中定义的，只需要修改`nginx/values.yaml`的内容，也就完成了`templates`目录下`yaml`文件的配置。

#### 修改

```shell
vim nginx/Chart.yaml
```

```yaml
apiVersion: v2
name: nginx
description: A Helm chart for Kubernetes
type: application #chart类型，application或library
version: 0.1.0 #chart版本
appVersion: 1.0.0 #application部署版本```
```

```shell
vim tomcat/values.yaml
```

```yaml
replicaCount: 1
image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "latest"
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
serviceAccount:
  create: true
  annotations: {}
  name: ""
podAnnotations: {}
podSecurityContext:
  {}
  # fsGroup: 2000
securityContext:
  {}
  # capabilities:
  #   drop:
  #   - ALL
  # readOnlyRootFilesystem: true
  # runAsNonRoot: true
  # runAsUser: 1000
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: true
  annotations:
    {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - host: nginx.lzxlinux.cn #指定ingress域名及路径
      paths: [/]
  tls: []
  #  - secretName: chart-example-tls
  #    hosts:
  #      - chart-example.local
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80
  # targetMemoryUtilizationPercentage: 80
nodeSelector: {}
tolerations: []
affinity: {}
```

#### 部署

```shell
helm install nginx nginx --dry-run --debug                #渲染输出，不进行安装
helm install nginx nginx -n default             #部署chart，release版本默认为1
helm ls
NAME 	NAMESPACE	REVISION	UPDATED                               	STATUS  	CHART      	APP VERSION
nginx	default  	1       	2020-08-19 16:39:48.80635996 +0800 CST	deployed	nginx-0.1.0	1.0.0

kubectl get pod
NAME                     READY   STATUS    RESTARTS   AGE
nginx-74865b6d4c-867vm   1/1     Running   0          28s

kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   8d
nginx        ClusterIP   10.108.89.192   <none>        80/TCP    34s

kubectl get ingress
NAME    CLASS    HOSTS               ADDRESS   PORTS   AGE
nginx   <none>   nginx.lzxlinux.cn             80      38s
```

#### 升级

```shell
helm upgrade nginx nginx                #升级release，release版本加1

kubectl get svc
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP        8d
nginx        NodePort    10.108.89.192   <none>        80:30080/TCP   14m
```

#### 回滚

可以根据 release 版本回滚，

```shell
helm history nginx                  #查看release版本历史

REVISION	UPDATED                 	STATUS    	CHART      	APP VERSION	DESCRIPTION
1       	Wed Aug 19 16:39:48 2020	superseded	nginx-0.1.0	1.0.0      	Install complete
2       	Wed Aug 19 16:52:14 2020	deployed  	nginx-0.1.0	1.0.0      	Upgrade complete
```

```shell
helm rollback nginx 1               #回滚release到版本1
Rollback was a success! Happy Helming!
```

```shell
helm history nginx

REVISION	UPDATED                 	STATUS    	CHART      	APP VERSION	DESCRIPTION
1       	Wed Aug 19 16:39:48 2020	superseded	nginx-0.1.0	1.0.0      	Install complete
2       	Wed Aug 19 16:52:14 2020	superseded	nginx-0.1.0	1.0.0      	Upgrade complete
3       	Wed Aug 19 16:58:36 2020	deployed  	nginx-0.1.0	1.0.0      	Rollback to 1
```

```shell
kubectl get svc

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   8d
nginx        ClusterIP   10.108.89.192   <none>        80/TCP    19m
```

```shell
kubectl get ingress

NAME    CLASS    HOSTS               ADDRESS   PORTS   AGE
nginx   <none>   nginx.lzxlinux.cn             80      56s
```

可以看到，nginx release 已经回滚到版本 1。
通常情况下，在配置好 templates 目录下的 kubernetes 清单文件后，后续维护只需要修改 Chart.yaml 和 values.yaml 即可。

### 创建 Helm 仓库

Helm 可以使用私有 Helm 仓库，将自定义的 Chart 推送至仓库。

#### 安装 Push 插件

```shell
helm plugin install https://github.com/chartmuseum/helm-push
helm plugin ls

NAME	VERSION	DESCRIPTION
push	0.8.1  	Push chart package to ChartMuseum
```

#### 添加 Repo

```shell
helm repo add reponame http://repourl/reponame/chartname --username=yourname --password=yourpwd
helm repo ls
NAME  	URL
stable	http://mirror.azure.cn/kubernetes/charts
aliyun	https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
reponame	http://repourl/reponame/chartname

cd /software

helm push nginx reponame

Pushing nginx-0.1.0.tgz to harbor...
Done.
```

## 关于 Chart

Chart 是描述一组 Kubernetes 资源文件的集合。单个 Chart 既可以用于部署简单的应用(单个服务)，也可以部署复杂的应用(多个服务、高可用架构)。
使用 `helm create <chart name>` 命令，可以创建特定结构的目录及文件，之后可以将它们打包到版本存档中进行部署。
如果要下载并查看已发布 chart 的文件而不安装它，则可以使用 `helm pull <chart repo>/<chart name>` 进行操作。

### 文件结构

Chart 被组织为目录内文件的集合，目录名称就是 Chart 的名称（不包含版本信息）。因此，描述 WordPress 的 Chart 将存储在 wordpress/目录中。

而在此目录中，Helm 将期望与以下内容匹配的结构：

```shell
wordpress/
  Chart.yaml            # 包含chart信息的YAML文件
  LICENSE               # 包含chart许可的纯文本文件（可选）
  README.md             # README自述文件（可选）
  values.yaml           # 此chart的默认配置值
  values.schema.json    # 用于在 values.yaml 上强加结构的JSON模式（可选）
  charts/               # 包含此chart所依赖的任何charts的目录
  crds/                 # 自定义资源定义（CRD）
  templates/            # 模板目录，与值结合时，将生成有效的Kubernetes清单文件
  templates/NOTES.txt   # 包含简短用法说明的纯文本文件（可选）
```

Helm 保留了 charts/、crds/和 templates/目录的使用，以及列出的文件名。其他文件将保持原样。

### Chart.yaml

Chart.yaml 文件是 Chart 所必需的。它包含以下字段:

```yaml
apiVersion: # chart API版本 (必需)
name: # chart 名称 (必需)
version: # 版本 (必需, SemVer 2标准)
kubeVersion: # 所有兼容的Kubernetes 版本 (可选, SemVer 2标准)
description: # 项目单句描述 (可选)
type: # chart 类型，application 和 library (可选)
keywords:
  -  # 关于项目的关键字列表 (可选)
home: # 项目主页的url (可选)
sources:
  -  # 项目源码的url列表 (可选)
dependencies: # chart 需求列表 (可选)
  - name: # chart 名称 (nginx)
    version: # chart 版本 ("1.2.3")
    repository: # repo url ("https://example.com/charts") 或 别名 ("@repo-name")
    condition: # 一个解析为boolean的yaml路径，用于 启用/禁用 charts (如 subchart1.enabled ) (可选)
    tags: # (可选)
      -  # Tags 可以用来对 charts 的 启用/禁用 分组 (可选)
    enabled: # 使用 bool 参数决定是否应该加载 chart (可选)
    import-values: # (可选)
      -  # ImportValues 保存源值到要导入父键的映射。每一项可以是一个字符串或一对子/父子列表项 (可选)
    alias: # 用于 chart 的别名。多次添加相同的 chart 时很有用 (可选)
maintainers: # (可选)
  - name: # 维护人员名称 (每个维护人员必需)
    email: # 维护人员email (每个维护人员可选)
    url: # 维护人员的url (每个维护人员可选)
icon: # 作为图标使用的 SVG 或 PNG 图片 的url (可选)
appVersion: # app 版本 (可选)
deprecated: # chart 是否已弃用 (可选, boolean)
annotations:
  example: # 按名称键入的注释列表 (可选)
```

### Chart 依赖

Helm 中，一个 Chart 可能会依赖任意数量的其它 Chart。这些依赖项可以在 Chart.yaml 中通过 dependencies 字段进行动态配置，也可以导入 charts/目录中并手动进行管理。

当前 Chart 所依赖的 Chart 在 dependencies 字段中定义为列表：

```yaml
dependencies:
  - name: apache
    version: 1.2.3
    repository: https://example.com/charts
  - name: mysql
    version: 3.2.1
    repository: https://another.example.com/charts
```

repository 字段是 chart repo 的完整 url。需要注意的是，必须使用 helm repo add <repo url>本地添加该 repo。可以使用存储库的名称代替 url。

```shell
helm repo add example-charts https://example.com/charts
```

```yaml
dependencies:
  - name: apache
    version: 1.2.3
    repository: "@example-charts"
```

定义依赖项后，可以运行 helm dependency update <chart name>，它将使用依赖项文件将所有指定的 Chart 下载到您的 charts/目录中。

### 依赖项别名

除上述字段外，每个依赖项都可以包含可选字段 Alias。

为依赖的 Chart 添加别名，将 Chart 置于依赖关系中时将使用别名作为依赖项的名称。

```yaml
dependencies:
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
    alias: new-subchart-1
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
    alias: new-subchart-2
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
```

在上面的示例中，将获得 3 个依赖项：

- subchart
- new-subchart-1
- new-subchart-2

### 依赖项标签和条件

除上述字段外，每个依赖项还可以包含可选字段 Tags 和 Condition。

默认情况下会加载所有 Chart。如果存在 Tags 或 Condition 字段，则它们将被用于控制应用它们的 Chart 的加载。

Condition 字段包含一个或多个 Yaml 路径（以逗号分隔）。如果此路径存在于父 Chart 的 Values 中并解析为布尔值，则将基于该布尔值 启用/禁用 Chart。仅列表中找到的第一个路径有效，如果不存在路径，则该条件无效。

Tags 字段是与该 Chart 关联的 Yaml 标签列表。在父 Chart 的 Values 中，可以通过指定标签和布尔值来 启用/禁用 所有带有标签的 chart。

```yaml
dependencies:
  - name: subchart1
    repository: http://localhost:10191
    version: 0.1.0
    condition: subchart1.enabled, global.subchart1.enabled
    tags:
      - front-end
      - subchart1
  - name: subchart2
    repository: http://localhost:10191
    version: 0.1.0
    condition: subchart2.enabled,global.subchart2.enabled
    tags:
      - back-end
      - subchart2
```

values.yaml

```yaml
subchart1:
  enabled: true
tags:
  front-end: false
  back-end: true
```

上面示例中，所有带有标签 front-end 都将被禁用，但是由于 subchart1.enabled 路径在父 chart 的 Values 中为 true，因此条件将覆盖 front-end 标签并启用 subchart1。

由于 subchart2 带有标签 back-end，且 back-end 为 true，subchart2 将被启用。另外，尽管 subchart2 指定了条件，但父 Chart 的 Values 中没有相应的路径和值，因此该条件无效。

`--set`参数可以用于更改标签和条件值

```shell
helm install --set tags.front-end=true --set subchart2.enabled=false
```

### 标签和条件解析

- 条件（有设置时）始终会覆盖标签。存在的第一个条件路径获胜，后续条件路径将被忽略

- 如果 chart 的任何标签为 true，则启用该 chart

- 标签和条件值必须设置在父 chart 的 Values 中

- tags：父 chart 的 Values 中的键必须是顶级键；不支持全局和嵌套表

## Helm 内置对象

对象从模板引擎传递到模板中。

对象可以很简单，只有一个值；或者可以包含其他对象或函数。例如，`Release` 对象包含多个对象（如 `Release.Name`）并且 Files 对象具有一些函数。

```yaml
Release: 此对象描述发行版本身。它里面有几个对象
- Release.Name: release 名称
- Release.Namespace: release 的 namespace（如果清单未覆盖）
- Release.IsUpgrade: 如果当前操作是upgrade或rollback，则设置为 true
- Release.IsInstall: 如果当前操作是install，则设置为 true
- Release.Revision: release的版本号。初始部署时为1，并且每次升级或回滚时加1
- Release.Service: release 服务的名称。在Helm上，始终是Helm

Values: 从 values.yaml 文件和用户提供的文件传入模板的值，默认情况下 Values 为空

Chart: Chart.yaml 文件的内容。Chart.yaml 中的任何数据都可以在此处访问

Files: 提供对 chart 中所有非特殊文件的访问。不能使用它来访问模板，但是可以使用它来访问 chart 中的其他文件：
- Files.Get: 是用于通过名称（.Files.Get config.ini）获取文件的函数
- Files.GetBytes: 是将文件内容作为字节数组而不是字符串获取的函数
- Files.Glob: 是一个函数，该函数返回名称与给定的Shell Glob模式匹配的文件列表
- Files.Lines: 是逐行读取文件的函数，对于遍历文件很有用
- Files.AsSecrets: 是将文件主体作为Base64编码的字符串返回的函数
- Files.AsConfig: 是一个将文件正文作为YAML映射返回的函数

Capabilities: 提供了有关Kubernetes集群支持哪些功能的信息
- Capabilities.APIVersions: 是一组版本
- Capabilities.APIVersions.Has $version: 指示版本（例如 batch/v1）或资源（例如 apps/v1/Deployment）在集群上是否可用
- Capabilities.KubeVersion 和 Capabilities.KubeVersion.Version: 是Kubernetes版本
- Capabilities.KubeVersion.Major: 是Kubernetes的主要版本
- Capabilities.KubeVersion.Minor: 是Kubernetes的次要版本


Template: 包含有关正在执行的当前模板的信息

    Template.Name: 当前模板的命名空间文件路径（例如 mychart/templates/mytemplate.yaml）

    Template.BasePath: 当前 chart 的模板目录的命名空间路径（例如 mychart/templates）
```

上⾯的值可用于任何顶级模板，要注意内置值始终以大写字母开头。

### values.yaml

helm 模板提供的内置对象之一是 `Values`，该对象提供对传递到 chart 中的值的访问。其内容来自多种来源：

1. chart 中的 values.yaml 文件
2. 如果是子 chart，则是父 chart 中的 values.yaml 文件
3. helm install 或 helm upgrade 带的 -f 参数指定的 yaml 文件（如 helm install -f myvals.yaml ./mychart）
4. 通过 --set 参数传递的值（如 helm install --set foo=bar ./mychart）

上面按顺序排列：values.yaml 是默认值，可以被父 chart 的 values.yaml 覆盖，而后者可以由用户提供的 yaml 文件覆盖，而后者又可以由 --set 参数覆盖。

示例 values.yaml

```yaml
favorite:
  drink: coffee
  food: pizza
```

根据示例 values.yaml，可以这样修改模板：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink }}
  food: {{ .Values.favorite.food }}
```

### 模板函数和管道

当将 .Values 对象中的字符串注入到模板时，可以通过调用模板函数 quote 来引用这些字符串：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ quote .Values.favorite.drink }}
  food: {{ quote .Values.favorite.food }}
```

模板函数遵循语法：functionName arg1 arg2...，在上面代码段中，quote .Values.favorite.drink 调用 quote 函数并将其传递给单个参数。

#### 管道 '|'

管道 `|` 是将一系列模板命令链接在一起的工具，以紧凑地表达一系列转换。管道 `|` 是按顺序完成多项工作的有效方式。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink | quote }}
  food: {{ .Values.favorite.food | quote }}
```

上面示例中，没有调用，而是反转了顺序。使用管道 `|` 将参数“发送”到函数：`.Values.favorite.food | quote`

    反转顺序是模板中的常见做法，.val | quote 比 quote .val 更为常见。

使用管道，可以将多个功能链接在一起：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink | quote }}
  food: {{ .Values.favorite.food | upper | quote }}
```

该模板产生以下输出：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trendsetting-p-configmap
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "PIZZA"
```

上面示例中，已经将 pizza 转换为 “PIZZA”。

#### default 函数

default 函数允许在模板内部指定默认值，以防省略该值。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink | default "tea" | quote }}
  food: {{ .Values.favorite.food | upper | quote }}
```

values.yaml 中可以注释 drink，得到输出：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fair-worm-configmap
data:
  myvalue: "Hello World"
  drink: "tea"
  food: "PIZZA"
```

在实际 Chart 中，所有默认值都应该配置在 values.yaml 中，并且不应使用 default 函数重复。

#### lookup 函数
lookup 函数可用于在运行中的集群中查找资源。

参数的组合：

```shell
kubectl get pod mypod -n mynamespace  →   lookup "v1" "Pod" "mynamespace" "mypod"

kubectl get pods -n mynamespace       →   lookup "v1" "Pod" "mynamespace" ""

kubectl get pods --all-namespaces     →   lookup "v1" "Pod" "" ""

kubectl get namespace mynamespace     →   lookup "v1" "Namespace" "" "mynamespace"

kubectl get namespaces                →   lookup "v1" "Namespace" "" ""
```

当 lookup 返回一个对象时，它将返回一个字典，可以进一步从字典中提取特定值。

例如，返回该 mynamespace 对象存在的注释：

```yaml
(lookup "v1" "Namespace" "" "mynamespace").metadata.annotations
```

当 lookep 返回一个对象列表时，可以通过 items 字段访问对象列表：

```yaml
{{ range $index, $service := (lookup "v1" "Service" "mynamespace" "").items }}
    {{/* do something with each service */}}
{{ end }}
```

如果找不到对象，则返回一个空值。

lookup 函数使用 Helm 现有的 Kubernetes 连接配置来查询 Kubernetes。如果在与调用 API 服务器进行交互时返回任何错误（例如缺乏访问资源的权限），则模板处理将失败。

需要注意的是，在 helm template 或 helm install|update|delete|rollback --dry-run 期间，Helm 不会与 Kubernetes API Server 联系，因此在这种情况下 lookup 函数将返回 nil。

```yaml
indent: 从左到右指定空格个数

with: 可以允许将当前范围 . 设置为特定的对象。例如 .Values.service，使用 with 可以将 .Values.service 改为 .

变量: 在 Helm 模板中，变量是对另一个对象的命名引用。它遵循这个形式 $name。变量被赋予一个特殊的赋值操作符：:=
```

#### .Capabilities.APIVersions.Has 函数

```yaml
.Capabilities.APIVersions.Has 函数返回API版本或资源在集群中是否可用。
.Capabilities.APIVersions.Has "apps/v1"
.Capabilities.APIVersions.Has "apps/v1/Deployment"
```

#### 其它常用函数

```shell
and         返回两个参数的布尔值和
or          返回两个参数的布尔值或。它返回第一个非空参数或最后一个参数
not         返回其参数的布尔取反
eq          如果Arg1 = Arg2，则返回true，否则返回false
ne          如果Arg1 != Arg2，则返回true，否则返回false
lt          如果Arg1 < Arg2，则返回true，否则返回false
le          如果Arg1 <= Arg2，则返回true，否则返回false
gt          如果Arg1 > Arg2，则返回true，否则返回false
ge          如果Arg1 >= Arg2，则返回true，否则返回false
lower       将整个字符串转换为小写
upper       将整个字符串转换为大写
repeat      重复给定字符串多次
substr      从字符串获取子字符串
nospace     从字符串中删除所有空格
indent      indent 函数将给定字符串中的每一行缩进到指定的缩进宽度
nindent     nindent 函数与 indent 函数相同，但是在字符串的开头添加了新行
replace     执行简单的字符串替换
reverse     用给定列表的元素，生成一个新列表，顺序与原列表相反
uniq        生成一个列表，删除所有重复项
has         测试列表是否具有特定元素，返回true，否则返回false
slice       获取列表部分元素，列表切片
until       生成一个顺序的整数列表
untilStep   和 until 一样，生成一个顺序的整数列表，但 untilStep 允许定义开始、结束和步长
seq         类似 seq 命令，生成参数之间的所有整数，默认步长为1或-1，单调递增或递减
add         相加
add1        加1
sub         相减
div         相除
mul         相乘
max         最大值
min         最小值
floor       返回 <= 输入值的最大浮点数
ceil        返回 >= 输入值的最大浮点数
round       四舍五入，返回一个浮点数
len         以整数形式返回参数的长度
base        返回路径的最后一个元素
dir         返回目录，去除路径的最后一部分
clean       清理路径，只保留路径开头和结尾
ext         返回文件扩展名
isAbs       检查文件路径是否是绝对路径
```

Helm 包含许多模板函数，可以在模板中使用它们。常用函数：https://helm.sh/docs/chart_template_guide/function_list/

## 流程控制

控制结构（在模板中被称为“动作”）提供了控制模板生成流程的能力。helm 的模板语言提供以下控制结构：

```shell
if/else     用于创建条件块
with        指定范围
range       提供“针对每个”样式的循环
```

除此之外，helm 还提供了一些声明和使用命名模板段的操作：

```shell
define      在模板中声明一个新的命名模板
template    导入命名模板
block       声明一种特殊的可填充模板区域
```

### if/else

#### 基础结构

```yaml
{{ if PIPELINE }}
  # Do something
{{ else if OTHER PIPELINE }}
  # Do something else
{{ else }}
  # Default case
{{ end }}
```

如果值为以下内容，pipeline 为 false：

1. 布尔值 false
2. 数字 0
3. 空字符串
4. nil（empty 或 null）
5. 空集合（map，slice，tuple，dict，array）

在其他条件下，pipeline 为 true。

**示例**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  drink: {{ .Values.favorite.drink | default "tea" | quote }}
  food: {{ .Values.favorite.food | upper | quote }}
  {{ if eq .Values.favorite.drink "coffee" }}mug: true{{ end }}
```

**输出**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: eyewitness-elk-configmap
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "PIZZA"
  mug: true
```

### with

with 控制变量作用域。. 是对当前范围的引用，而 .Values 告诉模板 Values 在当前范围内查找对象。

with 的语法类似于一个简单的 if 语句：

```yaml
{{ with PIPELINE }}
  # restricted scope
{{ end }}
```

with 可以将当前范围 . 设置为特定对象：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  {{- end }}
```

但是需要注意，在受限范围内，将无法使用 . 从父 chart 范围访问其他对象：

```yaml
{{- with .Values.favorite }}
drink: {{ .drink | default "tea" | quote }}
food: {{ .food | upper | quote }}
release: {{ .Release.Name }}
{{- end }}
```

由于 Release.Name 不在 . 的限制范围内，因此会报错。但是可以使用 {{ end }}重置作用域：

```yaml
{{- with .Values.favorite }}
drink: {{ .drink | default "tea" | quote }}
food: {{ .food | upper | quote }}
{{- end }}
release: {{ .Release.Name }}
```

还可以用 $ 从父 chart 范围访问对象 Release.name。模板执行开始时将 $ 映射到根作用域，并且在模板执行期间不会更改。以下内容也可以工作：

```yaml
{{- with .Values.favorite }}
drink: {{ .drink | default "tea" | quote }}
food: {{ .food | upper | quote }}
release: {{ $.Release.Name }}
{{- end }}
```

### range
在 helm 的模板语言中，迭代集合的方法是使用 range 运算符。

示例：

values.yaml

```yaml
favorite:
  drink: coffee
  food: pizza
pizzaToppings:
  - mushrooms
  - cheese
  - peppers
  - onions
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  {{- end }}
  toppings: |-
    {{- range .Values.pizzaToppings }}
    - {{ . | title | quote }}
    {{- end }}
```

以下内容也可以工作：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  toppings: |-
    {{- range $.Values.pizzaToppings }}
    - {{ . | title | quote }}
    {{- end }}
  {{- end }}
```

**输出**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: edgy-dragonfly-configmap
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "PIZZA"
  toppings: |-
    - "Mushrooms"
    - "Cheese"
    - "Peppers"
    - "Onions"
```

## 变量
在 helm 模板中，变量是对另一个对象的命名引用。它遵循以下形式：`$name`，变量使用特殊的赋值运算符`:=`。

在前面的示例中，此代码会失败：

```yaml
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  release: {{ .Release.Name }}
  {{- end }}
```

Release.Name 不在该代码 with 块限制的范围之内。可以将上面代码重写为对变量使用 Release.Name：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- $relname := .Release.Name -}}
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  release: {{ $relname }}
  {{- end }}
```

**输出**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: viable-badger-configmap
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "PIZZA"
  release: viable-badger
```

变量在 range 循环中特别有用。它们可以用于类似列表的对象，以同时捕获索引和值：

```yaml
toppings: |-
  {{- range $index, $topping := .Values.pizzaToppings }}
    {{ $index }}: {{ $topping }}
  {{- end }}
```

注意，range 首先跟的是变量，然后是赋值运算符，然后是列表。这会将整数索引（从零开始）分配给 `$index`，并将值分配给`$topping`。

**输出**

```yaml
toppings: |-
  0: mushrooms
  1: cheese
  2: peppers
  3: onions
```

对于同时具有键和值的数据结构，可以使用 range 两者来获取。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

**输出**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: eager-rabbit-configmap
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
```

变量通常不是“全局”的，它们的作用域仅限于声明它们的块。$ 变量是全局变量，该变量始终指向根上下文。

## 命名模板

命名模板也称为部分模板或子模板，是一个简单的文件中定义的、并且给定名称的模板。_helpers.tpl 文件是命名模板的默认位置。

命名模板需要注意的是，模板名称是全局的，如果声明了两个相同名称的模板，则以最后加载的那个为准。

通常的命名约定是在每个定义的模板前添加 chart 名称：`{{ define "mychart.labels" }}`。通过使用特定的 chart 名称作为前缀，可以避免由于模板名称相同而引起的任何冲突。

### define
define 操作可以在模板文件内部创建命名模板，语法如下：

```yaml
{{ define "MY.NAME" }}
  # body of template here
{{ end }}
```

定义一个模板来封装 Kubernetes 标签块，示例：

```yaml
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
{{- end }}
```

将此模板嵌入到现有的 ConfigMap 中，然后将其包含在 template 操作中：

```yaml
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

**输出**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: running-panda-configmap
  labels:
    generator: helm
    date: 2016-11-02
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
```

helm chart 通常将这些模板放在 _helpers.tpl 文件中，然后可以在 ConfigMap 中调用：

_helpers.tpl

```yaml
{{/* Generate basic labels */}}
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
{{- end }}
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

**模板范围**
_helpers.tpl

```yaml
{{/* Generate basic labels */}}
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
    chart: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
{{- end }}
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" . }}
```

```shell
helm install --dry-run --debug plinking-anaco ./mychart
```

输出：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: plinking-anaco-configmap
  labels:
    generator: helm
    date: 2016-11-02
    chart: mychart
    version: 0.1.0
```

当命名模板（使用 define 创建的模板）被渲染时，它将接收 template 调用传递的范围。

### include 函数
示例：

```yaml
{{- define "mychart.app" -}}
app_name: {{ .Chart.Name }}
app_version: "{{ .Chart.Version }}"
{{- end -}}
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
    {{ template "mychart.app" . }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{ template "mychart.app" . }}
```

输出：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: measly-whippet-configmap
  labels:
    app_name: mychart
app_version: "0.1.0+1478129847"
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
  app_name: mychart
app_version: "0.1.0+1478129847"
```

可以看到，app_version 的缩进是错误的，因为 template 是操作而不是函数，所以无法将 template 调用的输出传递给其他函数。

helm 提供了一种替代方法，include 可以将模板的内容导入到当前 pipeline 中，然后可以将其传递给 pipeline 中的其它函数。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{ include "mychart.app" . | indent 4 }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{ include "mychart.app" . | indent 2 }}
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: edgy-mole-configmap
  labels:
    app_name: mychart
    app_version: "0.1.0+1478129987"
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
  app_name: mychart
  app_version: "0.1.0+1478129987"
```

## 访问模板内的文件

有时要导入文件，而不是模板，可以通过 .Files 描述的对象访问文件来实现。

helm 提供了通过 .Files 对象访问文件的权限。有几点需要注意：

1. 在 chart 中可以添加其他文件。但由于 Kubernetes 对象的存储限制，chart 必须小于 1M
2. .Files 因为安全原因，某些文件无法通过该对象访问：
    - 无法访问 templates/ 中的文件
    - 无法访问使用 .helmignore 排除的文件
3. chart 不保留 unix 模式信息，因此文件级权限限制对 .Files 对象的文件可用性没有影响

示例：
编写一个模板，将三个文件读入 ConfigMap。首先向 chart 添加三个文件，将三个文件放入 mychart/ 目录中。

config1.toml

```shell
message = Hello from config 1
```

config1.toml

```shell
message = Hello from config 2
```

config3.toml

```shell / yaml
message = Hello from config 3
```

使用 range 函数来遍历它们，并将其内容注入到 ConfigMap 中：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- $files := .Files }}
  {{- range tuple "config1.toml" "config2.toml" "config3.toml" }}
  {{ . }}: |-
    {{ $files.Get . }}
  {{- end }}
```

输出：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: quieting-giraf-configmap
data:
  config1.toml: |-
    message = Hello from config 1

  config2.toml: |-
    message = This is config 2

  config3.toml: |-
    message = Goodbye from config 3
```

### 文件路径处理
在处理文件时，对文件路径本身执行一些标准操作会非常有用。相关函数有：

```shell
base        返回路径的最后一个元素
dir         返回目录，去除路径的最后一部分
clean       清理路径，只保留路径开头和结尾
ext         返回文件扩展名
isAbs       检查文件路径是否是绝对路径
```

### glob 模式
随着 chart 的增长，可能会更需要组织文件。helm 提供了 Files.Glob(pattern string) 方法，用来以 glob 模式灵活地提取某些文件。

例如，目录结构如下：

```shell
foo/:
  foo.txt foo.yaml

bar/:
  bar.go bar.conf baz.yaml
```

globs 有多种选择：

```yaml
{{ $currentScope := .}}
{{ range $path, $_ :=  .Files.Glob  "**.yaml" }}
    {{- with $currentScope}}
        {{ .Files.Get $path }}
    {{- end }}
{{ end }}
```

或

```yaml
{{ range $path, $_ :=  .Files.Glob  "**.yaml" }}
      {{ $.Files.Get $path }}
{{ end }}
```

### ConfigMap 和 Secrets 实用函数
想要将文件内容同时放入 ConfigMap 和 Secrets 中，以便在运行时安装到 pod 中。

结合 glob 模式，从上面的 glob 示例给出目录结构：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: conf
data:
{{ (.Files.Glob "foo/*").AsConfig | indent 2 }}
---
apiVersion: v1
kind: Secret
metadata:
  name: very-secret
type: Opaque
data:
{{ (.Files.Glob "bar/*").AsSecrets | indent 2 }}
```

### 编码方式
可以导入文件并使用 base-64 模板对其进行编码，以确保成功传输：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-secret
type: Opaque
data:
  token: |-
    {{ .Files.Get "config1.toml" | b64enc }}
```

输出：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: lucky-turkey-secret
type: Opaque
data:
  token: |-
    bWVzc2FnZSA9IEhlbGxvIGZyb20gY29uZmlnIDEK
```

### Lines
有时，需要访问模板中文件的每一行。

为此 helm 提供了 Lines 方法，Lines 可以使用 range 函数循环遍历：

```yaml
data:
  some-file.txt: {{ range .Files.Lines "foo/bar.txt" }}
    {{ . }}{{ end }}
```

在 helm install 期间，无法将外部文件传递给 chart。因此，必须使用 helm install -f 或 helm install --set 加载数据。

## 子 chart 和全局 Values
chart 可以具有依赖项，称为子 chart，子 chart 也有自己的 values 和 templates。

关于子 chart，有几点主要注意：
1. 子 chart 被看作“独立的”，它不能显式依赖其父 chart，子 chart 无法访问其父 chart 的 values
2. 父 chart 可以覆盖子 chart 的 values
3. helm 可以设置能被所有 chart 访问的全局 values

### 创建子 chart

```shell
helm create mychart
cd mychart/charts
helm create mysubchart
```

当子 chart 中 values 的 key 与父 chart 中 values 的 key 相同时，父 chart 的 values 会覆盖子 chart 的 values。

### 全局 values
全局 values 是可以从任何 chart 或子 chart 中以完全相同的名称访问的 values。全局 values 需要显式声明。

Values.global 可以用来设置全局 values，例如：

values.yaml

```yaml
favorite:
  drink: coffee
  food: pizza
pizzaToppings:
  - mushrooms
  - cheese
  - peppers
  - onions
mysubchart:
  dessert: ice cream
global:
  salad: caesar #全局values
```

### 共享模板
父 chart 可以与子 chart 共享模板。任何 chart 中任何已定义的模板块都可以用于其它 chart。

定义一个简单的模板，例如：

```yaml
{{- define "labels" }}from: mychart{{ end }}
```

include 和 template 函数都可以引用模板，但 include 可以动态引用，而 template 仅接受字符串。

```yaml
{ { include $mytemplate } }
```

## 更多
### .helmignore 文件
.helmignore 文件用于指定不想包含在 helm chart 中的文件。

如果存在 .helmignore 文件，helm package 命令将忽略该文件中匹配到的所有文件。

.helmignore 文件支持 unix shell 全局匹配、相对路径匹配和否定（以 ! 前缀）。每行仅支持一种模式。

示例：

```yaml
# comment
.git
*/temp*
*/*/temp*
temp?
```

### 调试

```yaml
helm lint                           验证chart是否遵循语法
helm install --dry-run --debug      渲染模板，然后返回生成的kubernetes清单文件
helm template --debug               渲染模板，然后返回生成的kubernetes清单文件
helm get manifest                   查看服务器上安装了哪些模板
```

当 yaml 无法解析、但想查看生成内容时，可以先在模板中注释掉问题部分，然后重新运行 helm install --dry-run --debug：

```yaml
apiVersion: v2
# some: problem section
# {{ .Values.foo | quote }}
```

上面的内容将渲染并返回完整的注释：

```yaml
apiVersion: v2
# some: problem section
#  "bar"
```
