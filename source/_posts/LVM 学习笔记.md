title: LVM学习笔记
author: Kinson
tags:
  - LVM
categories:
  - 技术
  - Linux
date: 2021-6-15 13:53:59
---

**写在前面：**
今天开会讨论了 PH2 相关服务器的部署问题，发现老外创建的系统没有使用 LVM，这对之后的运维工作制造了不必要的麻烦。以前没有详尽的了解过 LVM。正好借着这个机会了解下~

## 关于 LVM

### 概念解释

LVM(Logical Volume Manager)逻辑卷管理，是一种将一个或多个硬盘的分区在逻辑上集合，相当于一个大硬盘来使用，当硬盘的空间不够使用的时候，可以继续将其它的硬盘分区加入其中，这样可以实现一种磁盘空间的动态管理，相对于普通的磁盘分区有很大的灵活性，使用普通的磁盘分区，当一个磁盘的分区空间不够使用的时候，很可能带来很大的麻烦。使用 LVM 在一定程度上就可以解决普通磁盘分区带来的问题。

### 为什么使用 LVM

LVM 通常用于装备大量磁盘的系统, 比如服务器中的磁盘阵列。
但 LVM 同样适用于仅有一、两块硬盘的小系统。

#### 小系统使用LVM的益处

**传统的文件系统**

一个文件系统对应一个分区，直观，但不易改变，不同的分区相对独立，无相互联系，各分区空间常常利用不平衡，空间不能充分利用。当一个文件系统／分区已满时，无法对其扩充，只能采用重新分区／建立文件系统，非常麻烦，或把分区中的数据移到另一个更大的分区中；或采用符号连接的方式使用其它分区的空间。如果要把硬盘上的多个分区合并在一起使用，只能采用再分区的方式，这个过程需要数据的备份与恢复。

**采用LVM**

硬盘的多个分区由LVM统一为卷组管理，可以方便的加入或移走分区以扩大或减小卷组的可用容量，充分利用硬盘空间；文件系统建立在逻辑卷上，而逻辑卷可根据需要改变大小(在卷组容量范围内)以满足要求，可以跨分区。

#### 大系统使用LVM的益处

在使用很多硬盘的大系统中，使用LVM主要是方便管理、增加了系统的扩展性。用户／用户组的空间建立在LVM上，可以随时按要求增大，或根据使用情况对各逻辑卷进行调整。当系统空间不足而加入新的硬盘时，不必把用户的数据从原硬盘迁移到新硬盘，而只须把新的分区加入卷组并扩充逻辑卷即可。同样，使用LVM可以在不停服务的情况下。把用户数据从旧硬盘转移到新硬盘空间中去。

## LVM原理

传统文件系统，比如这个盘只有300G，那么建立在这个300G上面的文件系统最多只能用到300G，但是有了LVM这个功能后，我们建立文件系统的盘就不是建立在物理盘上，而是建立在一个叫LV逻辑卷上面，这个卷是一个逻辑概念不是物理盘，空间可能大于一个物理盘，也可能小于一个物理盘。而且这个LV逻辑卷的空间可以扩展和缩小，这样就给上层的文件系统提供了更好的支持。

### 名词解释
**PV(Physical Volume):** 物理卷, 处于 LVM 最底层, 其实就是指一个分区（如/dev/sdb1 ）或者是一个盘（如/dev/sdb）。

**VG(Volume Group):** 卷组, 建立在 PV 之上, 可以含有一个到多个 PV。（相当于一个Pool，由多个PV组成的pool）

**LV(Logical Volume):** 逻辑卷, 建立在 VG 之上, 相当于原来分区的概念, 不过大小可以动态改变。(比如/dev/mapper/rhel-root这个目录其实是一个文件系统挂载点，这个点就是承载在一个LV上，这个文件系统的大小就是这个LV的大小。)

### 原理图
![LVM原理图](/images/lvm.png)

## 普通的挂载磁盘方法

### 创建分区的主要操作

#### 查看分区情况： fdisk -l

```shell
 fdisk -l

Disk /dev/sda: 299.0 GB, 298999349248 bytes			# 磁盘/dev/sda
255 heads, 63 sectors/track, 36351 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x4d69fe0e

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *           1          26      204800   83  Linux		# 分为2个区, sda1
Partition 1 does not end on cylinder boundary.
/dev/sda2              26       36352   291785728   8e  Linux LVM	# sda2

# 磁盘/dev/sdb没有分区
Disk /dev/sdb: 4000.0 GB, 3999999721472 bytes
255 heads, 63 sectors/track, 486305 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000
......
```

#### 查看已有磁盘： lsblk

```shell
 lsblk
NAME                       MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda                          8:0    0 278.5G  0 disk
├─sda1                       8:1    0   200M  0 part /boot
└─sda2                       8:2    0 278.3G  0 part
  └─VolGroup-LogVol (dm-0) 253:0    0   1.9T  0 lvm  /		# LVM类型的分区
sdb                          8:32   0   3.7T  0 disk 		# 还没有分区的新磁盘
```

#### 对新磁盘进行分区： fdisk /dev/sdb

```shell
 fdisk /dev/sdb
Device contains neither a valid DOS partition table, nor Sun, SGI or OSF disklabel
Building a new DOS disklabel with disk identifier 0xf91f8c4c.
Changes will remain in memory only, until you decide to write them.
After that, of course, the previous content won't be recoverable.

Warning: invalid flag 0x0000 of partition table 4 will be corrected by w(rite)

WARNING: The size of this disk is 4.0 TB (4000225165312 bytes).
DOS partition table format can not be used on drives for volumes
larger than (2199023255040 bytes) for 512-byte sectors. Use parted(1) and GUID
partition table format (GPT).


WARNING: DOS-compatible mode is deprecated. It's strongly recommended to
         switch off the mode (command 'c') and change display units to
         sectors (command 'u').

Command (m for help): n				# n 表示新建分区
Command action
   e   extended
   p   primary partition (1-4)
p									# p 表示分区类型为主分区, 主分区只有1-4种选择
Partition number (1-4): 1			# 主分区的编号
First cylinder (1-486333, default 1): 	# 开始扇区号, 直接回车, 使用默认值1
Using default value 1

# 结束扇区号, 使用默认值 --- 这里只加载了新磁盘的一半(2T), 所以还需要再次创建分区/dev/sdb2使用剩下的一半.
Last cylinder, +cylinders or +size{K,M,G} (1-267349, default 267349):
Using default value 267349

Command (m for help):  w			#  将上述设置写入分区表并退出
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

#### 再次查看分区情况 - fdisk -l

多出来一个/dev/sdb1 的区, 这个 1 就是之前主分区之后指定的分区编号.

```shell
 fdisk -l

Disk /dev/sda: 299.0 GB, 298999349248 bytes
255 heads, 63 sectors/track, 36351 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x4d69fe0e

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *           1          26      204800   83  Linux
Partition 1 does not end on cylinder boundary.
/dev/sda2              26       36352   291785728   8e  Linux LVM

# /dev/sdb磁盘:
Disk /dev/sdb: 4000.0 GB, 3999999721472 bytes
255 heads, 63 sectors/track, 486305 cylinders
Units = cylinders of 16065 * 512 = 8225280 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x8f3043b5

# 多出来的分区/dev/sdb1
   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1               1      267349  2147480811   83  Linux

......
```

#### 查看当前分区表中的分区信息： cat /proc/partitions

```shell
 cat /proc/partitions
major minor  #blocks  name

   8        0   291991552  sda
   8        1      204800  sda1
   8        2   291785728  sda2
   8       32  3906249728  sdb		# 添加的新磁盘
   8       33  2147480811  sdb1		# 创建的新分区
 253        0  2046660608  dm-0
如果创建完之后，cat /proc/partitions 查看不到对应的分区，使用 parprobe 刷新命令即可:

 partprobe /dev/sdc
```

### 格式化新分区

#### 格式化新分区: mkfs -t

这里建议将新分区格式化为 ext4 文件类型，还有 ext2，ext3 等文件类型，区别请参考博客 ext2、ext3 与 ext4 的区别。

```shell
 mkfs -t ext4 /dev/sdb1
mke2fs 1.41.12 (17-May-2010)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
134217728 inodes, 536870202 blocks
26843510 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=4294967296
16384 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968,
        102400000, 214990848, 512000000

Writing inode tables:  8874/16384
```

等待一小会后, 将出现下述提示, 说明格式化完成:

```shell
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information:  done

This filesystem will be automatically checked every 26 mounts or
180 days, whichever comes first.  Use tune2fs -c or -i to override.
```

### 挂载新分区

#### 创建目录, 并将 /dev/sdb1 挂在到该目录下:

```shell
[root@localhost /]# mkdir data && cd /data
[root@localhost data]# mount /dev/sdc1 /data
```

#### 查看挂载是否成功:

```shell
[root@localhost data]# df -l
Filesystem                   1K-blocks       Used  Available Use% Mounted on
/dev/mapper/VolGroup-LogVol  286901696   18601728  253726196   7% /
tmpfs                         66020980          0   66020980   0% /dev/shm
/dev/sda1                       495844      33476     436768   8% /boot

# 挂载成功:
/dev/sdb1                   2113784984     202776 2006208168   1% /data
```

### 设置开机自动挂载

编辑文件 /etc/fstab

```shell
[root@localhost data]# vim /etc/fstab

# 文件内容如下:
# /etc/fstab
# Created by anaconda on Wed Sep 12 10:41:40 2018
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
/dev/mapper/VolGroup-LogVol  /                     ext4    defaults        1 1
/dev/sdb1                    /data                 ext4    defaults        1 1
UUID=22b1d425-d050-43c3-a735-06d48bbb9051 /boot    ext4    defaults        1 2
tmpfs                        /dev/shm              tmpfs   defaults        0 0
devpts                       /dev/pts              devpts  gid=5,mode=620  0 0
sysfs                        /sys                  sysfs   defaults        0 0
proc                         /proc                 proc    defaults        0 0
```

## LVM 方式挂载磁盘(推荐)

### 创建PV，VG，LV的指令

``` shell
创建物理卷
pvcreate /dev/vdb1            ##创建物理卷/dev/vdb1
创建物理卷组
vgcreate vg0 /dev/vdb1        ##创建物理卷组vg0
创建逻辑卷
lvcreate -L 300M -n lv0 vg0   ##在vg0卷组上创建名为lv0，大小为300M的逻辑卷
```

### 创建一个逻辑卷（操作展示）
```shell
fdisk /dev/vda
```
![更改分区类型](/images/change_disk_type.png)

``` shell
pvcreate /dev/vdb1            #创建物理卷
vgcreate -s 8M vg0 /dev/vdb1  #创建物理卷组vg0,PE为8M
lvcreate -L 300M -n lv0 vg0   #在卷组vg0上创建名为lv0，大小为300M的逻辑卷
mkfs.xfs /dev/vg0/lv0         #格式化逻辑卷并改系统格式为xfs
mount /dev/vg0/lv0 /mnt       #挂载(linux下的文件系统需要被挂载后才能使用)
df -h
```

### 扩容
#### xfs系统中的扩容：
**情况一：vg足够扩展**
``` shell
lvextend -L 500M /dev/vg0/lv0      ##扩展逻辑卷空间到500M
xfs_growfs /dev/vg0/lv0            ##扩展文件系统
```
**情况二：vg不够拉伸，得先扩大设备再扩大系统**

扩大设备
``` shell
pvcreate /dev/vdb2        ##创建物理卷/dev/vdb2 
vgextend vg0 /dev/vdb2    ##将新的物理卷vdb2添加到现有的卷组vg0 
```
扩展逻辑卷
``` shell
lvextend -L 1500M /dev/vg0/lv0     ##增加逻辑卷空间到1500M 
xfs_growfs /dev/vg0/lv0
```

### ext4系统的扩容

``` shell
umount /mnt              ##先卸载 
mkfs.ext4 /dev/vg0/lv0   ##格式化逻辑卷 ，并改系统为ext4
mount /dev/vg0/lv0 /mnt/ ##挂载 
lvextend -L 1800M /dev/vg0/lv0  ##增加逻辑卷空间 
Extending logical volume lv0 to 1.76 GiB Logical volume lv0 successfully resized 
resize2fs /dev/vg0/lv0   ##更新逻辑卷信息
```

### 缩减逻辑卷空间

``` shell
umount /mnt                     ##先卸载
e2fsck -f /dev/vg0/lv0          ##扫描逻辑卷上的空余空间
resize2fs /dev/vg0/lv0 1000M    ##设备文件减少到1000M
lvreduce -L 1000M /dev/vg0/lv0  ##将逻辑卷减少到1000M
mount /dev/vg0/lv0 /mnt         ##挂载
```

### 缩减vg：（迁移到闲置设备）

``` shell
pvmove /dev/vdb1 /dev/vdb2  ##将vdb1的空间数据转移到vdb2
  /dev/vdb1: Moved: 88.0%
  /dev/vdb1: Moved: 100.0%  ##转移数据成功
vgreduce vg0 /dev/vdb1      ##将/dev/vdb1分区从vg0卷组中移除
  Removed "/dev/vdb1" from volume group "vg0"
pvremove /dev/vdb1          ##把/dev/vdb1分区从系统中删除
  Labels on physical volume "/dev/vdb1" successfully wiped
```

> 注意：将vdb1的空间数据转移到vdb2时，要确保vdb2的足够的空间能将vdb1的数据转移，否则需要先将vdb1缩减。

### LVM快照创建

``` shell
touch /mnt/file{1..5}
lvcreate -L 50M -n lv0backup -s /dev/vg0/lv0  ##建立一个50M的快照
mount /dev/vg0/lv0backup /mnt                 ##挂载快照
cd /mnt
ls
rm -fr *                                   ##删除所有文件
cd
umount /mnt
lvremove /dev/vg0/lv0backup                   ##删除快照
lvcreate -L 50M -n lv0backup -s /dev/vg0/lv0  ##重建快照
mount /dev/vg0/lv0backup /mnt                 ##挂载快照
ls /mnt                                ##又可以看到之前建立的文件
```

结论： LVM的快照可以将某一时刻的信息记录到快照区中，因此，可以利用这一特点对数据做完全备份。

### 删除设备

``` shell
umount /mnt  ##卸载
df -h
lvremove /dev/vg0/lv0backup    ##删除快照
lvremove /dev/vg0/lv0         ##删除逻辑卷
vgremove vg0                  ##删除物理卷组
pvremove /dev/vdb{1..2}       ##删除物理卷
```