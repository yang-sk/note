# 第10章 信号量

## 10.1 概述
信号量（semaphore）可以在进程间或线程间做同步。

按类型分为三种
- Posxi有名信号量，使用PosixIPC名字来标识
- Posix基于内存的信号量，放在共享内存中
- SystemV信号量，在内核中维护

信号量可以在内核或文件系统中维护。
Posix信号量由文件路径名来标识，尽管可能在内核中维护。

对信号量的操作：
- 创建。需要指定初值
- 等待。测试信号量的值，如果小于等于0则一直阻塞，如果大于0则减一。
- 挂出。把信号量的值加一。

按照使用方式，可以分为二值信号量和计数信号量。但是本质没有区别。

信号量可用于互斥，类似于互斥锁。
互斥锁与信号量使用流程对照
```
初始化互斥锁                初始化信号量为1
pthread_mutex_lock         sem_wait
临界区                      临界区
pthread_mutex_unlock       sem_post
```
思考：信号量为0，表示正在被独占。大于0表示可以占用。

例如：生产者每次向缓冲区添加条目，消费者每次从缓冲区取出条目。缓冲区只能容纳一个条目。
``` 
生产者 -> [缓冲区] -> 消费者
```

伪代码如下
```c
         初始化：empty=1,full=0;
--------------------------------------------
       [生产者]      |         [消费者]
while(1){            |  while(1){
    sem_wait(empty); |      sem_wait(full);
    insert_item;     |      delete_item;
    sem_post(full);  |      sem_post(empty);
}                    |  }
```

> 正在等待信号量的线程会标记为ready-to-run

信号量与互斥锁和条件变量的差异
- 互斥锁必须总是由获取锁的线程解锁，信号量的挂出却不必由等待它的线程执行。
- 互斥锁只有被占用和未被占用两种状态,信号量可以计数
- 条件变量可以发出信号，但是如果没有线程等待该信号，则信号丢失。信号量可以看做是信号的计数，所以不会丢失。

> 信号量发明的初衷是为了进程间通信，互斥锁和条件变量发明的初衷是线程间通信。

思考：post可以认为是发出一个信号；wait可以是等待（并消化）一个信号。信号量的值，表示“悬空”的信号个数。

Posix提供有名信号量和基于内存的信号量，后者也称无名信号量。
两者使用的函数有所区别。
```
有名信号量      |      基于内存的信号量
sem_open()     |        sem_init()
--------------------------------------
          sem_wait()
          sem_trywait()
          sem_post()
          sem_getvalue()
-------------------------------------
sem_close()     |       sem_destroy()
sem_unlink()    |
```
基于内存的信号量可以在共享内存中进行进程间同步。

## 10.2 sem_open、sem_close和sem_unlink函数

sem_open打开或创建具名信号量。具名信号量总是可用于线程和进程同步。
```c
#include<semaphore.h>
sem_t* sem_open(const char* name,int oflag,.../* mode_t mode,unsigned int value */);
返回：若成功则为指向信号量的指针，出错则SEM_FAILED
```
要点
- name遵循PosixPIC名称规则。
- oflag可以是0、O_CREAT或 O_CREAT|O_EXCL
- 如果指定了O_CREAT标志，那么第三个和第四个参数是需要的。
- mode指定权限位，value指定初始值。初始值不能超过SEM_VALUE_MAX(这个常值至少为21767）
- 二值信号量初值往往是1，计数信号量初值往往大于1
- 函数返回了一个指针。【动态分配？函数内静态分配？还是类似于文件描述符仅仅是索引值】

> 在原书作者测试的两个系统上，oflag无需指定读写权限，默认要求读写权限的。[待测试?]

sem_close关闭信号量
```c
#include<semaphore.h>
int sem_close(sem_t* sem);
返回：成功则0，出错-1
```
进程终止时，内核会关闭其上所有的具名信号量，不论进程自愿（调用_exit）还是非自愿终止（接收Unix信号）。
关闭信号量不会从系统中删除。即，它至少是随内核持续的。
具名信号使用sem_unlink从系统中删除
```c
#include<semaphore.h>
int sem_unlink(const char* name);
成功则0，出错-1
```
类似于文件，信号量具有引用计数。close和unlink的操作与文件类似。unlink立即删除；close减少引用计数，计数为0时才会析构。

## 10.3 sem_wait和sem_trywait
等待目标信号量的值大于0.如果大于0则减一并返回。操作是原子的。
try是非阻塞版本,信号量为0时返回EAGAIN错误。
```c
#include<semaphore.h>
int sem_wait(sem_t* sem);
int sem_trywait(sem_t* sem);
成功0，出错-1
```
同大多数的阻塞函数一样，阻塞版本会被中断，返回EINTR

## 10.4 sem_post 和 sem_getvalue
线程使用完某个信号量时，应该调用sem_post.会使得信号量加一，从而唤醒某些等待进程（如果此时信号量为正）。

```c
#include<semaphore.h>
int sem_post(sem_t* sem);
int sem_getvalue(sem_t* sem,int* valp);
成功0，出错-1
```
取值函数可以返回信号量当前值。如果该信号量当前已上锁，则返回0，或某个负数，绝对值是等待该信号量的线程数。

最后，在各种同步技巧（互斥锁条件变量读写锁信号量）中，能够从信号处理程序中安全调用的唯一函数是sem_post.(暂不理解）

> 信号量既可以上锁又可以等待。但是互斥锁和条件变量分别为了上锁和等待优化，可能有更高的性能。

## 10.5 简单的程序

信号量随内核持续，即使没有进程在使用它，它的值依然被维护。

当持有某个信号量锁的进程没有释放它就终止，此时内核不给信号量解锁。但是持有某个记录锁的进程没有释放就终止时，会自动释放。
思考：上述中的“持有”和“释放”对于信号量来说，可能是等待和挂出。进程结束意味着不再占用资源，所以自动释放可能更合理。

## 10.6 生产者-消费者

环形生产-消费问题
- 共享缓冲区是一个环绕缓冲区。生产者和消费者分别存入和读取数据。
- 单个生产者，单个消费者。
- 生产者仅需把数组下标值填入数组，消费者验证填入值。
- 假设共需要填充和验证items次

缓冲区示意图
![环形缓冲区][1]

面临的问题：生产者不能走到消费者前面。

三个条件：
1. 缓冲为空，消费者不能读取
2. 缓冲区满，生产者不能存入
3. 生产和消费者的操作避免竞争

条件3是因为生产和消费者存在同时对共享数据进行操作的情况，所以进行互斥保护。

需要的信号量：
- 名为mutex的二值信号量，保护生产和消费者的操作，避免竞争
    初始化为1，表示当前临界区可用。（当然也可以用互斥锁来替代）
- 名为nempty的计数信号量统计空槽数目。
    初始化为缓冲区长度。
- 名为nstored的计数信号量统计已填写的槽位数。初始化为0

主程序
```c
#include "unp2.h"
#define NBUFF 10
int nitems=100;
struct {
    int buff[NBUFF];
    sem_t *mutex, *nempty, *nstored;
 } shared;

void *produce(void *), *consume(void *);
int main(int arge, char **argv){
    pthread_t tid_produce, tid_consume；

    /* create three semaphores */
    shared.mutex = Sem_open(Px_ipc_name("mutex"), O_CREAT | O_EXCL,FILE_MODE, 1);
    shared.nempty = Sem_open(Px_ipc_name("nempty"), O_CREAT | O_EXCL,FILE_MODE, NBUFF);
    shared.nstored = Sem_open(Px_ipc_name("nstored"), O_CREAT | O_EXCL,FILE_MODE, 0);

    /* create one producer thread and one consumer thread */
    Set_concurrency(2);
    Pthread_create(&tid_produce, NULL, produce, NULL);
    Pthread_create(&tid_consume, NULL, consume, NULL)；

    /* wait for the two threads */
    Pthread_join(tid_produce, NULL);
    Pthread_join(tid_consume, NULL);

    /* remove the semaphores */
    Sem_unlink(Px_ipc_name("mutex"));
    Sem_unlink(Px_ipc_name("nempty"));
    Sem_unlink(Px_ipc_name("nstored"));
    exit(0);
```
要点
1. 使用我们自己定义的px_ipc_name产生名称以适应不同系统
2. 为了避免信号量已存在，进行unlink并忽视任何错误
3. 另一种方法是指定O_EXCL进行open以检查是否存在，若存在则unlink
4. 结束时也可以用sem_close取代sem_unlink,此时关闭而非删除信号量。不过进程结束时会自动地close。

子函数
```c
void *produce(void *arg){
    int i;
    for (i = 0; i < nitems; i++) {
        Sem_wait(shared.nempty);     /* wait for at least 1 empty slot */
        Sem_wait(shared.mutex);
        shared.buff[i % NBUFF] = i; /* store i into circular buffer */
        Sem_post(shared.mutex);
        Sem_post(shared.nstored);   /* 1 more stored item */
    }
    return(NULL);
}

void *consume(void *arg){
    int i;
    for (i = 0; i < nitems; i++) {
        Sem_wait(shared.nstored);   /* wait for at least 1 stored item */
        Sem_wait(shared.mutex);
        if (shared.buff[ i % NBUFF] != i)
            printf("buff[%d] = %d\n", i, shared.buff[i % NBUFF]);
        Sem_post(shared.mutex);
        Sem_post(shared.nempty);    /* 1 more empty slot */
    }
    return(NULL);
}
```
要点
1. 本例中生产和消费的操作较为简单，没有竞争关系，所以互斥并不必要。但是互斥的情况更常见。

死锁：
在多线程中，互相制约的线程可能造成死锁。
> posix允许sem_wait返回EDEADLK，但是某些实现不支持。

## 10.7 文件上锁

用信号量解决第9章的文件上锁问题。

```c
#define LOCK_PATH "pxsemlock"
sem_t* locksem=0;
int initflag;
void my_lock(int fd){
    if(initflag == 0){
        locksem= Sem_open(Px_ipc_name(LOCK_PATH),O_CREAT,FILE_MODE,1);
        initflag=1;
    }
    Sem_wait(locksem);
}
void my_unlock(int fd){
    Sem_post(locksem);
}
```
要点
- 上锁：如果未打开信号量则先打开；等待信号量。
- 解锁：挂出信号量。

## 10.8 sem_init和sem_destroy函数
本章此前的内容是具名信号量。本节讲述基于内存的信号量。Posix具名信号量由name标识，通常指代文件系统中的某个文件。基于内存的信号量由进程分配，它没有名字。

```c
#include<semaphore.h>
int sem_init(sem_t* sem,int shared,unsigned int value);
返回：若出错则-1
int sem_destroy(sem_t* sem);
返回：成功0，出错-1
```
要点
- sem_init初始化，sem参数指向应用程序必须分配的sem_t变量。
- shared为0则信号量在线程间共享，否则在进程间共享。
- 进程间共享必须放在共享内存中。
- value是初始值。
- sem_destroy执行摧毁操作。

基于内存的信号量不需要类似O_CREAT标志。sem_init总是初始化已有的信号量。
对某个信号量必须只初始化一次，否则结果是未定义的。

sem_open和sem_init一些差异
- sem_open返回一个指向sem_t变量的指针，该变量由sem_open函数本身分配并初始化。
- init需要用户自行创建信号量实体，然后对它初始化。
> posix.1警告说，对于基于内存的信号量，只有sem指针才可以访问信号量，但sem_t类型的副本访问结果未定义
> sem_init出错时返回-1，但成功并不返回0，可能是历史原因。

基于内存的信号量至少随进程持续。如果某个内存区保持有效，则其中的信号量一直存在。
- 如果在单进程内共享，则进程结束后消失
- 如果在进程间共享，则必须放在共享内存区，则随共享内存区存活

Posix和SystemV的共享内存区是随内核持续的，因此其中的基于内存的信号量可以一直存在。

注意：fork并不产生共享内存区
以下并不能预期工作：
```c
sem_t mysem;
sem_init(&mysem,1,0);   /* 2nd arg of 1 */
if(fork()==0){
    ...
    sem_post(&mysem);
}
sem_wait(&mysem);   /* wait for child */
```
问题在于mysem没有在共享内存区中。fork出的子进程通常不共享父进程的内存空间，即，子进程持有父进程的内存空间副本。这和共享内存不是一回事。

具名信号量和基于内存的信号量主要的区别
- 创建和销毁的函数不一样
- 前者只提供指针用于操作，后者提供对象供操作
- 前者机制类似于文件，后者是内存

注意上述区别，就可以在两种形式间随意改写。

## 10.9 多个生产者单个消费者

不同于单个生产者，多个生产者情况中，需要记录下一个待填充的位置和数值。
```c
#include "unpipc.h"
#define NBUFF   1000
#define MAXNTHREADS 100

int nitems, nproducers； /* read- only by producer and consumer */
struct {                /* data shared by producers and consumer */
    int buff[NBUFF];
    int nput,nputval;
    sem_t mutex, nempty, nstored； /* semaphores, not pointers */
} shared；

void produce(void *), *consume(void *);
int main(int arge, char **argv){
    int i, count[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS], tid_consume;
    
    nitems =100；
    nproducers = 10;

    /* initialize three semaphores */
    Sem_init(&shared.mutex, 0, 1);
    Sem_init(&shared.nempty, 0, NBUFF);
    Sem_init(&shared.nstored, 0, 0);
    
    /* create all producers and one consumer */
    Set_concurrency(nproducers+1);
    for (i=0; i < nproducers; i++) {
        count[i]=0;
        Pthread_create(&tid_produce[i], NULL, produce, &count[i]);
    }
    Pthread_create(&tid_consume, NULL, consume, NULL);
    /* wait for all producers and the consumer */
    for (i = 0; i < nproducers; i++) {
        Pthread_join(tid_produce[i], NULL);
        printf("count[%d]=%d\n", i, count[i]);
    }
    Pthread_join(tid_consume, NULL);
    
    Sem_destroy(&shared.mutex);
    Sem_destroy(&shared.nempty);
    Sem_destroy(&shared.nstored )；
    exit(0);
```
要点
- nitems是生产的条目数，nproducers是生产线程数。只读全局变量
- nput是下一个待填充的位置下标，nputval是下一个待填充值。

子程序
```c
void *produce(void *arg){
    for ( ; ; ) {
        Sem_wait(&shared.nempty);  /* wait for at least 1 empty */
        Sem_wait(&shared.mutex);     /* lock */
        if (shared.nput >= nitems) {
            Sem_post(&shared.nempty); /* cancel empty */
            Sem_post(&shared.mutex);    /* unlock */
            return NULL;
        }
        shared.buff[shared.nput % NBUFF] = shared.nputval;
        shared.nput++;
        shared.nputval++;
    
        Sem_post(&shared.mutex)；      /* unlock */
        Sem_post (&shared.nstored);     /* stored one */
        *((int*) arg) += 1；
    }
}
```
要点
- 多个生产者共同生产。nput和nputval是共享数据，需要访问保护。
- 检测到终止条件后退出。
- 生产者在退出前一定要挂出nempty，这样才是统一、完备的。假设只剩下一个空槽，但是数个生产线程中，一个线程获取信号量，其他线程阻塞；如果该线程退出前不挂出，其他线程永远阻塞。
- 当wait到empty，会减一，既然nemtpy代表空槽数，那么相当于已经消化了一个空槽。即刻终止的线程检测到终止条件后退出，它不执行"消耗空槽"操作，所以应该“归还”计数。

思考：实际上，把终止条件放在`nput++`后面也许更合理。当某次操作达到终止条件时立即退出，而不是等下次检验。不过这无伤大雅，不是主要面临的问题。

思考：多个同类线程，退出前应放出导致线程阻塞的信号。

消费者
```c
void *consume(void *arg){
    for (i = 0; i < nitems; i++) {
        Sem_wait(&shared.nstored); /* wait for at least 1 stored item */
        Sem_wait(&shared.mutex);
        
        if (shared.buff[i % NBUFF] ! = i)
            printf("err: buff[%d] = %d\n, i, shared.buff[i % NBUFF]);
        Sem_post(&shared.mutex);
        Sem_post(&shared.nempty); / * 1 more empty slot */
    }
    return(NULL);
```

## 10.10 多个生产者多个消费者

多个生产者和多个消费者同时执行。

这种情况下，同种线程会同时执行，生产和消费线程间有顺序关系。同步变得复杂。

例如：多个进程/线程根据IP地址解析主机名，然后放入资源池中以供使用。
> 注意：gethostbyaddr在线程间使用时必须是线程安全的版本。否则，可以用多进程代替多线程，以绕开线程安全的问题。可用共享内存实现进程通信。
> 思考：线程不安全通常是因为函数内有静态内存。线程间共享全局内存，其他线程调用函数，可能冲掉静态内存的值。但进程间内存独立不存在此问题。

```c
#include "unpipc.h"
#define NBUFF 1000
#define MAXNTHREADS 100

int nitems, nproducers, nconsumers; /* read-only */
struct {                    /* data shared */
    int buff[NBUFF];
    int nput,nputval;
    int nget,ngetval;
    mutex_t mutex, nempty, nstored;
} shared；

void produce(void *), *consume{void *);

```

同样的，如果是多个消费者，则需要数据指示当前待处理的位置，nget是消费者下一个待验证的位置，ngetval则存放期望验证的值。

主函数
```c
int main(int argc, char **argv){
    int i,prod_cnt[MAXNTHREADS],cons_cnt[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS], tid_consume[MAXNTHREADS];
    nitems = 100；
    nproducers = 4;
    nconsumers = 5;

    Sem_init(&shared.mutex, 0, 1);
    Sem_init(&shared.nempty, 0 , NBUFF);
    Sem_init(&shared.nstored, 0, 0)；

    Set_concarrency(nproducers + nconsumers)；
    for (i = 0; i < nproducers；i++) {
        prod_cnt[i] = 0;
        Pthread_create(&tid_produce[i], NULL, produce, &prod_cnt[i])；
    }
    for (i = 0; i < nconsumers；i++) {
        conscount[i] = 0;
        Pthread_create(&tid_consume[i], NULL, consume, &cons_cnt[i]);
    }

    for (i = 0；i < nproducers; i++) {
        Pthread_join(tid_produce[i] , NULL);
        printf("producer count[%d] = %d\n", i, prod_cnt[i] )；
    }
    for (i = 0; i < nconsumers; i++) {
        Pthread_join(tid_consume[i], NULL)；
        printf("consumer count[%d] = %d\n", i, cons_cnt[i]）；
    }
    Sem_destroy(&shared.mutex);
    Sem_destroy(&shared.nempty);
    Sem_destroy(&shared.nstored);
    exit(0);
```
cons_cnt保存每个消费者线程处理的条目数。

生产者
相对于上节，仅仅添加如下[+]行
```c
if(shared.nput>=nitems){
[+] Sem_post(&shared.nstored);  /* let consume terminate */
    Sem_post(&shared.nempty);
    Sem_post(&shared.mutex);
    return NULL:
}
```

新加行让消费者终止。缓冲区所有条目被消费掉后，所有消费者线程会阻塞于等待nstored。我们让每个生产者线程结束时给nstored信号加一，以给各个消费者线程解阻塞。

消费者
```c
void * consume(void* arg）{
    int i；
    for ( ; ; ) {
        Sem_wait(&shared.nstored)；     /* wait for at least 1 stored item */
        Sem_wait(&shared.mutex);
        if (shared.nget >= nitems) {
            Sem_post(&shared.nstored);  /* for partners */
            Sem_post(&shared.mutex);
            return(NULL);
        }

        i = shared.nget % NBUFF；
        if (shared.buff[i] != shared.ngetval)
            printf("err: buff[%d] = %d\n", i , shared.buff[i]);
        shared.nget++;
        shared.ngetval++;
        Sem_post(&shared.mutex);
        Sem_post(&shared.nempty);
        *((int*)arg)+= 1；
    }
}

```

可见，阻塞问题有：
- 同种线程的阻塞

线程进入循环时，必定会等待某个信号量。这样在信号量计数少于线程数时，必定有线程阻塞。因此第一个率先达到终止条件的线程需要放出信号量，便于其他线程解阻塞。其他都会消化信号量并解阻塞后，判断达到终止条件而结束，此时均会放出信号量。便于下一个阻塞线程消化信号量并解阻塞。

- 生产与消费间的阻塞【待测试】
生产者终止时，需要给出消费者解阻塞信号量。？？暂且不明，因为即使没有，消费者看上去也可以被率先终止的消费者发出的信号量解阻塞，而且解阻塞后会判断终止，终止时又会发出信号量，因而连锁反应使得所有线程终止。
。。。。？、？？？ 

## 10.11 多个缓冲区

本节可以认为是生产消费者的一个具体例子。

在处理一些数据的典型程序中，下面的循环很常见：
```c
while( (n=read(fdin,buff,BUFFSIZE))>0 ){
    /* deal with data */
    write(fdout,buff,n);
}
```
这种模式的时序为：
`读入-> 处理 -> 输出`，
而且只使用一个固定的缓冲区

为了便于说明，我们只认为处理过程分为读入和输出两个步骤。

![三种模式][2]

图中演示了三种情况
1. 单线程单缓冲：逐步进行读写
2. 多线程单缓冲：两个线程一个读一个写；但是缓冲区只有一个，所以写线程完成后，读线程才能读；反之亦然。所以没有时间上的优势。
3. 多线程多缓冲：读的同时，另一个线程可以写。约束在于：某个缓冲区读入数据后，才可以被写出；

经典的双缓冲方案：两个线程两个缓冲区。相当于单生产单消费，两格的环形缓冲区。

我们可以使用两个线程/进程，一个读入，一个输出。读入的线程只管读取，读取后存入缓冲区。输出的线程只管输出。此时要用到多个缓冲区。毕竟读入线程会读入多条数据，以备输出线程逐个处理。

线程间通知
- 读入线程读取后需要通知输出线程，可以输出。
- 已输出后，输出线程通知读入线程，缓冲区已处理完毕，可以再次写入。（当然，这里假设缓冲区是重复利用的状态，如环形。如果不需重复利用，则不必通知）

思考：两个线程一个读一个写，而不是多线程，每个线程各自完成读写。原因在于从文件中读写，是有顺序的。文件指针的位置是唯一的。文件的多线程读写可能需要使用某些同步，暂不明。

使用内存信号量，NBUFF指定缓冲区个数。

```
#include "unpipc.h"
#define NBUFF 8
struct {                /* data shared by producer and consumer */
    struct {
        char    data[BUFFSIZE]; /* a buffer */
        ssize_t n;      /* count of #bytes in the buffer */
    } buff[NBUFF]；     /* NBUFF of these buffers/counts */
    sem_t mutex, nempty, nstored;   /* semaphores, not pointers */
} shared;

int fd;         /* input file */
void *produce(void*), *consume(void*);

int main(int argc, char **argv){
    pthread_t tid_produce, tid_consume；
    if(argc != 2)
        err_quit("usage: mycat2 <pathnamc>");

    fd = Open(argv[1], O_RDONLY);
    
    /* initialize three semaphores */
    Sem_init(&shared.mutex, 0, 1);
    Sem_init(&shared.nempty, 0, NBUFF);
    Sem_init(&shared.nstored, 0, 0);

    /* one producer thread, one consumer thread */
    Set_concurrency(2);
    Pthread_create(&tid_produce, NULL, produce, NULL);
    Pthread_create(&tid_consume, NULL, consume, NULL);

    Pthread_join(tid_produce, NULL);
    Pthread_join(tid_consume, NULL);

    Sem_dostroy(&shared.mutex);
    Sem_destroy(&shared.nempty);
    Sem_destroy(&shared.nstored);
    exit(0);
}
```
要点：
- 有NBUFF个缓冲区，每个缓冲区由一个数组data和长度值n构成。


子函数
```c
void *produce(void arg){
    int i;
    for(i = 0; ; ) {
        Sem_wait(&shared.nempty);       /* wait for at least 1 empty slot */
        Sem_wait(&shared.mutex);
        /* deal with data */
        Sem_post(&shared.mutex);
        shared.buff[i].n = Read(fd, shared.buff[i].data, BUFFSIZE);
        if (shared.buff[i].n == 0) {
            Sem_post(shared.nstored);
            return(NULL);
        }
        if (++i >= NBUFF)
            i=0;                /* circular buffer */
        
        Sem_post(&shared.nstored )； /* 1 more stored item */
    }
}

void *consume(void *arg){
    int i;
    for (i = 0; ; ) {
        Sem_wait(&shared.nstored);      /* wait for at least 1 stored item */
        Sem_wait(&shared.mutex);
        /* critical region */
        Sem_post(&shared.mutex);
        if (shared.buff[i].n == 0)
            return(NULL)；
        Write(STDOUT_FILENO, shared.buff[i].data, shared.buff[i].n);
        if(++i >= NBUFF)
            i = 0;          /* circular buffer */
        Scm_post(&shared.nempty);        /* 1 more empty slot * /
    }
}
```

要点
- 使用互斥锁作为操作保护，尽管在单生产单消费没有必要。不过感觉互斥锁位置不太对。。。【？】
- 生产者结束条件：read到EOF
- 消费者结束条件：碰到长度为0的缓冲区表示都处理完毕。因为是环形依次处理的，结束前不应遇见空缓冲区。

【同样地，这里的线程退出时解阻塞的问题待测试。】

## 10.12 进程间共享信号量
具名信号量总可以在进程间共享。特定名字会索引到同一个信号量。
> 每个进程sem_open可能返回不同的指针（可能是内存映射，不明），但是这些指针索引同一个信号量。

如果在sem_open返回指针后，接着调用fork，那么父进程的信号量仍在子进程打开，依然可以用指针进行操作。
以下可以正常运行
```c
sem_t* mysem;
mysem=sem_open(...)
if( fork()==0){
    sem_wait(mysem);
}
sem_post(mysem);
```
思考：可能因为具名信号量具有文件的特性，所以进程中信号量实体实际上类似于文件描述符，是对资源的引用，而非资源本身。

而基于内存的信号量在内存中，随着子进程对父进程的内存空间复制，它也会复制，并且失效。详见之前章节。

基于内存的信号量在进程间共享条件：在共享内存中，sem_init的第二个参数为1。
> 对照：进程间共享互斥锁/条件变量/读写锁的情况类似，必须在共享内存且指定PHTREAD_PROCESS_SHARED属性。

> 造成具名和内存信号量情况不同的主要因素，是前者存放在文件或内核（表现更接近文件），使用时类似于文件描述符的索引机制，所以跨进程很容易。后者存放于内存，是一个内存变量，所以依托于内存。

## 10.13 信号量限制
Posix定义两个常量限制
SEM_NSEMS_MAX 一个进程可同时打开的最大信号量数（要求至少256）
SEM_VALUE_MAX 一个信号量的最大值(Posix要求至少32767）
它们通常定义在<unistd.h>中，可在运行中调用sysconf函数获取
```c
long nmax=sysconf(_SC_SEM_NSEMS_MAX);
long vmax=sysconf(_SC_SEM_VALUE_MAX);
```

## 10.14 使用FIFO实现信号量（略）
## 10.15 使用内存映射IO实现信号量（略）
## 10.16 使用SystemV信号量实现Posix信号量（略）

## 一些小结和补充
有名和无名
表现为文件 内存中
总可以在进程间 初始化指定是否在内存间共享
至少随内核 随进程，但也共享内存。。。 严格来说是随内存

## 习题

在获取信号量后进程崩溃，不会自动释放信号量，可能造成错误。

posix1指定了一个可选功能：sem_wait可被信号中断返回EINTR

  [1]: https://yskimg.oss-cn-beijing.aliyuncs.com/unp_2/circle_product_consume.png
  [2]: https://yskimg.oss-cn-beijing.aliyuncs.com/unp_2/circle_product_consume.png
  
