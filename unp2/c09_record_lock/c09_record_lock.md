# 第9章 记录上锁

## 9.1 概述

记录上锁用于在进程间共享文件(而不是线程间)。

通常在内核维护，其属主是由属主的进程ID标识的。

本章例程：
读取某文件中的整数，数值加一，然后存回文件。

##### 主函数
```c
#include "unp.h"
#define SEQFILE "seqno"
void my_lock(int), my_unlock(int);
int main(){
    int fd;
    long i,seqno;
    pid_t  pid;
    ssize_t n;
    char line[MAXLINE+1];
    pid=getpid();
    fd= Open(SEQFILE,O_RDWR,FILE_MODE);
	for(i=0; i<20; i++){
		my_lock(fd);
		Lseek(fd,0L,SEEK_SET);
		n=Read(fd,line,MALINE);
		line[n]='\0';
		n=sscanf(line,"%ld\n",&seqno);
		printf("%s:pid=%ld,seq# =%ld\n",argv[0],(long)pid,seqno);
		seqno++;
		snprintf(line,sizeof(lien),"%ld\n",seqno);
		Lseek(fd,0L,SEEK_SET);
		Write(fd,line,strlen(line));
		my_unlock(fd);
	}
	exit(0);
}  // code 9-2
```
##### my_lock与my_unlock函数
这里简单设置为空。
```c
void my_lock(){}
void my_ulock(){}
```
##### 调用
先设定文件内的整数为0，然后调用命令行
```bash
# prog & prog &
```
如果每个程序自加40次，最后的结果是40.但是测试发现并非这样。应做同步，保护文件访问。

可能的出错方式参考后续节。

注意：调用程序在后台运行，此命令行会立即返回。但是后台程序的标准输出会打印在控制台。
##### 要点
- 在打印进程号时，需要把pid_t强制转换为long类型。因为前者可能是int或long，所以用long可以达到最大的兼容性。
    > 参考: yang-sk/note/c/ 目录中”C语言强制类型转换“相关内容。
- 后台进程可能会在控制台上进行输出

## 9.2 对比记录上锁与文件上锁

记录上锁：可以指定文件中上锁的字节范围。
- Posix记录上锁指定 起始偏移和长度均为零时，字节范围是整个文件。   
- 即: 文件上锁是记录上锁的一个特例      

粒度(granularity)标识操作对象的尺度级别。    
- 如果粒度是文件，则无法在同一时间对文件进行多个互斥性的操作。
- 记录上锁的粒度是字节，可以对文件的不同字节范围进行同时操作。
- 文件通常是最粗的粒度，记录通常是最细的粒度。

## 9.3 Posix fcntl 记录上锁
记录上锁的接口是fcntl函数。
```c
#include<fcntl.h>
int fcntl(int fd,int cmd, ... /* struct flock *arg */);
返回：成功则取决cmd 出错-1
```
记录上锁时，第三个参数是必要的，它指向一个flock结构体。
```c
struct flock{
    short l_type; 	// F_RDLCK,F_WRLCK,F_UNLCK
	short l_whence; // SEEK_SET SEEK_CUR SEEK_END
	off_t l_start; 	// relative starting offset in bytes
	off_t l_len;	// bytes; 0 means until end-of-file
	pid_t l_pid;	// PID returned by F_GETLK
}
```
注意：不同实现可能有不同的成员顺序，因此避免使用列表初始化。

操作类型有三种：

##### F_SETLK 获取或释放锁
获取(l_type成员为F_RDLCK或F_WRLCK)或释放( l_type成员为F_UNLCK)由arg指向的flock结构所描述的锁。
如果无法将该锁授予调用进程，该函数就立即返回一个EACCES或EAGAIN错误而不阻塞。

##### F_SETLKW 获取或释放锁
该命令是上一个命令的阻塞版本，如果无法将所请求的锁授予调用进程，调用线程会阻塞。(该命令中字母W即为“Wait”)

##### F_GETLK 检查是否可以获取锁
检查由arg指向的锁以确定是否有某个已存在的锁会妨碍将新锁授予调用进程。 如果当前没有这样的锁存在，由arg指向的flock结构的l_type成员就被置为F_UNLCK。
否则， 关于这个己存在锁的信息将在由arg指向的flock结构中返回，包括持有该锁的进程的进程ID。

应清楚发出F_GETLK命令后紧接着发出F_SETLK命令不是一个原子操作。
这就是说，如果我们发出F_GETLK命令检查发现可以获取锁，那么跟着立即发出F_SETLK命令不能保证成功上锁。 这两次调用之间可能有另外的进程获取了锁。

提供F_GETLK命令的原因在于：当执行F_SETLK命令的fcntl函数返回错误时， 导致该错误的某个锁的信息可由F_GETLK命令返回， 从而允许我们确定是哪个进程锁住了所请求的文件以及上锁方式(读出锁或写入锁)。 但是即使是这样的情形， F_GETLK命令也可能返回该文件已解锁的信息， 因为在F_SETLK和F_GETLK命令之间， 该文件区可能被解锁。

> 当前是否允许上锁取决于其他进程是否占用该锁，而非本进程内是否占用该锁。因为进程可以对同一个字节范围多次上锁，新操作会覆盖先前的操作，不会因为重复上锁而报错。
> 例如：本进程中上锁后调用检查锁命令，依然返回UNLOCK。因为本进程内可以多次上锁，当前状态不阻碍获取锁。(如果此时无其他进程干扰)

> 互斥锁和读写锁似乎也有类似情况。

> 文件能否读写与文件的字节范围是否被锁无关(前提是劝告性上锁)，前者由文件访问权限完全决定。记录上锁是劝告锁，进程可以无视上锁而强行访问资源本身。只要有权限就可以访问，不论是否被锁。当然这样可能违反了协作。

flock结构描述锁的类型( 读出锁或写入锁) 以及待锁住的字节范围。 跟lseek一样， 起始字节偏移是作为一个相对偏移( l_start成员) 伴随其解释( l_whence成员) 指定的。 

l_whence成员有以下三个取值：
• SEEK_SET: 	相对于文件的开头解释。
• SEEK_CUR: 	相对于文件的当前字节偏移( 即当前读写指针位置) 解释。
• SEEK_END: 	相对于文件的末尾解释。

l_len成员指定从该偏移开始的连续字节数。长度为0意思是“ 从起始偏移到文件偏移的最大可能值”。

因此， 锁住整个文件有两种方式。

1. 指定l_whence成员为SEEK_SET， l_start成员为0， l_len成员为0。
2. 使用lseek把读写指针定位到文件头，然后指定l_whence成员为SEEK_CUR, l_start成员为0, l_len成员为0。

第一种方式最常用， 因为它只需一个函数调用(fcntl) 而不是两个。

fcntl记录上锁既可用于读也可用于写， 对于一个文件的任意字节， 最多只能存在一种类型的锁( 读出锁或写入锁)。 而且， 一个给定字节可以同时占用多个读出锁，但只能有一个写入锁。 这与第8章的读写锁是一致的。 

当一个描述符不是打开来用于读时， 如果对它请求一个读出锁， 错误就会发生， 同样，如果不是打开来用于写，请求一个写入锁， 错误也会发生。

对于一个打开着某个文件的进程来说，当它关闭该文件的所有描述符或它本身终止时， 与该文件关联的所有锁都被删除。
> 确实如此， 甚至于所关闭的描述符先前是在其文件己由本进程( 通过该文件的另一个描述符)上锁后才打幵也不例外.肴来删除锁时关键的是进程ID, 而不是引用同一文件的描述符数目及打幵目的(只读、 只写、 读写)。既然锁跟进程1D紧密关联， 它不能通过fork由子进程继承也就顺理成章， 因为父子进程有不同的进程ID。(译者注)
> 注：上述大概是说，即使文件先上锁，后打开，关闭时也会清理锁。

锁不能通过fork由子进程继承。

> 进程结束时内核自动清理锁的情况，只有fcntl记录锁实现了。System V信号量則把它作为一个选項提供. 其他同步技巧( 互斥锁、 条件变量 、读写锁、Posix信号量)并不在进程终止时执行清理工作.我们已在7.7节末尾讨论过这一点.

记录上锁不应该同标准I/O函数库一块使用， 因为该函数库会执行内部缓冲。为避免问题，应使用read和write。

### 例子

```c
void my_lock(int fd){
    struct flock lock; 
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    lock.1_start = 0;
    lock.l_len = 0;     /* write lock entire file */
    Fcntl(fd,F_SETLKW,&lock);
}
void my_unlock{int fd){
    struct flock lock;
    lock.l_type = F_UNLCK;
    lock.l_whence = SEEK_SET;
    lock.1_start = 0; 
    lock.l_len = 0;      /* unlock entire file */
    Fcntl(fd, F_SETLK, &lock) ;
}  // code 9-3
```

例子：简化的宏

通过定义来自APUE的12.3节的以下宏，简化代码(主要是填写成员的步骤)

注：测试发现ubuntu未定义该宏

```c
#define read_lock(fd, offset, whence, len) \
    lock_reg(fd, F_SETLK, F_RDLCK, offset, whence, len)
#define readw_lock(fd, offset, whence, len) \
    lock_reg(fd, F_SETLKW, F_RDLCK, offset, whence, len)
#define write_lock(fd, offset, whence, len) \
    lock_reg(fd, F_SETLK, F_WRLCK, offset, whence, len)
#define writew_lock(fd, offset, whence, len) \
    lock_reg(fd, F_SETLKW, F_WRLCK, offset, whence, len)
#define un_lock(fd, offset, whence, len) \
    lock_reg(fd, F_SETLK, F_UNLCK, offset, whence, len)
#define is_read_lockable(fd, offset, whence, len) \
    !lock_test(fd, F_RDLCK, offset, whence, len)
#define is_write_lockable(fd, offset, whence, len) \
    !lock_test(fd, F_WRLCK, offset, whence, len)
```

这些宏的前三个参数有总安排成跟iseek函数的前三个参数相同。

这些宏使用我们的 lock_reg和lock_test函数，

```c
int lock_reg(int fd , int cmd, int type, off_t offset, int whence, off_t len){
    struct flock lock;
    lock.l_type = type;         /* F_RDLCK, F_WRLCK, F_UNLCK */
    lock.l_start = offset;      
    lock.l_whence = whence;     /* SEEK_SET, SEEK_CUR, SEEK_END */
    lock.l_len = len;
    return fcntl(fd, cmd, &lock);  // -1 upon error 
}  //code 9-4
```

```c
pid_t lock_test(int fd, int type, off_t offset, int whence, off_t len){
    struct flock lock;
    lock.l_type = type;
    lock.l_start = offset;
    lock.l_whence = whence;
    lock.l_len = len;
    if(fcntl(fd, F_GETLK, &lock) == -1)
        return (-1);                /* unexpected error */
    if(lock.l_type == F_UNLCK)
        return (0) ;            /* false, region not locked by another proc*/
    return(lock.l_pid) ;        /* true, return positive PID of lock owner */
}  // code 9-5
```

## 9.4 劝告性上锁

上锁是为了保护特定的资源，避免访问冲突。

劝告性上锁：
- 访问资源时，需要显式对某个锁对象进行上锁和解锁。
- 进程可以无视劝告性上锁强行访问资源(如果有权限)。
- 劝告上锁正常运作的前提，是所有访问资源的进程共同遵循正确的上锁和解锁规则。

## 9.5 强制性上锁

强制性上锁：
- 仅由某些系统提供。
- 内核会检查read和write请求，在访问冲突时执行阻塞或报错。

强制性上锁实际上很难顺利运作。例如本章例程中，以下三步
1. 取出文件中整数

2. 数值加一 

3. 写入文件

是一套完整的操作，它们被放入临界区中，互不冲突。但强制上锁仅保证读写互不冲突。

在下面情况中就发生了错误，类似于多线程与寄存器变量出错的情形。

```
文件中初始数值为1
进程1  取值(1)------------加一(2)------------写入(2)
进程2           取值(1)---加一(2)---写入(2)
```

强制性上锁会增加内核时间消耗，主要用于检查各个read和write调用情况。

> 参考：9.5强制性上锁

## 9.6 读出者和写入者的优先级
假设某个锁被当前进程占用，其他进程在等待该锁。当前进程释放锁以后，该锁是优先交给读进程还是写进程？这是posix未说明的。不同实现可能不同。

优先读：大量的读请求可能让写无限延后，导致数据更新滞后。
优先写：强调数据的更新，似乎更合理些。

原书中给出例程进行测试，参考原书：9.6读出者和写入者的优先级。
笔者未测试。

## 9.7 启动一个守护进程的唯一副本

记录上锁的一个常见用途就是实现某程序只运行唯一副本。

进程启动时尝试上锁某文件：
- 如果上锁成功，则保持占用，直至进程结束; 
- 如果上锁失败，证明有相同进程在运行，则终止本进程。

```c
int main(){
    int pidfd;
    char line[MAXLINE];
    /* open the PID file, create if nonexistent */
    pidfd = Open(PATH_PIDFILE, C_RDWR | O_CREAT, FILE_MODE);

    /* try to write lock the entire file */
    if (write_lock(pidfd, 0,SEEK_SET, 0) < 0) {
        if(errno == EACCES || errno == EAGAIN)
            err_quit("unable to lock %s, is %s already running?",
PATH_PIDFILE, argv[0]);
        else
            err_sys("unable to lock %s", PATH_PIDFILE);
}
    /* write my PID, leave file open to hold the write lock */
    snprintf(line, sizeof(line), "%ld\n", (long)getpid());
    Ftruncate(pidfd, 0);
    Write(pidfd, line, strlen(line) ) ; 

    /* then do whatever the daemon does ... */
    pause();
}   // code 9-11
```
要点

- 保证独占，使用写入锁(而非读出锁)


- 写入文件时记得截短，以清理文件原有内容
- 文件内写入进程ID方便查看管理

还有其他方法防止自身另一个副本启动， 譬如说可能使用信号量。记录锁的优势在于， 许多守护程序都编写成向某个文件写入本进程ID, 而且如果某个守护进程过早崩溃了， 那么内核会自动释放它的记录锁。

## 9.8 文件作为锁来使用

打开文件时指定O_CREAT与O_EXCL，那么如果文件已存在则返回错误。而"检查文件是否存在"与“创建文件”都是原子的，所以利用这些特性可以实现跨进程的锁。

文件本身的存在代表锁的存在。上锁的过程就是创建文件; 解锁的过程就是unlink文件(从文件系统中删除)。

上锁时若文件已存在，则别的进程无法创建，因而无法上锁，以此实现同步。

> 原书中认为此部分是陈旧的方式，应该使用记录锁取代。详细内容参考原书9.8章节。

## 9.9 NFS上锁

NFS是网络文件系统。NFS的大多数实现支持fcntl记录上锁。 

Unix系统通常以两个额外的守护进程支持NFS记录上锁， 它们是lockd和statd。当某个进程调用fcntl以获取一个锁，而且内核检测出其描述符引用通过NFS安装的某个文件系统上的一个文件时，本地的lockd就向服务器的lockd发送这个请求。statd守护进程跟踪着持有锁的各个客户，它与lockd交互以提供NFS上锁的崩溃恢复功能。

NFS文件的记录锁比本地文件的记录上锁花的时间长，因为需要网络通信。

fcntl记录上锁在NFS上应该起作用，但是某些实现并不理想。

## 习题

问：如果不对标准输出进行缓冲，这样的修改有什么效果？

答：多线程中应避免使用标准IO，因为有缓冲区的存在，导致输出不是即时的。

要使得标准IO流不做缓冲(即时输出)，可以用`setvbuf(stdout,NULL,_IONBF,0)`

通常情况下，标准输出是行缓冲的。如果输出内容末尾有换行，会立即输出，就不会启用缓冲。此时printf调用就会变为write调用。

问：如果不使用printf而是逐个字符输出？

答：那么在多线程中，各线程的字符可能错误地交叉混杂。

Tip: 设置某个文件描述符的非阻塞标志，对记录上锁没有影响。

问： 在使用记录锁实现唯一副本时，能否用O_TRUNC截断模式打开文件？

答：不能，如果本进程的另一个副本正在运行，截断模式打开文件时会冲掉文件内的数据。
所以正确的方式是打开文件，检查是否上锁并进行确认。只有在确定自己是唯一副本时才可以截掉文件内容。

问：使用记录锁时，应该尽量指定哪种偏移基准？

答：使用记录锁时，尽量使用SEEK_SET。

原因如下：

- SEEK_CUR是相对于当前偏移量(即当前文件指针)。使用时可能需先用lseek偏移某个量，然后再使用记录锁。那么这两个步骤之间，可能有别的线程也调用了lseek，导致偏移量并非预期。
- SEEK_END是相对于文件尾。在上锁操作之前，可能有别的进程修改了文件尾(例如增减数据)，使得基准发生改变。
