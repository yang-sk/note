# 第13章 Posix共享内存区

## 13.1 概述
上一章较为笼统地讨论了共享内存区和mman函数，并给出父子进程共享内存的例子。

posix1提供了两种在无亲缘进程间共享内存的方法。
1. 内存映射文件
     由open函数打开， 由mmap函数把得到的描述符映射到当前进程地址空间中的一个文件。 在上一章就是用了这种方法。
2. 共享内存对象
     由shm_open打开一个Posix.1 IPC名字(也许是在文件系统中的一个路径名)， 所返回的描述符由mmap函数映射到当前进程的地址空间。 我们将在本章讲述种技术。

这两种技术都需要调用mmap, 差别在于作为mmap的参数之一的描述符的获取手段： 通过open或通过shm_open。 Posix把两者合称为内存区对象.

## 13.2 shm_open和shm_unlink函数

Posix共享内存区涉及以下两个步骤要求。

1. 指定一个名字参数调用shm_open, 以创建一个新的共享内存区对象或打幵一个已存在的共享内存区对象。


2. 调用mmap把这个共享内存区映射到调用进程的地址空间。

```c
#include <sys/mman.h>
int shm_open(const char *name, int oflag, mode_t mode);
返回：若成功则为非负描述符，若出错则为-1
int shm_unlink(const char *name); 
返回：若成功则为0,出错则为-1
```
要点
- name参数服从PosixIPC名字规则。

- oflag参数必须或者含有O_RDONLY(只读)标志，或者含有O_RDWR ( 读写) 标志， 还可以指定O_CREAT、 O_EXCL或O_TRUNC。 如果随O_RDWR指定O_TRUNC标志， 而且共享内存区对象己经存在， 那么它将被截短至0。

- mode参数指定权限位, 它在指定了O_CREAT标志的前提下使用。注意， 与mq_open和sem_open函数不同， shm_open的mode参数总是必须指定的(而不是可省的)。如果没有指定O_CREAT标志， 那么该参数可以指定为0。

- shm_open的返回值是一个整数描述符， 它随后用作mmap的第五个参数。

- shm_unlink函数删除一个共享内存区对象的名字。 跟所有其他unlink函数( 删除文件系统中一个路径名的unlink，删除一个Posix消息队列的mq_unlink， 以及删除一个Posix有名信号景的sem_unlink)一样，删除一个名字不会影响对于其底层支撑对象的现有引用，直到对于该对象的引用全部关闭为止。删除一个名字仅仅防止后续的open、 mq_open或sem_open调用取得成功。

  思考：close应该是关闭本进程对文件描述符的读写等操作。所以对记录上锁解锁、映射出的共享内存等没什么影响。

> 不同与消息队列和信号量，共享内存对象需要先打开再映射，才能使用。而前两者打开后就可以使用了。

## 13.3 ftruncate和fstat函数
处理mmap的时候， 普通文件或共享内存区对象的大小都可以通过调用ftruncate修改。
```c
#include <unistd.h>
int ftruncate(int fd , off_t length);
返回: 若成功则为0, 若出错则为-1
```
Posix就该函数对普通文件和共享内存区对象的处理的定义稍有不同。
- 对于普通文件：如果该文件的大小大于参数，额外的数据就被丢弃。如果小于，那么该文件是否被修改以及大小是否增长是未加说明的。实际上对于普通文件，把它的大小扩展到length字节的可移植方法是：先lseek到偏移为length-1处，然后write 1个字节的数据。所幸几乎所有Unix实现都支持使用ftruncate扩展一个文件。

  思考：文件需裁剪时用ftruncate，需扩展时应该用lseek方法。所以万金油的方式就是截至0，再用lseek(当然这会丢弃所有文件内容)。
- 对于一个共享内存区对象： ftruncate把该对象的大小设置成length字节。

我们调用ftruncate来指定新创建的共享内存区对象的大小，或者修改已存在的对象的大小。当打开一个己存在的共享内存区对象时，我们可调用fstat来获取有关该对象的信息。 
```c
#include <sys/types.h>
#include <sys/stat.h>
int fstat(int fd, struct stat* buf);
返回：成功则为0, 出错则为-1
```
stat结构有12个或以上的成员(APUE第4章详细讨论它的所有成员)， 然而当fd指代一个共享内存区对象时， 只有四个成员含有信息。
```c
struct stat {
    ...
    mode_t  st_mode;    /* mode: S_I{RW}{USR,GRP,OTH} */
    uid_t   st_uid;     /* user ID of owner */
    gid_t   sd_gid;     /* group ID of owner */
    off_t   st_size;    /* size in bytes */
    ...
};
```

> 不幸的是， Posix.l 并没有指定一个新创建的共享内存区对象的初始内容.关于Shm_open函数的说明只说： “(新创建的) 共享内存区对象的大小应该为0”. 关于ftruncate函数的说明指定， 对于一个普通文件(不是共享内存区)， “如果其大小被扩展， 那么扩展部分应显得好像已用0填写过”。 然而却没有关于被扩展了的共享内存区对象新内容的陈迷。

## 13.4 简单的程序
posix共享内存至少有随内核的持续性。

以下代码实现：往指定共享内存对象中写入一个模式：0,1,2...254,255,0,1...

shmopen打开指定的共享内存对象，fstat获取大小，mmap映射后关闭它的描述符。

```c
int main(int argc, char **argv){
    int i, fd;
    struct stat stat; 
    unsigned char *ptr; 
    / * open, get size, map */
    fd = Shm_open(argv[l], O_RDWR, FILE_MODE);
    Fstat(fd, &stat);
    ptr = Mmap(NULL, stat.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd); 
    / * set: ptr[0] = 0, ptr[1] = 1, etc.*/
    for (i = 0; i < stat.st_size; i++)
        *ptr++ = i % 256;
 	exit(0);
}  // code 13-4
```

对共享内存的访问是通过指针来完成的。

共享内存区在不同的进程中可以表现不同的地址。这里的地址应该是mmap函数的返回值，猜测是因为这个地址值应该是相对于进程内存空间来说的。而每个进程的内存空间是独立的。

## 13.5 给一个共享的计数器持续加1

计数器存放在共享内存，用有名信号量来同步。

以下程序实现：创建并初始化共享内存区和信号量。
```c
#include "unp2.h"
struct shmstruct {      /* struct stored in shared memory */
    int count;
};
sem_t *mutex;           /* pointer to named semaphore */
int main(int arge, char **argv){
    int fd;
    struct shmstruct* ptr;
    if (arge != 3)
        err_quit("usage: server1 <shmname> <senmame>");

    shm_unlink(Px_ipc_name(argv[1]));      /* OK if this fails */
    /* create shm, set its size, map it, close descriptor */
    fd = Shm_open(Px_ipc_name(argv[1]), O_RDWR | O_CREAT | O_EXCL, FILE_MODE);
    Ftruncate(fd, sizeof(struct shmstruct));
    ptr = Mmap(NULL, sizeof(struct shmstruct), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd); 
    sem_unlink(Px_ipc_name(argv[2]));       /* OK if this fails */
    mutex = Sem_open(Px_ipc_name(argv[2]), O_CREAT | O_EXCL, FILE_MODE, 1);
    Sem_close(mutex);
    exit(0);
} // code 13-7
```

要点
- shm_unlink提防对象已存在。sem_unlink同理。
- 共享内存和信号量用不同的名字，系统不保证会根据类型区分同名的情况。

以下程序实现：打开已有共享内存和信号量，并对计数器进行累加
```c
struct shmstruct {
    int count;
};
sem_t* mutex;  /* pointer to named semaphore */
int main(int argc, char **argv){
    int     fd, i, nloop;
    pid_t   pid;
    struct shmstruct* ptr;
    if(argc != 4)
        err_quit("usage: client1 <shmname> <semname> <#loops>");
    nloop = atoi(argv[3]);
    fd = Shm_open(Px_ipc_name(argv[1]), O_RDWR, FILE_MODE);
    ptr = Mmap(NULL, sizeof(struct shmstruct), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd);
    mutex = Sem_open(Px_ipc_name(argv[2]), 0);  /* must exist */
    pid = getpid(); 
    for (i = 0; i < nloop; i++) {
        Sem_wait(mutex); 
        printf("pid %ld: %d\n", (long) pid, ptr->count++) ;
        Sem_post(mutex);
    }
    exit(0);
}  // code 13-8
```

## 13.6 向一个服务器发送消息
现在对生产消费者问题做如下修改：服务器启动后创建共享内存对象，各客户进程向其中放置消息。服务器对消息逐个做处理(这里仅输出这些消息)。

类型：多个生产者(客户)和单个消费者(服务器)。

#### 头文件
```c
#include "unpipc.h"
#define MESGSIZE    256  /* max size per message, include null at end */
#define NMESG       16  /* max messages */
struct shmstruct {
    sem_t mutex, nempty, nstored;
    int nput;
    long noverflow;			/* overflow by senders */
    sem_t noverflowmutex;   /* mutex for noverflow */
    long msgoff[NMESG];     /* offset of each message */
    char msgdata[NMESG*MESGSIZE];	/* data */
};
```
#### 基本的信号量和变量
- 三个信号量：mutex, nempty, nstored。
- 一个变量: nput表示存放的下一个位置(1,2...NMESG-1)。

既然多个生产者，这些量当然在共享内存中，且受访问保护。

#### 关于溢出
某个客户想发送消息时所有槽位已满，但是假使客户同时又是某种类型的服务器(如FTP服务器或HTTP服务器)，那么它可能不愿意等待服务器释放出一个槽位。 因此， 我们令发生这种情况时并不阻塞，而是给overflow计数器加1。由于该溢出计数器也是在所有客户和服务器之间共享的，因此它也需要互斥锁保护。

#### 消息偏移和数据
数组msgoff含有针对msgdata数组的各个偏移， 指出了每个消息的起始位置。这就是说msgoff[0]为0，msgoff[1]为256 (MESGSIZE的值)，msgoff[2]为512，等等。

在处理共享内存区时，我们只能使用这样的偏移 (offset)，因为共享内存区对象可映射到各个进程的不同物理地址。也就是说，对于同一个共享内存区对象， 调用mmap的各个进程所得到的返回值可能不同。由于这个原因，我们不能在共享内存区对象中使用指针(pointer)，因为它们含有存放在这些对象内各变量的实际地址。

思考：各个进程的内存空间是独立的，进程把指针(地址量)解释为在本进程内存空间的地址。所以地址量不能跨进程传递。

##### 创建共享内存区对象

调用shm_unlink删除可能仍然存在的共享内存区对象。接着使用shm_open创建这个对象， 再用mmap把它映射到调用进程的地址空间。 然后关闭它的描述符。

##### 等待消息， 然后输出

for循环的前半部分是标准的消费者算法： 等待nstored，等待mutex， 处理数据，释放mutex， 挂出nempty。

##### 处理溢出

每次经由这个循环， 我们还检查是否溢出。 我们测试计数器noverflows的值是否不同于上一次的值， 若是则输出并保存这个新值。 注意， 我们在持有noverflowmutex信号量期间获取计数器值的， 但在比较并输出它之前先释放了这个信号量。 这展示了“减少临界区操作”的一般规则。

#### 服务器程序
它等待某个客户往指定的共享内存区中放置一个消息， 然后输出这个消息。
```c
#include "cliserv2.h"
int main(int argc, char **argv){
    int fd, index, lastnoverflow, temp; 
    long offset;
    struct shmstruct* ptr;
    if (argc != 2)
        err_quit("usage: server2 <name>");

    /* create shm, set its size, map it, close descriptor */
    shm_unlink(Px_ipc_name(argv[1]));	// OK if fail
    fd = Shm_open(Px_ipc_name(argv[1]), O_RDWR | O_CREAT | O_EXCL, FILE_MODE);
    ptr = Mmap(NULL, sizeof(struct shmstruct), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Ftruncate(fd, sizeof(struct shmstruct));
    Close(fd);

    for (index = 0; index < NMESG; index++)
        ptr->msgoff[index] = index * MESGSIZE;
    
    Sem_init(&ptr->mutex, 1, 1) ; 
    Sem_init(&ptr->nempty, 1, NMESG);
    Sem_init(&ptr->nstored, 1, 0);
    Sem_init(&ptr->noverflowmutex, 1, 1);

    /* this program is the consumer */
    index = 0;
    lastnoverflow = 0;
    for ( ; ; ) {
        Sem_wait(&ptr->nstored);
        Sem_wait(&ptr->mutex); 
        offset = ptr->msgoff[index];
        printf("index = %d： %s\n", index, &ptr->msgdata[offset]);
        if ( ++index >= NMESG)
            index=0;            //circluar buffer ; or   index=(index+1)%NMESG;
        Sem_post(&ptr->mutex);
        Sem_post(&ptr->nempty);

        Sem_wait(&ptr->noverflowmutex);
        temp = ptr->noverflow;      /* don't printf while mutex held */
        Sem_post(&ptr->noverflowmutex);
        if (temp != lastnoverflow) {
            printf("noverflow = %d\n", temp); 
            lastnoverflow = temp;
        }
    }
    exit(0);
}  // 13-11
```
#### 客户程序
```c
#include "cliserv2.h"
int main(int argc, char **argv){
    int fd, i, nloop, nusec;
    pid_t pid;
    char mesg[MESGSIZE]; 
    long offset;
    struct shmstruct* ptr;

    if (argc != 4)
        err_quit("usage: client2 <name> <#loops> <#usec>");
    nloop = atoi(argv[2]);
    nusec = atoi(argv[3]);
    /* open and map shared memory that server must create */
    fd = Shm_open(Px_ipc_name(argv[1]), O_RDWR, FILE_MODE);
    ptr = Mmap(NULL, sizeof(struct shinstruct), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd); 
    pid = getpid();
    for (i = 0; i < nloop; i++) {
        Sleep_us(nusec); 
        snprintf(mesg, MESGSIZE, "pid %ld： message %d", (long) pid, i); 
        if(sem_trywait(&ptr->nempty) == -1) {
            if(errno==EAGAIN) {
                Sem_wait(&ptr->noverflowmutex);
                ptr->noverflow++; 
                Sem_post(&ptr->noverflowmutex);
                continue; 
            }else
                err_sys("sem_try wait error");
        }
        Sem_wait(&ptr->mutex); 
        offset = ptr->msgoff[ptr->nput]; 
        if(++(ptr->nput) >= NMESG)
            ptr->nput = 0;  // circular buffer 
        Sem_post(&ptr->mutex); 
        strcpy(&ptr->msgdata[offset], mesg);
        Sem_post(&ptr->nstored ); 
    }
    exit(0);
}  //13-12
```
要点
- 指定微妙数来停顿，以造成溢出。
- 打开共享内存对象，映射，关闭描述符
- 在最后的strcpy前释放了mutex，以减少其临界区。

