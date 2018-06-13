# 第5章 posix消息队列

## 5.1 概述
消息队列可认为是一个消息链表。有足够写权限的线程可往队列中放置消息， 有足够读权限的线程可从队列中取走消息。 

每个消息都是一个记录（它是有消息边界的），它由发送者陚予一个优先级。 在某个进程往一个队列写入消息之前， 并不需要另外某个进程在该队列上等待消息的到达。 这跟管道和FIFO是相反的， 对后两者来说， 除非读出者己存在， 否则先有写入者是没有意义的。

一个进程可以往某个队列写入一些消息， 然后终止，再让另外一个进程在以后某个时刻该
出这些消息。 我们说过消息队列具有随内核的持续性（ 1.3节）， 这跟管道和FIFO不一样。 当一个管道或FIFO的最后一次关闭发生时， 仍在该管道或FIFO上的数据将被丢弃。

本章讲述Posix消息队列， 第6章讲述System V消息队列。这两组函数间存在许多相似性，下面是主要的差别。
- 对Posix消息队列的读总是返回最高优先级的最早消息， 对SystemV消息队列的读则可以返回任意指定优先级的消息。
- 当往一个空队列放置一个消息时， Posix消息队列允许产生一个信号或启动一个线程，System V消息队列则不提供类似机制。

队列中的每个消息具有如下属性：
- 一个无符号整数优先级（ Posix) 或一个长整数类型（SystemV);
- 消息的数据部分长度（ 可以为0);
- 数据本身（ 如果长度大于0)。

注意这些特征不同于管道和FIFO。 后两者是字节流模型， 没有消息边界， 也没有与每个消息关联的类型。 

图5-1展示了一个消息队列的可能布局

链表头中含有两个属性： 队列中允许的最大消息数以及每个消息的最大大小。 

## 5.2 mq_open,mq_close和mq_unlink

mq_open函数创建一个新的消息队列或打开一个己存在的消息队列。
```c
#include <mqueue.h>
mqd_t mq_open(const char *name, int oflag , …
/* mode_t mode, struct mq_attr* attr */ )；
返回： 若成功则为消息队列描述符， 若出错则为-1
```
要点
- name参数遵守Posix命名规则。
- oflag参数是O_RDONLY、 O_WRONLY或O_RDWR之一， 可能按位或上O_CREAT、 O_EXCL或
O_NONBL0CK.
- 当实际操作是创建一个新队列时（已指定O_CREAT标志，且所请求的消息队列尚未存在），mode和attr参数是必要的。
- attr参数用于给新队列指定某些属性。如果为空则就使用默认属性。 

mq__open的返冋值称为消息队列描述符（ mesagequeuedescriptor)， 但它不必是（ 而且很可能不是） 像文件描述符或套接字描述符这样的短整数。 

己打开的消息队列是由mq_close 关闭的。
```c
# include <mqueue.h>
int mq_c1ose (rr.qd_t mqdes )；
返回： 若成功则为0, 若出错则为-1
```
其功能与关闭一个己打开文件的close函数类似： 调用进程可以不再使用该描述符，但其消息队列并不从系统中删除。 一个进程终止时， 它的所有打开着的消息队列都关闭， 就像调用mq_close—样。

要从系统中删除用作mq_open第一个参数的某个name，必须调用mq_unlink。
```c
#include <mqueue.h>
int mq_unlink (const char* name ) ；
返回： 若成功则为0. 若出错则为-1
```
每个消息队列有一个保存其当前打开着描述符数的引用计数器（就像文件一样）， 因而本函数能够实现类似于unlink函数删除一个文件的机制： 当一个消息队列的引用计数仍大于0时,其name就能删除， 但是该队列的析构（ 这与从系统中删除其名字不同） 要到最后一个mq_close
发生时才进行®。

> 一个消息队列的名字在系统中的存在本身也占用其引用计数器的一个引用数， unlink从系统中删除该名字意味着同时将其引用计数减1,若变为0則真正拆除该队列.一译者注
> 和unlink—样， mq_close也将当前消息队列的引用计数减1,若变为0则附带拆除该队列。 [但是不删除名字就永远不能到0]一译者注

思考：close和unlink笼统来说，一个是关闭，一个是删除。但是close和unlink更接近于使得某资源不再可用，而对资源的关闭/析构由内核在合适的时候完成。

思考：close所做的事情，一是使得目标文件在当前进程内不可用于读写等操作，二是减少引用计数。在计数为0时，内核关闭文件。unlink所做的事情，一是使文件名从文件系统中删除，不能被本进程和其他进程打开；二是减少引用计数，和close相同。【所以unlink一方面减少了文件名存在本身的引用计数，又减少了对资源访问的计数，后者猜测在unlink里面调用了close类似的操作。？】
内核在引用数为0时候析构资源。文件名的存在本身也是一个引用计数。

所以两者所做的：1.告诉内核该资源不再可用（在本进程不再做读写操作等，或文件名从文件系统中删除），2.减少引用计数。不过unlink在删除文件名时就减少了一次。


Posix消息队列至少随内核的持续.这就是说， 即使当前没有进程打开着某个消息队列， 该队列及其上的各个消息也将一直存在，直到调用mm_unlink并让它的引用计数达到0以删除该队列为止。

## 5.3 mq_getattr和mq_setattr函数
每个消息队列有四个属性， mq_getattr返回所有这些属性，mq_setattr则设置其中某个属性。
```c
#include <mqueue.h>
int mq_getattr(mqd_t mqdes, struct mq_attr *attr) ；
int mq_setattr(mqd_t mqdes , const struct mq_attr *attr , struct mq_attr *oattr)；
均返回： 若成功则为0, 若出错则为-1
```
mq_attr结构含有以下属性。
```c
struct mq_actr {
    long_flags;     /* message queue flag： 0, O_NONBLOCK */
    long mq_maxmsg； /* max number of messages allowed on queue */
    long mq_msgsize； /* max size of a message (in bytes) */
    long mq_curmsgs； /* number of messages currently on queue */
};
```
指向某个mq_attr结构的指针可作为mq_open的第四个参数传递， 从而允许我们在该函数
的实际操作是创建一个新队列时，给它指定mq_maxmsg和mq_msgsize属性，并忽略该结构的另外两个成员。

mq_getattr把所指定队列的当前属性填入由attr指向的结构。

mq_setattr给所指定队列设置属性，但是只使用由attr指向的mq_attr结构的mq_flags成
员， 以设置或清除非阻塞标志。 该结构的另外三个成员被忽略： 每个队列的最大消息数和每个消息的最大字节数只能在创建队列时设置， 队列屮的当前消息数则只能获取而不能设置。

另外， 如果oattr指针非空， 那么所指定队列的先前属性（ mq_flags、 mq_maxmsg和
mq_msgsize) 和当前状态（ mq_curmsgs) 将返回到由该指针指向的结构中。

用mq_open创建队列时，可以指定队列的最大消息数和最大消息长度，但是必须两者都指定。如果不需指定只需attr指针为空。

> 我们的Getopt包裏函数调用标准函数库中的getopt函数， 并在getopt检测到错谈时终止当前进程， 这些错误包括： 遇到一个没有包含在getopt:第三个参数中的选项字母， 或者遇到一个没有所需参数的选项字母（字母后跟冒号指示 ） .不论遇到哪种错误， getopt都将一个出错消息写到标准错误输出， 然后返回一个错误， 这个错误导致我们的Getopt包襄函數终止•

## 5.4 mq_send和mq_receive函数
分别用于往一个队列中放置和取走一个消息。
每个消息有一个优先级， 它是一个小于MQ_RPIO_MAX的无符号整数。 Posix要求至少为32
mq_receive总是返冋所指定队列中最高优先级的最早消息， 而且该优先级能随该消息的内容及其长度一同返回
```c
#include <mqueue.h>
int mq_send (mqd_t mqdes, const char *ptr, size_t len, unsigned int prio);
返回： 若成功则为0, 若出错则为-1
ssize_t mq_receive(mqd_t mqdes, char *ptr, size_t len, unsigned int *priop ) ；
返回: 若成功则为消息中字节数， 若出错则为-1
```

> 指针类型为char* ，其实void*更合适点。

mq_receive的/en参 数 的 值 不 能 小 P能 加 到 所 指 定 队 列 中 的 消 息 的 最 大 大 小 （ 该 队 列
mq_attr结 构 的mq_msgsize成员）。 要是/⑼小于该值， mq_receive就立即返回EMSGSIZE错误。
这意味着使用 Posix消息队列的大多数应用程序必须在打开某个队列后调用mq_getattr
确定最大消息大小， 然后分配一个或多个那样大小的读缓冲区。 

mq_send的/?r/o参数是待发送消息的优先级， 其值必须小T*MQ_PRIO_MAX。 如果mq_receive
的pr/冲参数是一个非空指针， 所返回消息的优先级就通过该指针存放。 如果应用不必使用优先
级不同的消息， 那就给mq^send指定值为0的优先级， 给mc^receive指定一个空指针作为其最
后一个参数。

> 0字节长度的消息是允许的。mq——receive可以返回0，表示0长度。这和read函数不同。

> 没有技术可以（权威地）标识消息的发送者，意味着发送者信息可以被伪造。

> size_t可以是无符号的int或long，所以假如要打印，最好强制转换为long.

## 5.5 消息队列限制

上文给出队列的两个限制，它们都是在创建该队列时建立的：
mq_mqxmsg   队列中的最大消息数；
mq_msgsize  给定消息的最大字节数。
这两个值都没有内在的限制。

消息队列的实现定义了另外两个限制：
MQ_OPEN_MAX 一个进程能够同时拥有的打开着消息队列的最大数 (Posix要求至少为8）
MQ_PRIO_MAX 消息的最大优先级值加1 (Posix要求至少为32)

这两个常值往往定义在<unistd.h>头文件中， 也可以在运行时通过调用sysccmf函数获
取， 如接下来的例子所示。
```c
    long open_max = sysconf(_SC_MQ_OPEN_MAX);
    long prio_max = sysconf(_SC_MQ_PRIO_MAX);
```

## 5.6 mq_notify函数
Posix消息队列允许异步事件通知（ asynchronous event notification )， 以告知何时有一个消息放置到了某个空消息队列中。 这种通知有两种方式可供选择：
- 产生一个信号；
- 创建一个线程来执行一个指定的函数。

这种通知通过调用mq_notify建立。
```c
#include <mqueue.h>
int mq_notify(mqd_t mqdes , const struct sigevent *notification ) ;
返回： 若成功则为0, 若出错则为-1
```
该函数为指定队列建立或删除异步事件通知。 sigevent结构是随Posix.1实时信号新加的，后者在下一节详细讨论。该结 构 以 及 本 章中引入的所有新的信号相关常值都定义在<signal .h>头文件中。
```c
union sigval {
    int     sival_int;
    void*   sival_ptr；
};
struct sigevent {
    int     sigev_notify;   /* SIGEV_{NONR,SIGNAL,THREAD} */
    int     sigev_signo;    /* signal number if SIGEV_SIGNAL */
    union   sigval  sigev_value;    // passed to signal handler or thread
    void    (*sigev_notify_function)(union sigval);
    pthread_attr_t  *sigev_notify_attributes;
};
```
我们马上给出以不同方法使用异步事件通知的几个例子，但在此前先给出一些普遍适用于该函数的若干规则。
1. 如果notification参数非空，那么当前进程希望在有一个消息到达所指定的先前为空的队列时得到通知。 我们说“ 该进程被注册为接收该队列的通知”。
2. 如果notification参数为空，而且当前进程目前被注册为接收所指定队列的通知，那么己存在的注册将被撤销。
3. 任意时刻只有一个进程可以被注册为接收某个给定队列的通知。
4. 当有一个消息到达某个先前为空的队列，而且已有一个进程被注册为接收该队列的通知时， 只有在没有任何线程阻塞在该队列的mq_receive调用中的前提下，通知才会发出。 这就是说， 在mq_reveive调用中的阻塞比任何通知的注册都优先。
5. 当该通知被发送给它的注册进程时， 其注册即被撤销。该进程必须再次调用mmotify
以重新注册（ 如果想要的话）。

> Unix最初的问题在于，信号被捕获后，其行为被复位，需要重新建立处理程序。但是复位和建立之间可能有信号被接收然后触发某些行为。乍看之下，消息队列的信号通知也有这种问题，然而，队列变空前通知不会发生。所以我们必须在从队列读取消息前（而不是之后）重新注册。

### 简单的程序
注意里面有个小错误

要点
- sigevent结构中sigev_notify成员填入SIGEV_SIGNAL表示，当队列由空变非空时，产生信号。然后将sigev_signo设置为指定的信号

```
#include "unpipc.h"
mqd_t mqd;
void *buff；
struct mq_attr aLtr；
struct sigevent sigev；

static void sig_usrl(int);

int main(int argc, char argv){
    if (argc !=2）
        err_quit("usage: mqnotifysigl <name>");
    /* open queue, get attributes, allocate read buffer */
    mqd = Mq_open(argv[1], O_RDONLY)；
    Mq_getattr(mqd, &attr);
    buff = Malloc(attr.mq_msgsize);
    /* establish signal handler, enable notification */
    Signal(SIGUSR1, sig_usrl);
    sigev.sigev_notify = SIGEV_SIGNAL；
    sigev.sigev_signo = SIGUSRl ;
    Mq_notify(mqd, &sigev);
    for ( ; ; )
        pause();        /* may get EINTR */
    exit(0);
}

static void sig_usrl(int signo){
    ssize_t n;
    Mq_notify(mqd, &sigev);     /* reregister first */
    n = Mq_receive(mqd, buff, attr.mq_msgsize, NULL);
    printf("SIGUSRl received, read %ld bytes\n", (long) n);
    return；
}
```

问题在于调用了不安全的异步信号函数

### Posix 信号： 异步信号安全函数

Posix使用异步信号安全（async-signal-safe ) 术语描述可以从信号处理程序中调用的函数。 图5-10列出了这些Posix函数以及由Unix 98加上的其他几个函数。
```
access          fpathconf       rename          sysconf
aio_return      fstat           rmdir           tcdrain
aio_suspend     fsync           sem_post        tcflow
alarm           getegid         setgid          tcflush
cfgetispeed     geteuid         setpgid         tcgetattr
cfgetospeed     getgid          setsid          tcgetpgrp
cfsetispeed     getgroups       setuid          tcsendbreak
cfsetospeed     getpgrp         sigaction       tcsetattr
chdir           getpid          sigaddset       tcsetpgrp
chmod           getppid         sigdelset       time
chown           getuid          sigemptyset     timer_getoverrun
clock_gettime   kill            sigfillset      timer_gettime
close           link            sigismember     timer_settime
creat           lseek           signal          times
dup             mkdir           sigpause        umask
dup2            mkfifo          sigpending      uname
execle          open            sigprocmask     unlink
exccve          pathconf        sigqueue        utime
_exit           pause           sigset          wait
fcntl           pipe            sigsuspend      waitpid
fdatasync       raise           sleep           write
fork            read            stat
```

注意所有标准I/O函数和pthread_AXY函数都没有列在其中。 本书所涵盖的所有IPC函数中， 只有sem_post、 read和write列在其中（ 我们假定read和write可用于管道和FIFO)

### 例子：信号通知
避免从信号处理程序中调用任何函数的方法之一是：处理程序仅仅设置一个全局标志，
由某个线程检査该标志以确定何时接收到一个信息。 

以下展示了这种技巧， 不过它含有另外一个错误， 我们不久会讲到。
本例中，降低了全局变量的个数，通常鼓励这样做。
```c
#include "unpipc.h"
volatile sig_atomic_t mqflag；
static void sig_usr1(int);

int main(int argc, char **argv){
    mqd_t mqd;
    void *buff;
    ssize_t n；
    sigset_t zeromask, newmask, oldmask;
    struct mq_attr attr；
    struct sigevent sigev；
    if (argc != 2)
        err_quit("usage: mapiotifysig2 <namf2>" );
    / * open queue, get attributes, allocate read buffer */
    mqd = Mq_open(argv[1], O_RDONLY);
    Mq_getattr(mqd, &attr)；
    buff = Malloc(attr.mq_msgsize);

    Sigemptyset(&zeromask)；
    Sigemptyset(&newmask)；
    Sigemptyset(&oldmask);
    Sigaddset(&newmask, SIGUSR1);   // for block SIGUSR1

    /* establish signal handler, enable notification */
    Signal(SIGUSR1, sig_usrl);
    sigev.sigev_notify = SIGEV_SIGNAL;
    sigev.sigev_signo = SIGUSR1；
    Mq_notify(mqd, &sigev ) ；

    for ( ; ; ) {
        Sigprocmask(SIG_BLOCK, &newmask, &oldmask);     // block SIGUSR1
        while (mqflag == 0)
           sigsuspend(&zeromask)；
        mqflag = 0;             /* reset flag */
        Mq_notify(mqd,&sigev);  // reregister first 
        n = Mq_receive(mqd, buff, attr.mq_msgsize , NULL)； // [problem code]
        printf("read %ld bytes\n", (long) n);
        Sigprocmask(SIG_UNBLOCK, &newmask , NULL);  //unblock SIGUSR1
    }
    exit(0);
}

static void sig_usrl(int signo){
    mqflag = 1;
    return;
}
```

调用sigprocmask阻塞SIGUSR1， 并把当前信号掩码保存到oldxnask中。 随后在一个循
环中测试全局变量mqflag, 以等待信号处理程序将它设置成非零。 只要它为0, 我们就
调用sigsuspend, 它原子性地将调用线程投入睡眠， 并把它的信号掩码复位成zeromask
( 没有一个信号被阻塞）。每次sigsuspend返回时， SIGUSR1被重新阻塞

思考：在处理SIGUSR1信号引发的操作时，要把该信号阻塞，应该是防止在处理期间遗漏了后来接收的SIGUSR1信号。【关于sigsuspend还不太了解】

存在的问题：假设两个消息被加入队列，此时只会触发一个信号，只会处理一次消息。所以应该在捕获信号后，读取所有的消息。

### 使用非阻塞mq_receive的信号通知
以非阻塞形式反复读取，直至返回出错信息。
```c
...
mqd=Mq_open(argv[1],O_RDONLY | O_NONBLOCK);     // [change]
...
for(;;){
    Sigprocmask(SIG_BLOCK, &newmask, &oldmask);
    while (mqflag == 0)
        sigsuspend(&zeromask )；
    mqflag = 0;              /* reset flag */
    Mq_notify(mqd, &sigev);
    // [change begin]
    while( (n = mq_receive(mqd, buff, attr.mq_msgsize, NULL))>=0){  
        printf("read %ld bytes\n", (long) n)；
    }
    if (errno != EAGAIN)
        err_sys("mq_receive error");
    // [change end]
    Sigprocmask(STG_UNBLOCK # Stnewmask, NULiL) ；
}
```
改动
1. 打开队列时指定非阻塞模式
2. 在一个循环内反复读取，返回EAGAIN表示没有数据可读

思考：也许可以用消息队列的“当前消息数目”属性来实现。

### 使用sigwait代替信号处理程序
上文调用sigsuspend阻塞， 以等待某个信号的到达。
更简易（并且可能更高效）的方法之一是阻塞在某个函数以等待该信号的递交，而
不是让内核执行信号处理程序。 sigwait提供了这种能力。
```c
#include <signal.h>
int sigwait(const sigset_t *set , int *sig ) ;
返回： 若成功则为0, 若出错则为正的Exxx值
```
调用sigwait前， 我们阻塞某个信号集。 我们将这个信号集指定为参数。 sigwait然后
一直阻塞到这些信号中有一个或多个待处理， 这时它返回其中一个信号。 该信号值通过指针sig存放， 函数的返冋值则为0。 这个过程称为 “问步地等待一个异步事件”： 我们是在使用信号，但没有涉及异步信号处理程序.

```c
#include "unpipc.h"
int main(int argc, char **argv){
    int signo；
    mqd_t mqd；
    void *buff；
    ssize_t n；
    sigset_t newmask；
    struct mq_attr attr ;
    struct sigevent sigev;
    if (argc != 2)
        err_quit{"usage： mqnotifysig4 <name>");
    // open queue, get attributes, allocaLe read buffer
    mqd = Mq_open(argv[1], RDONLY | O_NONBLOCK);
    Mq_getattr(mqd, &attr);
    buff = Malloc(attr.mq_msgsize);
    Sigemptyset(&newmask)；
    Sigaddset(&newmask, SIGUSR1) ；
    Sigprocmask(SIG_BLOCK, &newmask, NULL)；
    /* establish signal handler, enable notification */
    sigev.sigev_notify = SIGEV_SIGNAL;
    sigev.sigev_signo = SIGUSR1;
    Mq_notify(mqd, &sigev ) ；

    for(;;){
        Sigwait(&newmask, &signo);
        if(signo == SIGUSR1) {
            Mq_notify(mqd, &sigev);
            while ( (n = mq_receive(mqd, buff, attr.mq_msgsize, NULL)) >= 0){
                printf("read %ld bytesNn", (long) n)；
            }
            if (errno != EAGAIN)
                err_sys{"mq_receive error" ) ；
        }
    }
    exit(0);
}
```
> sigwait往往在多线程化的进程中使用。多线程化的进程中不能使用sigprocmask，而应用pthread_sigmask(参数与前者相同).
> sigwait 存在两个变种： sigwaitinfo和sigtimedwait, sigwaitinfo还返回一个
siginfo_t结构（将在下一节中定义 ）,目的是用于可靠信号中.sigtimedwait也返回一个siginfo_t结构， 并允许调用者指定一个时间限制.
> 大多数讨论线程的书推荐在多线程化的进程中使用sigwait来
处理所有佶号， 而绝不要使用异步信号处理程序 •

### 使用select的Posix消息队列
消息队列描述符不同与普通描述符，不可用在select和poll中。本例中，设定消息通知触发信号，信号处理函数向一个管道写入数据（write是异步信号安全的）。管道可以用在select和poll，因而可以实现IO复用。

```c
#include "unpipc.h"
int     pipefd[2]；
static void sig_usr1(int);

int main(int argc, char **argv){
    int     nfds;
    char    c;
    fdset   rset;
    mqd_t mqd;
    void *buff;
    ssize_t n;
    struct mq_attr attr；
    struct sigevent sigev；
    if (argc != 2)
        err_quit("usage: mqnotifysig5 <name>");
     /* open queue, get attributes, allocate read buffer */
    mqd = Mq_open(argv[1], O_RDONLY | O_NONBLOCK);
    Mq_getattr(mqd, &attr);
    buff = Malloc(attr.mq_msgsize);
    
    Pipe(pipefd);
    /* establish signal handler, enable notificat,ion */
    Signal(SIGUSR1, sig_usr1);
    sigev.sigev_notify = SIGEV_SIGNAL;
    sigev.sigev_signo = SIGUSR1；
    Mq_notify(mqd, &sigev);
    FD_ZERO(&rset );
    for ( ; ; ) {
        FD_SET(pipefd[0], &rset);
        nfds = Select(pipefd[0] + 1, &rset, NULL, NULL, NULL)；
        if(FD_ISSET(pipefd[0], &rset)) {
            Read(pipefd[0], &c, 1);
            Mq_notify(mqd, &sigev ) ；  /* reregister first */
            while ( (n = mq_receive(mqd, buff, attr.mq_msgsize, NULL)) >= 0){
                printf("read %ld bytes\n", (long) n)；
            }
            if (errno != EAGAIN)
                err_sys("mq_receive error”)；
        }
    }
    exit(0);
}

static void sig_usrl(inc signo){
    Write(pipefd[1]，"", 1 ) ；     / * one byte of 0 * /
    return；
}
```
注意只在信号处理函数内写入管道一个字符，它只起到通知作用。

### 例子：启动线程
异步事件通知的另一种方式是把sigev_notify设置成SIGEV_THREAD，这会创建一个新的
线程。 该线程调用由sigev_notify_function指定的函数，所用的参数由sigev_value指定。
新线程的线程属性由sigev_notify_attributes指定， 空指针表示默认属性。 

我们把给新线程的参数 ( sigev_value) 指定成一个空指针， 因此不会有任何东西传递给该线程的起始函数。 我们能以参数的形式传递一个指向所处理消息队列描述符的指针， 而不是
把它声明为一个全局变量， 不过新线程仍然需要消息队列M性和sigev结构（ 以便重新注册）。

我们把给新线程的属性指定成一个空指针， 因此使用的是系统默认属性。 这样的新线程是作为脱离的线程创建的。

> 遗憾的是，当前有的实现不支持该小节内容。

```c
#include "unpipc.h"
mqd_t mqd;
struct mq_attr attr;
struct sigevent sigev；
static void notify_thread(union sigva1)；   /* our thread function */
int main(int argc, char **argv){
    if (argc != 2)
        err_quit ( ” usage: mqnoti fythreadl <name> ");
    mqd = Mq_open(argv[1] , O_RDONLY | O_NONBLOCK);
    Mq_getattr(mqd, &attr);
    sigev.sigev_notify = SIGEV_THREAD;
    sigev.sigev_value.sival_ptr = NULL；
    sigev.sigev_notify__function = notify_thread；
    sigev.sigev_notify_attributes = NULL;
    Mq_notify(mqd, &sigev);

    for ( ； ； ){
        pause(); /* each new thread does everything */
    exit(0);
}

static void notify_thread(union sigval arg){
    ssize_t n;
    void *buff；
    printf("notify_thread started\n");
    buff = Malloc(attr.mq_msgsize ) ；
    Mq_notify(mqd, &sigev); /* reregister * /
    while ( (n = mq_receive(mqd, buff, attr.mq_msgsize, NULL)) >= 0) {
        printf("read %ld bytes\n", (long) n ) ；
    if (errno != EAGAIN)
        err_sys("receive error”） ；
    pthread_exit(NULL);
}
```

## 5.7 Posix实时信号

信号可划分为两个大组。
1. 其值在SIGRTMIN和SIGRTMAX之间（ 包括两者在内） 的实时信号。 Posix要求至少提供
RTSIG_MAX种实时信号， 而该常值的最小值为8。
2. 所有其他信号： SIGALRK、 SIGINT、 SIGKILL, 等等。

接下来我们关注接收某个信号的进程的sigaction调用中是否指定了新的SA_SIGINFO标
志。 只有信号类型是实时信号且指定该标志的情况下，实时行为才是有保证的。否则不同实现可能情况不同。

实时行为（realtime behavior) 隐含着如下特征。
- 信号是排队的。 这就是说，如果同一信号产生了三次，它就递交三次。另外，一种给定信号的多次发出以先进先出(FIFO)顺序排队。
对于不排队的信号来说， 产生了三次的某种信号可能只递交一次。
- 当有多个SIGRTMIN到SIGRTMAX范围内的解阻塞信号排队时， 值较小的信号先于值较大
的信号递交。 这就是说，SIGRTMIN比值为SIGRTMIN+1的信号“更为优先”。
- 当某个非实时信号递交时， 传递给它的信号处理程序的唯一参数是该信号的值。 实时信号比其他信号携带更多的信息。 通过设胃SA_SIGINFO标志安装的实时信号的信号处
理程序声明如下：
```c
void func(int signo , siginfo_t *info, void *context);
```
其中signo是该信号的值，siginfo_t结构则定义如下:
```c
typedef struct {
    int si_signo;           // same value as signo argument 
    int si_code;            /* SI_{USER,QUEUE,TIMER,ASYNCIO,MEGEQ} */
    union sigval si_value;  /* integer or pointer value from sender */ 
} siginfo_t;
```

context参数所指向的内容依赖于实现。

> siginfo_t是使用typedef定义的具有以_t结尾的名字的唯一一个Posix结构.
声明时而不出现struct一词

- 一些新函数定义成使用实时信号工作。 例如，sigqueue函数用于代替kill函数向某个进程发送一个信号， 该新函数允许发送者随所发送信号传递一个sigval联合。

实时信号由下列Posix.l特性产生，它们由包含在传递给信号处理程序的siginfo_t结构中的si_code值来标识。
- SI_ASYNCIO 信号由某个异步I/O请求的完成产生， 这些异步I/O请求就是Posix的aio_
XXX 函数， 我们不讲述。
- SI_MESGQ 信号在有一个消息被放置到某个空消息队列中时产生， 如5.6节中所述。
- SI_QUEUE 信号由sigqueue函数发出。 稍后我们将给出一个这样的例子。
- SI_TIMER 信号由使用timer_settime函数设置的某个定时器的到时产生， 我们不讲
- SI_USER 信号由kill函数发出。

如果信号是由某个其他事件产生的，si_code就会被设置成不同于这里所列的某个值。
siginfo_t结构的si_value成员的内容只在si_code为SI_ASYNCIO、 SI_MESGQ、 SI_QUEUE或SI_TIMER时才有效。

### 实时信号的测试程序
子进程阻塞三种实时信号， 父进程随后发送9个信号（三种实时信号各3个）， 子进程接着解阻寒信号， 我们于是看到每种信号各有多少个递交以及它们的先后递交顺序。
```c
#include "unpipc.h"
static void sig_rt(int, siginfo_t *, void* );
int main(int argc, char **argv){
    int  i, j；
    pid_t pid;
    sigset_t newset;
    union sigval val；
    
    printf(SIGRTMIN = %d, SIGRTMAX = %d\n", (int) SIGRTMIN, (int) SIGRTMAX);
    if ( (pid=Fork()) == 0) {
        /* child： block three realtLine signals */
        Sigemptyset(&newset);
        Sigaddset(&newset, SIGRTMAX);
        Sigaddset(&newset, SIGRTMAX - 1);
        Sigaddset(&newset, SIGRTMAX - 2);
        Sigprocmask(SIG_BLOCK, &newset, NULL) ；
        // establish signal handler with SA_SIGINFO set
        Signal_rt(SIGRTMAX, sig_rt, &newset ) ；
        Signal_rt(SIGRTMAX-1, sig_rt, &newset);
        Signal_rt(SIGRTMAX-2, sig_rt, &newset);
        sleep(6); /* let parent send all the signals */
        Sigprocmask(SIG_UNBLOCK, &newset, NULL); /* unblock */
        sleep(3); /* let all queued signals be delivered */
        exit(0);
    }
    /* parent sends nine signals to child V
    sleep(3);   /* let child block all signals */
    for(i = SIGRTMAX； i >= SIGRTMAX-2; i--){
        for (j = 0; j < 3; j++) {
            val.sival_int = j;
            Sigqueue(pid, i, val);
            printf("sent signal %d, val = %d\n", i, j);
        }
    }    
    exit(0);
}

static void sig_rt(int signo, siginfo_t *info, void *context){
    printf("received signal #%d, code = %d, ival = %d\n",
        signo, info->si_code, info->si_vakue.sival_int);
}
```

> 无论何时处理不止一种实时信号，我们都必须给毎种实时信号的信号处理函数指定一个smask值， 该掩码应该阻塞所有剩余的值较大的（ 即优先级较低的） 实时信号。 Posix规則保证当有多种实时信号待处理时，值最小的信号域先递交，然而保证较低优先级的实时信号不中断当前信号处理函数却是我们的责任（言外之意就是高优先级的可以中断）。我们通过给信号处理函数指定一个sa_mask值来做到这点。

注意本例中printf不是异步信号安全的，最好的方法是分配全局变量，在信号处理函数内仅仅保存相关信息到全局变量中，并在子进程终止前打印其信息。

> 在原书的测试例程中，solars2.6的实现是有缺陷的。

自己定义的实时信号绑定函数
```c
#include "unpipc.h"
Sigfunc_rt * signal_rt(int signo, Sigfunc_rt* func, sigset_t *mask){
    struct sigaction act, oact;
    act.sa_sigaction = func;    /* must store function addr here */
    act.sa_mask = *mask;        // signals to block 
    act.sa_flags = SA_SIGINFO;  // must specify this for realtime

    if (signo == SIGALRM){
#ifdef SA_INTERRUPT
        act.sa_flags | = SA_INTERRUPT;
#endif
    } else {
#ifdef SA_RESTART
        act.sa_flags | = SA_RESTART  /* SVR4, 44BSD */
#endif
    }
    if (sigaction(signo, &act, &oact) < 0)
        return( (Sigfunc_rt*) SIG_ERR )；
    return(oact.sa_sigaction);
}
```

被绑定的信号处理函数原型如下，我们用typedef简化调用：
```c
typedef void Sigfunc_rt(int, siginfo_t * , void *);
```

加入实时信号支持后， sigaction发生变化， 即增加了新的sa_sigaction成员。
```c
struct sigaction {
    void (*sa_handler)();   /* SIG_DFL,SIC_IGN,or add of signal handler */
    sigset_t sa_mask;       /* additional signals to block */
    int sa_flags;           /* signal options: SA_xxx */
    void (*sa_sigaction)(int, siginfo_t, void *);
                /* addr of signal handler if SA_SIGINFO set */
};
```
规则如下
- 如果在sa_flags成员中设置 SA_SIGINFO标志， 那么sa_sigaction成员会指定信
号处理函数的地址。
- 如果在sa_flags成员中没有设SSA_SIGINFO标志， 那么sa_handler成员会指定信
号处理函数的地址。
- 为给某个信号指定默认行为或忽略该信号, 应把sa_handler设置为SIG_DFL或
SIG_IGN, 并且不设置SA_SIGINFO标志

## 习题

#### 在创建新队列时，如果attr参数为空，则maxmsg和msgsize必须都指定，如果只指定一个，另一个用默认值？
答：不指定参数创建队列，获取属性，删除队列。以此得到默认值。再创建新队列。

#### 互斥锁和条件变量放在共享内存用于进程通信时，在确认没有进程继续使用后再摧毁。

#### 在使用select的程序中，每次信号被捕获时，进入信号处理函数，导致select被中断。所以应该设置自行重启的函数。
```c
int Select(int nfds, fd_set rfds, fd_set *wfds, fd_set *efds, struct timeval *timeout){
    int n;
again:
    if( (n = select(nfds, rfds, wfds, efds, timeout )) < 0){
        if (errno == EINTR)
            goto again；
        else
            err_sys(" select err") ；
    } else if (n == 0 && timeout = = NULL)
        err_quit{"select returned 0 with no timeout" )；
    return(n)；
}
```
