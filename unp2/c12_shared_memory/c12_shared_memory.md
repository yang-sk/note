# 第12章 共享内存区介绍

## 12.1 概述
共享内存区是IPC中最快的。数据传递不需要通过内核。
对共享内存的使用需要某种同步，如互斥锁，条件变量，读写锁，记录锁，信号量。

考虑一个示例客户-服务器文件复制程序中涉及的通常步骤：
1. 服务器从输出文件读。该文件的数据由内核读入自己的内存空间，然后复制到服务器进程的内存空间。
2. 服务器往一个管道FIFO或消息队列中写入这些数据。这些IPC通常需要把数据从进程复制到内核。
3. 客户从IPC中读取这些数据，通常需要从内核复制到进程。
4. 客户写入到指定文件，从进程复制到内核，内核写入到文件。

所以整个过程需要四次内核与进程之间的内存复制。

共享内存不需要通过内核，避免内核与进程间的复制数据。

使用共享内存完成文件复制：
1. 服务器使用（譬如说）一个信号量取得访问某个共享内存的权力
2. 服务器从文件读入数据到共享内存。read函数的第二个参数指定目标地址，指向该共享内存
3. 服务器发出信号量通知客户
4. 客户从共享内存中写出到文件

这样只有在读写文件时共发生两次内核与进程间的数据拷贝。

例程：共享内存中增加一个计数量。

fork的父子是复制内存区而非共享内存区。

对父子进程的测试
```c
#include "unp2.h"
#define SEM_NAME "mysem"
int count = 0;
int main(int argc, char **argv){
    int i, nloop；
    sem_t *mutex；
    nloop = 100 ；

    /* create, initialize, and unlink semaphore */
    mutex = Sem_open(Px_ipc_name(SEM_NAME), 0_CREAT | O_EXCL, FILE_MODE, 1) ；
    Sem_unlink(Px_ipc_name(SEM_NAME) ) ；
    setbuf(stdou , NULL) ；        /* stdout is unbuffered */
    if (Fork() == 0) {
        for (i = 0; i < nloop； i++） {
            Sem_wait(mutex);
            printf("child: %d\n" , count++)；
            Sem_post(mutex)；
        }
        exit(0);
    }

    /* parent */
    for (i = 0; i < nloop； i++) {
        Sem_wait(mutex);
        printf("parent: %d\n", count++);
        Sem_post(mutex) ；
    }
    exit{0);
}
```
要点
- 标准输出设置为非缓冲模式，可以避免父子进程的输出不适当地交叉。确切地说，缓冲模式阻碍了实时性。
- unlink不妨碍已经被打开的信号量。

以上运作不正确，因为子进程持有父进程内存空间的副本。而不是共享内存。

## 12.2 mmap，munmap和msync函数
mmap函数把一个文件或posix共享内存对象映射到进程的内存空间。该函数有三个目的
1. 使用普通文件以提供内存映射IO
2. 使用特殊文件以提供匿名内存映射
3. 使用shm_open以提供无亲缘进程间的posix共享内存区

```c
#include<sys/mman.h>
void* mmap(void* addr,size_t len, int prot, int flags, int fd, off_t offset);
返回：成功则为被映射区的起始地址，出错则MAP_FAILED
```
其中addr可以指定描述符fd应被映射到的进程内空间的起始地址,通常为一个空指针，这样告诉内核自己去选择起始地址。无论哪种情况下，该函数的返回值都是描述符所映射到内存区的起始地址。

从被映射文件fd偏移offset(通常是0）处，映射len字节到进程空间。

【图】
注意：映射相当于引用，而不是拷贝。

内存映射区的保护由prot指定，使用下列常值。常见值是读写访问：PROT_READ|PROT_WRITE
```
PROT_READ   可读
PROT_WRITE  可写
PROT_EXEC   可执行
PROT_NONE   不可访问
```
flags使用以下常值。共享或私自必须指定一个，可选择性地加上FIXED。
- 如果指定私自，则当前进程对被映射数据所做的修改只对本进程可见，而不改变其底层支撑对象（或者是文件，或者是共享内存对象）。
- 如果指定共享，则改动会修改底层对象，改动对所有进程可见。

从移植性考虑，不应指定FIXED。如果没有指定FIXED，且addr非空，则addr如何处置取决于实现，不为空的addr通常被当做有关该内存去应如何具体定位的线索。
可移植的代码应该设addr为空，且不指定FIXED。
```
MAP_SHARED  变动是共享的
MAP_PRIVATE 变动是私自的
MAP_FIXED   准确地解释addr参数
```
父子进程共享内存，可以在fork前指定MAP_SHARED调用mmap。Posix.1保证父进程的内存映射关系留存在子进程中。

mmap成功返回后，fd可以关闭，这对建立的映射关系没有影响。

思考：从这种角度来看，关闭文件更像是告诉进程不再对文件描述符调用读写等操作。

思考：从unlink不妨碍已打开的信号量来说，close和unlink更像是告诉文件系统，在无进程使用资源时，资源该如何释放。（立即释放或按计数0释放）

删除映射关系：munmap
```c
#include<sys/mman.h>
int munmap(void* addr, size_t len);
成功0出错-1
```
addr是由mmap返回的地址，len是映射区的大小。再次访问这些地址将导致向调用
进程产生一个SIGSEGV信号（ 当然这里假设以后的mmap调用并不重用这部分地址空间）。
如果被映射区是使用MAP_PRIVATE标志映射的， 那么调用进程对它所作的变动都会被丢弃.

内核的虚拟内存算法保持内存映射“文件”（一般在硬盘上） 与内存映射“区”（在内存中） 的同步， 前提是它是一个MAP_SHARED内存。 这就是说， 如果我们修改了处于内存映射到某个文件的内存区中某个位置的内容，那么内核将在稍后某个时刻相应地更新文件。 然而有时候我们希望确信硬盘上的文件内容与内存映射区中的内容一致，于是调用msync来执行这种同步。
```c
#include <sys/mman.h>
int msync(void *addr , size_t len , int flags )；
返回： 若成功则为0, 若出错则为-1
```
其中addr和len参数通常指代内存中的整个内存映射区， 不过也可以指定该内存区的一个子
集。 参数flags是以下各常值的组合。
```
  常值             说明
MS_ASYNC        执行异步写
MS_SYNC         执行同步写
MS_INVALIDATE   使高速缓存的数据失效
```

MS_ASYNC和MS_SYNC这两个常值中必须指定一个，但不能都指定。
它们的差别是， 一旦写操作已由内核排入队列， MS_ASYNC即返回，而MS_SYNC则要等到写操作完成后才返回。
如果还指定了MSJNVALIDATE, 那么与其最终副本不一致的文件数据的所有内存中副本都失效。后续
的引用将从文件中取得数据。

为何使用 mmap
到此为止就mmap的描述间接说明了内存映射文件:被open后调用mmap映射到调用进程地址空间的某个文件。 

使用内存映射文件的I/O操作都在内核的掩盖下完成， 只需编写存取内存映射区中各个值的代码，不直接调用read、write或lseek。

需要了解的是，不是所存文件都能进行内存映射。 例如，试图把一个访问终端或套接字的描述符映射到内存将导致mmap返回错误。 这些类型的描述符必须使用read和write (或者它们的变体） 来访问。

mmap的另一个用途是在无亲缘关系的进程间提供共享的内存区。 这种情形下，所映射文件
的实际内容成为被共亨内存区的初始内容， 而且这些进程对该共享内存区所作的任何变动都复
制回所映射的文件（以提供随文件系统的持续性）。这里假设指定了MAP_SHARED标志， 它是进
程间共享内存所需求的。

## 12.3 在内存映射文件中给计数器持续加1

```c
#include "unpipc.h*
#define SEM_NAME "mysem"
int main(int argc, char **argv){
    int     fd, i, nloop, zero=0;
    int     *ptr;
    sem_t   *mutex;
    
    nloop = 100;
    /* open file, initialize to 0, map into memory */
    fd = Open(argv[1], O_RDWR | O_CREAT, FILEMODE);
    Write(fd, &zero, sizeof(int));
    ptr = Mmap(NULL, sizeof(int), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd)；

    /* create, initialize, and unlink semaphore */
    mutex = Sem_open(Px_ipc_namc(SEM_NAME), O_CREAT | O_EXCL, FILEMODE, 1);
    Sem_unlink(Px_ipc_name(SEM_NAME) ) ；
    
    setbuf(stdout, NULL);   /* stdout is unbuffered */
    if (Fork() == 0) {
        for (i = 0; i < nloop; i++) {
            Sem_wait(mutex) ；
            printf("child： %d\r", (*ptr)++);
            Sem_post(mutex);
        }
        exit(0);
    }
    /* parent */
    for (i = 0； i < nloop; i++） {
        Sem_wait(mutex);
        printf("parent: %d\n", (*ptr)++);
        Sem_post(mutex);
    }
    exit(0);
}
```

思考：按原书上说，内存映射文件不等同真正的文件？


基于内存的信号量

上一小节中使用具名信号量，放在内核中（也可以在文件中）；而内存信号量放在共享内存中。

本例中，信号量和共享数据一起在共享内存中。

```c
#include "unpipc.h"
struct shared {
    sem_t mutex；       /* the mutex： a Posix memory-based semaphore */
    int count;          /* and the counter */
} shared;

int main(int argc, char **argv){
    int fd, i, nloop；
    struct shared *ptr;
    nloop = 100 ；
    /* open file, initialize to 0, map into memory */
    fd = Open(argv[1], O_RDWR | O_CREAT, FILE_MODE);
    Write(fd, &shared, sizeof(struct shared));
    ptr = Mmap(NULL, sizeof(struct shared), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    Close(fd);

    /* initialize semaphore that is shared between processes */
    Sem_init(&ptr->mutex, 1, 1);

    setbuf(stdout, NULL)； /* stdout is unbuffered */

    if (Fork() == 0) {
        for (i = 0; i < nloop; i++) {
            Sem_wait(&ptr->mutex)；
            printf("child： %d\n", ptr->count++)；
            Sem_post(&ptr->mutex);
        }
        exit(0);
    }
    for (i = 0; i < nloop； i++) {
        Sem_wait(&ptr->mutex ) ；
        printf("parent: %d\n" , ptr->count-«-^);
        Sem_post(&ptr->mutex);
    }
    exit(0) ；
}
```

## 12.4 4.4BSD匿名内存映射（略）
## 12.5 SVR4 dev/zero内存映射（略）

## 12.6 访问内存映射的对象
内存映射一个普通文件时，内存中映射区的大小(mmap的第二个参数）通常等于该文件的大小。
然而两者可以不同。

TIP：如何设置文件大小为N
若待打开的文件不存在则创建，若存在则把它的大小截断至0。接着把文件读写指针移动N-1位，然后写一个字节。【应该是，如果当前文件大小大于N，则截断至N；如果小于N，则移动指针N-1位写入一个字节，待测试？或者直接Ftruncate？】

内存映射后描述符被关闭。关闭后映射关系依然存在。
关闭描述符，更像是告诉进程：不再对其进行读写之类的操作

```c
#include "unpipc.h"
int main(int argc, char **argv)
int fd,i;
char *ptr;
size_t  filesize,mmapsize,pagesize;

if (argc != 4)
    err_quit("usage： testl <pathname> <filesize> <mmapsize>");
filesize = atoi(argv[2]);
mmapsize = atoi(argv[3]);
fd = Open(argv[1], O_RDWR | O_CREAT | O_TRUNC, FILE_MODE) ;
Lseek(fd, filesize-1, SEEK_SET);
Write(fd,"", 1)；
ptr = Mmap(NULL, mmapsize, PROT_READ | PROT_WRITE, MAP_SHARED # fd, 0);
Close(fd);
pagesize = Sysconf(_SC_PAGESIZE);
printf("PAGESIZE = %ld\n, (long) pagesize)；
    for (i = 0; i < max(filesize, mmapsize); i += pagesize) {
        printf("ptr[%d] = %d\n"，i, ptrti));
        ptr[i] = 1;
        printf("ptr[%d] = %d\n", i pagesize - 1, ptr(i + pagesize - 1 J);
        ptr[i + pagesize - 1]=1;
    }
    printf("ptr[%d] %d\n"， i, ptr[i]);
    exit(0);
}
```

在文件页面的首尾写入“1”。

测试命令
```bash
od -b -A d <file>
# -b 八进制输出字节 -A d 以十进制输出地址
```
查看文件内存内容。

内核是按页来管理内存的。

![share_size][1]

#### mmap大小等于文件大小时的情况
- 能够访问超出文件范围，但在文件尾所在页面范围的内容，但改动不会写回到文件。
- 超过文件尾所在页范围，引发SIGSEGV段错误信号

#### mmap大小超出文件的情况
- 能够访问超出文件范围，但在文件尾所在页面范围的内容，但改动不会写回到文件。
- 在内存映射区内访问，但超出底层支撑对象的大小（例如文件）的大小，引发SIGBUS信号。
- 在内存映射区以远访问，SIGSEGV。

可以看出
- 内核知道底层支撑对象的大小，即使对象的描述符被关闭也一样。
- mmap可以指定大于该支撑对象的大小，但只有在文件范围大小之内，才能实现正常的访问和写入。

从上述描述，笔者推断访问规则应该是这样的：
- 在文件所在页范围内，访问不出问题，但只在文件范围内才能正常写回文件
- 在文件所在页范围外，映射区范围内是SIGBUS错误，映射区范围外是SIGSEGV错误
 
下一个程序它展示了处理一个持续增长的文件的一种常用技巧： 指定一个大于该文件大小的内存映射区大小， 跟踪该文件的当前大小（ 以确保不访问当前文件尾
以远的部分）， 然后就让该文件的大小随着往其中每次写入数据而增长。
```c
#define FILE    "test.data"
#define SIZE    32768
#define PAGESIZE 4096

int main(int argc, char **argv){
    int fd, i;
    char *ptr;
    fd = Open(FILE, O_RDWR | O_CREAT | O_TRUNC, FILE_MODE);
    ptr = Mmap(NULL, SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    for (i = PAGESIZE； i <= SIZE; i += PAGESIZE) {
        printf("setting file size to %d\n", i ) ；
        Ftruncate(fd, i);
        printf("ptr[%d] = %d\n", i-1, ptr[i-1]);
    }
    exit(0);
}
```


  [1]: https://yskimg.oss-cn-beijing.aliyuncs.com/unp_2/share_map_size.png
