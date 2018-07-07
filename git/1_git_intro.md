# git使用简介

## git文件组织结构概述

仓库是组织单元。

仓库保存着每个文件的每个版本。

下载到本地时，所有文件的每个版本都会被下载（默认是这样)

## 空间与文件状态

git空间可以分为三种：

1. 工作空间，从git上克隆下来的仓库的根目录。
2. 暂存空间(stage)，用于向服务器提交的空间。
3. git仓库：提交到远程服务器的文件。

基本的 Git 工作流程如下：

1. 在工作目录中修改某些文件。
2. 对修改后的文件进行快照，并保存到暂存区域。
3. 提交更新，将保存在暂存区域的文件快照永久转储到 Git 目录中。

相应的，文件状态可以分为：

- 如果是 Git 目录中保存着的特定版本文件，就属于已提交状态；
- 如果作了修改并已放入暂存区域，就属于已暂存状态；
- 如果自上次取出后，作了修改但还没有放到暂存区域，就是已修改状态。

## 运行前的配置

使用 git-config 命令来配置。

#### 配置文件存储位置

- `/etc/gitconfig` 文件：系统中对所有用户都普遍适用的配置。若使用 `git config` 时用 `--system` 选项，读写的就是这个文件。

- `~/.gitconfig` 文件：用户目录下的配置文件只适用于该用户。若使用 `git config` 时用 `--global` 选项，读写的就是这个文件。

- 当前项目的 Git 目录中的配置文件（也就是工作目录中的 `.git/config` 文件）：这里的配置仅仅针对当前项目有效。

每一个级别的配置都会覆盖上层的相同配置，所以 `.git/config` 里的配置会覆盖`/etc/gitconfig` 中的同名变量。

#### 用户信息

包括用户名和邮箱。

```bash
$ git config --global user.name "John Doe"
$ git config --global user.email johndoe@example.com
```

参数`global`指代用户目录下的配置文件。

#### 文本编辑器

修改默认的git文本编辑器

```bash
$ git config --global core.editor emacs
```

#### 差异分析器

修改默认的git差异分析器

```bash
$ git config --global merge.tool vimdiff
```

#### 查看配置信息
要检查已有的配置信息，可以使用 `git config --list` 命令：
```
$ git config --list
user.name=Scott Chacon
user.email=schacon@gmail.com
...
```
有时候会看到重复的变量名，那就说明它们来自不同的配置文件（比如 `/etc/gitconfig` 和 `~/.gitconfig`），不过最终 Git 实际采用的是最后一个。

也可以直接查阅某个环境变量的设定，只要把特定的名字跟在后面即可，像这样：

```
$ git config user.name
Scott Chacon
```
## 获取帮助

想了解 Git 的各式工具该怎么用，可以阅读它们的使用帮助，方法有三：

```
$ git help <verb>
$ git <verb> --help
$ man git-<verb>

```

比如，要学习 config 命令可以怎么用，运行：

```
$ git help config
```

