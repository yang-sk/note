# 第10章 信号量

## 10.1 概述
信号量(semaphore)可以在进程间或线程间做同步。

本书的信号量按类型分为三种
- Posxi有名信号量，使用PosixIPC名字来标识
- Posix基于内存的信号量，放在共享内存中
- SystemV信号量，在内核中维护

信号量可以在内核或文件系统中维护。

Posix信号量由文件路径名来标识，尽管可能(但非必需)在内核中维护。

注意：原书中更倾向认为信号量是“文件”，甚至在10.8中提到："它通常指代文件系统中的某个文件"。

按照使用方式，可以分为二值信号量和计数信号量。前者用以实现类似互斥锁的功能，后者用以计数。但是本质没有区别。

对信号量的操作：
- 创建。需要指定初值，二值信号量初值通常是1
- 等待。测试信号量的值，如果大于0则减一，如果小于等于0则一直阻塞
- 挂出。把信号量的值加一

信号量可用于互斥(类似于互斥锁)。互斥锁与信号量使用流程对照
```
初始化互斥锁             |    初始化信号量为1
pthread_mutex_lock     |     sem_wait
临界区                  |     临界区
pthread_mutex_unlock   |     sem_post
```
思考：信号量表征了资源的状态。信号量为0，表示正在被独占。大于0表示可以被使用。

例子：生产者每次向缓冲区添加条目，消费者每次从缓冲区取出条目。缓冲区只能容纳一个条目。
``` 
生产者 -> [缓冲区] -> 消费者
```

伪代码如下
```c
         初始化：empty=1,full=0;
--------------------------------------------
       [生产者]       |         [消费者]
while(1){            |  while(1){
    sem_wait(empty); |      sem_wait(full);
    insert_item;     |      delete_item;
    sem_post(full);  |      sem_post(empty);
}                    |  }
```

> 正在等待信号量的线程会标记为ready-to-run

信号量与互斥锁和条件变量的差异
- 互斥锁必须总是由获取锁的线程解锁，信号量的挂出却不必由等待它的线程执行。
- 互斥锁只有被占用和未被占用两种状态，信号量可以计数
- 条件变量可以发出信号，但是如果没有线程等待该信号，则信号丢失。信号量可以看做是信号的计数，所以不会丢失。

> 信号量发明的初衷是为了进程间通信，互斥锁和条件变量发明的初衷是线程间通信。

思考：post可以认为是发出一个信号; wait可以是等待(并消化)一个信号。信号量的值，表示“悬空”的信号个数。

Posix提供有名信号量和基于内存的信号量，后者也称无名信号量。

两者使用的函数有所区别。

```
有名信号量       |      基于内存的信号量
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

sem_open打开或创建有名信号量。有名信号量总是可用于线程和进程同步。
```c
#include<semaphore.h>
sem_t* sem_open(const char* name,int oflag,.../* mode_t mode,unsigned int value */);
返回：若成功则为指向信号量的指针，出错则SEM_FAILED
```
要点
- name遵循PosixPIC名称规则。
- oflag可以是0、O_CREAT或 O_CREAT|O_EXCL。(书中某例程还使用了O_RDWR，猜测可能和消息队列一样，默认需要读写权限)
- 如果指定了O_CREAT标志，那么第三个和第四个参数是需要的。
- mode指定权限位，value指定初始值。初始值不能超过SEM_VALUE_MAX(这个常值至少为21767)
- 二值信号量初值往往是1，计数信号量初值往往大于1
- 函数返回了一个信号量指针，信号量被函数本身分配并初始化。[动态分配，还是类似于文件描述符仅仅是索引值，暂不明]

> 在原书作者测试的两个系统上，oflag无需指定读写权限，默认要求读写权限。[待测试?]

##### sem_close关闭信号量

```c
#include<semaphore.h>
int sem_close(sem_t* sem);
返回：成功则0，出错-1
```
进程终止时会关闭其上所有的有名信号量，不论进程自愿(调用_exit)还是非自愿终止(接收Unix信号)。

关闭信号量不会从系统中删除。即，它至少是随内核持续的。

##### 有名信号使用sem_unlink从系统中删除

```c
#include<semaphore.h>
int sem_unlink(const char* name);
成功则0，出错-1
```
类似于文件，信号量具有引用计数。close和unlink的操作与文件类似。

- unlink立即删除系统中的文件名(文件名的存在本身就是一个计数)，并减少引用计数; 
- close使得文件不可被读写等操作，并减少引用计数。
- 内核在对象的计数为0时会析构对象。

测试ubuntu16.04发现，没有其他进程使用文件时，进程在unlink某文件会即刻删除该文件(至少看上去是这样).

## 10.3 sem_wait和sem_trywait
等待目标信号量的值大于0.如果大于0则减1并返回。整个操作是原子的。

try是非阻塞版本,信号量为0时返回EAGAIN错误。

```c
#include<semaphore.h>
int sem_wait(sem_t* sem);
int sem_trywait(sem_t* sem);
返回：成功0，出错-1
```
同大多数的阻塞函数一样，阻塞版本会被中断，返回EINTR

## 10.4 sem_post 和 sem_getvalue
线程使用完某个信号量时，应该调用sem_post，这会使得信号量加1，从而唤醒某些等待进程(如果此时信号量为正)。

```c
#include<semaphore.h>
int sem_post(sem_t* sem);
int sem_getvalue(sem_t* sem,int* valp);
返回：成功0，出错-1
```
取值函数可以返回信号量当前值。如果该信号量当前已上锁，则返回0(或某个负数，绝对值是等待该信号量的线程数，取决于实现)。

最后，在各种同步技巧(互斥锁条件变量读写锁信号量)中，能够从信号处理程序中安全调用的唯一函数是sem_post。

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
- 假设共需要填充和验证items次。

缓冲区示意图

![c10_circle_product_consume](c10_circle_product_consume.png)


面临的问题：生产者不能走到消费者前面。

三个条件：
1. 缓冲为空，消费者不能取出
2. 缓冲区满，生产者不能存入
3. 生产和消费者的操作避免竞争

条件3是因为生产和消费者存在同时对共享数据进行操作的情况，所以进行互斥保护。

需要的信号量：
- 名为mutex的二值信号量，保护生产和消费者的操作，避免竞争; 初始化为1，表示当前临界区可用。(当然也可以用互斥锁来替代)
- 名为nempty的计数信号量统计空槽数目。初始化为缓冲区长度。
- 名为nstored的计数信号量统计已填写的槽位数。初始化为0

在本例程中，生产者仅仅是把数组下标放入数组中，消费者做验证。

#### 主程序

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
    pthread_t tid_produce, tid_consume;

    /* create three semaphores */
    shared.mutex = Sem_open(Px_ipc_name("mutex"), O_CREAT | O_EXCL,FILE_MODE, 1);
    shared.nempty = Sem_open(Px_ipc_name("nempty"), O_CREAT | O_EXCL,FILE_MODE, NBUFF);
    shared.nstored = Sem_open(Px_ipc_name("nstored"), O_CREAT | O_EXCL,FILE_MODE, 0);

    /* create one producer thread and one consumer thread */
    Set_concurrency(2);
    Pthread_create(&tid_produce, NULL, produce, NULL);
    Pthread_create(&tid_consume, NULL, consume, NULL);

    /* wait for the two threads */
    Pthread_join(tid_produce, NULL);
    Pthread_join(tid_consume, NULL);

    /* remove the semaphores */
    Sem_unlink(Px_ipc_name("mutex"));
    Sem_unlink(Px_ipc_name("nempty"));
    Sem_unlink(Px_ipc_name("nstored"));
    exit(0);
}  //code 10-17
```
要点
1. 使用我们自己定义的px_ipc_name产生名称以适应不同系统
2. 为了避免信号量已存在，进行unlink并忽视任何错误。另一种方法是指定O_EXCL进行open以检查是否存在，若存在则unlink
3. 结束时也可以用sem_close取代sem_unlink，此时关闭而非删除信号量。不过进程结束时会自动地close。

#### 子函数

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
}   // code 10-18
```
注意：本例中生产和消费的操作较为简单，没有竞争关系，所以互斥并不必要。但是互斥的情况更常见(如下节所示)。

##### 死锁

在多线程中，互相制约的线程可能造成死锁。

> posix允许sem_wait返回EDEADLK，但是某些实现不支持。

## 10.7 文件上锁

用信号量解决第9章的文件上锁问题。

```c
#define LOCK_PATH "pxsemlock"
sem_t * locksem;
int initflag;
void my_lock(int fd){
    if(initflag == 0){
        locksem = Sem_open(Px_ipc_name(LOCK_PATH),O_CREAT,FILE_MODE,1);
        initflag = 1;
    }
    Sem_wait(locksem);
}
void my_unlock(int fd){
    Sem_post(locksem);
}  // code 10-19
```
要点
- 上锁：如果未打开信号量则先打开; 等待信号量。
- 解锁：挂出信号量。

## 10.8 sem_init和sem_destroy函数
本章此前的内容是有名信号量。本节讲述基于内存的信号量。Posix有名信号量由name标识，通常指代文件系统中的某个文件。基于内存的信号量由进程分配内存空间并初始化，它没有名字。

同有名信号量一样，它的数据类型也是sem_t。不过前者使用sem_open创建或打开，并返回一个指针(而不是实体对象)以供操作。后者必须手动创建实体对象并初始化。

初始化与摧毁函数：

```c
#include<semaphore.h>
int sem_init(sem_t* sem,int shared,unsigned int value);
返回：若出错则-1
int sem_destroy(sem_t* sem);
返回：成功0，出错-1
```
要点
- sem_init执行初始化，sem参数指向已经分配的sem_t变量。
- shared为0则信号量在线程间共享，否则在进程间共享。
- 进程间共享必须放在共享内存中。
- value是初始值。
- sem_destroy执行摧毁操作。

基于内存的信号量不需要类似O_CREAT标志。sem_init总是初始化已有的信号量。

对某个信号量必须只初始化一次，否则结果是未定义的。

##### sem_open和sem_init一些差异

- sem_open返回一个指向sem_t变量的指针，该变量由sem_open函数本身分配并初始化。
- init需要用户自行创建信号量实体，然后对它初始化。
> posix.1警告说，对于基于内存的信号量，只有sem指针才可以访问信号量，但sem_t类型的副本访问结果未定义
> sem_init出错时返回-1，但成功并不返回0，可能是历史原因。

基于内存的信号量至少随进程持续。如果某个内存区保持有效，则其中的信号量一直存在。
- 如果在单进程内共享，则进程结束后消失
- 如果在进程间共享，则必须放在共享内存区，则随共享内存区存活

Posix和SystemV的共享内存区是随内核持续的，因此其中的基于内存的信号量可以一直存在。

注意：fork并不产生共享内存区，以下并不能预期工作：
```c
sem_t mysem;
sem_init(&mysem,1,0);   /* 2nd arg of 1 */
if(fork()==0){
    ...
    sem_post(&mysem);
}
sem_wait(&mysem);   /* wait for child */
```
问题在于mysem没有在共享内存区中。fork出的子进程通常不共享父进程的内存空间，子进程持有父进程的内存空间副本。这和共享内存不是一回事。

##### 有名信号量和基于内存的信号量主要的区别

从编写代码的角度来说：

- 创建和销毁的函数不一样
- 前者只提供指针用于操作，后者提供对象供操作

从机制和特性的角度来说：
- 前者机制类似于文件，后者是内存
- 前者总可以在进程间共享(而不需要指定某些标志)，后者必须指定标志并在共享内存中才可以在进程间共享
- 前者至少随内核持续，后者随所在内存的存活期持续

注意上述区别，就可以在两种形式间随意改写。

## 10.9 多个生产者单个消费者

本节中，有多个生产者，向数组填充不断递增的值。

不同于单个生产者，多个生产者情况中，需要记录下一个待填充的位置和数值。

#### 主程序

```c
#include "unp2.h"
#define NBUFF   10
#define MAXNTHREADS 100

int nitems, nproducers;  /* read- only by producer and consumer */
struct {                /* data shared by producers and consumer */
    int buff[NBUFF];
    int nput,nputval;
    sem_t mutex, nempty, nstored;  /* semaphores, not pointers */
} shared;

void *produce(void *), *consume(void *);
int main(int arge, char **argv){
    int i, count[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS], tid_consume;

    nitems =100;
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
    Sem_destroy(&shared.nstored );
    exit(0);
}   // code 10-21
```
要点
- nitems是生产的条目数，nproducers是生产线程数，它们是只读全局变量
- nput是下一个待填充的位置下标，nputval是下一个待填充值。

#### 子程序

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

        Sem_post(&shared.mutex);       /* unlock */
        Sem_post (&shared.nstored);     /* stored one */
        *((int*) arg) += 1;
    }
}  // code 10-22
```
要点
- 多个生产者共同生产。缓冲区以及nput和nputval是共享数据，需要访问保护。

- 生产者检测到终止条件后退出。

生产者在退出前一定要挂出nempty。可以从两方面解释：
-  避免同类线程阻塞。假设只剩下一个空槽，但是数个生产线程中，一个线程获取空槽信号量，其他线程阻塞; 如果该线程退出前不挂出空槽信号量，其他线程永远阻塞。
-  维持正确的计数含义。当wait到empty时会减1，既然nemtpy代表空槽数，那么相当于已经消化了一个空槽。即刻终止的线程检测到终止条件后退出，它不执行"消耗空槽"操作，所以应该“归还”空槽计数。

思考：假设场景如下：只需放置一个条目，有100个生产者线程，缓冲区大小是5，此时空槽量是5。开始时5个生产线程进入迭代，其他95个阻塞，空槽量是0；1号线程获取了互斥锁，并处理完毕后释放互斥锁和装槽信号量。2号线程获取了互斥锁，但是发现终止条件到达，于是释放锁并退出，此时空槽量还是0。其他345号相继获取互斥锁，然后释放锁并终止。消费者消费了槽，放出空槽量，此时又有一个线程占有了空槽量进入迭代，终止。此时还有94个生产者阻塞。

思考：生产者每次迭代时，首要任务当然是检查是否达到结束条件。因此必然是检查在前，退出或处理在后。至于处理后是否还需检查终止条件并退出(而不是等下次迭代)其实无伤大雅，不是主要面临的问题。主要问题在于结束时的同类线程阻塞。

思考：多个同类线程，退出前应放出导致线程阻塞的信号。

#### 消费者

消费者同“单生产-单消费”的情况一致，没什么变动。

```c
void *consume(void *arg){
    int i;
    for (i = 0; i < nitems; i++) {
        Sem_wait(&shared.nstored); /* wait for at least 1 stored item */
        Sem_wait(&shared.mutex);

        if (shared.buff[i % NBUFF] != i)
        	printf("err: buff[%d] = %d\n", i, shared.buff[i % NBUFF]);
        Sem_post(&shared.mutex);
        Sem_post(&shared.nempty); /* 1 more empty slot */
    }
    return(NULL);
}  //code 10-23
```

## 10.10 多个生产者多个消费者

本节代码中，多个生产者和多个消费者同时执行。

这种情况下，同种线程会同时执行，且生产和消费线程间有顺序关系。同步变得复杂。

例如：多个进程/线程根据IP地址解析主机名，然后放入资源池中以供使用。
> 注意：gethostbyaddr在线程间使用时必须是线程安全的版本。否则，可以用多进程代替多线程，以绕开线程安全的问题。可用共享内存实现进程通信。
> 思考：线程不安全通常是因为函数内有静态内存。线程间共享全局内存。其他线程调用函数，可能冲掉静态内存的值。但进程间内存独立不存在此问题。

#### 全局变量

```c
#include "unpipc.h"
#define NBUFF 10
#define MAXNTHREADS 100

int nitems, nproducers, nconsumers; /* read-only */
struct {                    /* data shared */
    int buff[NBUFF];
    int nput,nputval;
    int nget,ngetval;
    sem_t mutex, nempty, nstored;
} shared; 

void *produce(void *), *consume(void *);
// code 10-24
```

同样的，如果是多个消费者，则需要数据指示当前待处理的位置，nget是消费者下一个待验证的位置，ngetval则存放期望验证的值。

#### 主函数

```c
int main(int argc, char **argv){
    int i,prod_cnt[MAXNTHREADS],cons_cnt[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS], tid_consume[MAXNTHREADS];
    nitems = 100; 
    nproducers = 4;
    nconsumers = 5;

    Sem_init(&shared.mutex, 0, 1);
    Sem_init(&shared.nempty, 0 , NBUFF);
    Sem_init(&shared.nstored, 0, 0); 

    Set_concarrency(nproducers + nconsumers); 
    for (i = 0; i < nproducers; i++) {
        prod_cnt[i] = 0;
        Pthread_create(&tid_produce[i], NULL, produce, &prod_cnt[i]); 
    }
    for (i = 0; i < nconsumers; i++) {
        conscount[i] = 0;
        Pthread_create(&tid_consume[i], NULL, consume, &cons_cnt[i]);
    }

    for (i = 0; i < nproducers; i++) {
        Pthread_join(tid_produce[i] , NULL);
        printf("producer count[%d] = %d\n", i, prod_cnt[i]); 
    }
    for (i = 0; i < nconsumers; i++) {
        Pthread_join(tid_consume[i], NULL); 
        printf("consumer count[%d] = %d\n", i, cons_cnt[i]); 
    }
    Sem_destroy(&shared.mutex);
    Sem_destroy(&shared.nempty);
    Sem_destroy(&shared.nstored);
    exit(0);
}   // 10-25
```
cons_cnt保存每个消费者线程处理的条目数。

#### 生产者

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

#### 消费者

```c
void * consume(void* arg){
    int i; 
    for ( ; ; ) {
        Sem_wait(&shared.nstored);      /* wait for at least 1 stored item */
        Sem_wait(&shared.mutex);
        if (shared.nget >= nitems) {
            Sem_post(&shared.nstored);  /* for partners */
            Sem_post(&shared.mutex);
            return(NULL);
        }

        i = shared.nget % NBUFF; 
        if (shared.buff[i] != shared.ngetval)
            printf("err: buff[%d] = %d\n", i , shared.buff[i]);
        shared.nget++;
        shared.ngetval++;
        Sem_post(&shared.mutex);
        Sem_post(&shared.nempty);
        *((int*)arg)+= 1; 
    }
}  // 10-26
```

#### 思考

##### 上述方法的重点在于以下几个方面：

1. 生产与消费间互相制约的信号量。生产者需要空槽量，消费者需要占位量。生产条目后放出占位量，消费条目后放出空槽量。
2. 互斥锁(二值信号量)。包括以下两方面：
   - 同类线程间的互斥锁。因为同类线程会同时运作。
   - 生产消费间的互斥锁。因为某个生产者和某个消费者可能同时运作。单靠计数信号量不能实现互斥锁。
3. 终止时的信号偿还。检测到终止条件时退出，退出前偿还本线程解阻塞的信号量。
4. 生产者放出消费者解阻塞的信号量。

##### 为什么会出现第3条？

如果进入迭代时发现已被终止，应该退出线程。但是在wait信号量后会将信号量减一；也就是说，进入迭代需要消耗1个信号量；若检测到终止条件，则会退出，此时未做任何操作，应该归还信号量。(例如，生产者进入迭代需要消耗空槽数，但是检测到终止并退出，并没有向空槽填充数据，也就不存在消耗空槽的行为。)所以这个过程是“有借有还”的，借到信号量解阻塞，如果终止会归还信号量，从结果来看仅仅是“和平”地终止了一个线程，信号量没有什么变化。

##### 为什么会出现第4条？

首先需要明晰具体的处理模式。每个线程不断迭代，每次迭代的流程如下(省去了互斥锁)：

```c
等待信号量-检测是否终止-若终止则偿还信号量并退出-处理数据-下一轮迭代
```

处理数据前当然要检测是否终止，这是不可避免的。问题在于处理数据后不再检测是否终止，所以终止条件第一次达成时，不会立即终止，而是进入下一轮迭代。下一轮迭代时，终止条件已达成，但所有的线程都在等待信号量，并期待进入迭代检测到终止，然后偿还信号量并退出。

此时，只要有一个信号量，所有线程可以逐个退出。因为进入迭代消耗信号量，终止时偿还信号量，等于一个有借有还的过程。从结果上说，这样仅仅是终止了一个线程，信号量的计数并未改变。此时只要有一个信号量，被阻塞的线程会触发连锁反应，逐个解锁并退出。

- 对于生产者来说，某个生产者生产完最后一个条目时，应该是有空槽的(即使没有，消费者也一定可以消费掉某个条目产生空槽，毕竟最后一个条目刚被生产出来)， 那么空槽会触发"有借有还"过程，所以问题不大。
- 对于消费者来说，某个消费者在消费完最后一个条目时，占位数为零，因为没有条目了；既然最后一个条目被消费，说明生产者已经生产完毕，不再放出占位信号。没有占位数的情况下，所有消费者都会阻塞。

所以为了解除这种情况，需要在生产者结束时释放占位信号。生产者终止意味着所有生产任务已经结束，不必担心会扰乱生产消费之间的调度。

##### 另一种方案

出现上述现象的根本问题在于第一次检测到终止条件时，并没有立即终止线程，而是等到下一次迭代。在下一次迭代时，会出现所有线程等待信号量的情况。如果终止条件达成时，外部没有信号量计数，则所有线程将阻塞。

因此，可以在第一次检测到信号量时，立即终止线程，并放出信号量。这样就不需要借助外部的信号量，从而实现同类线程解锁。

首个结束的线程应该放出信号量。这个信号量是借给同类的，此时会触发连锁反应，借-终止-还，各个阻塞的线程依次解锁并结束，最后所有线程都结束。这样的话，信号量是比期望真实意义下的计数多1.

所以可以是这样：

```c
void* func(void* arg){
  for(;;){
    sem_wait(sem);
    if(finish){
      sem_post(sem);
      return NULL;
    }
    deal-with-data;
    if(finish){
      sem_post(sem);
      return NULL;
    }
    ....
  }
}
```

注意，代码中有两次if(finish)，但意义不同，第一处放出信号量是为了“偿还”，第二处是为了“解救同类”。

这里增加了步骤：生产最后一个条目后，即刻终止，并释放信号。引起同类的连锁解锁。此时解锁信号是内部产生的，而不是外部。消费者也可以如法炮制，不需要生产者结束时释放占位信号。

这样的话，生产结束时不需要显式放出占位信号，两种类型的线程间更加独立。

最后强调的是，整个任务结束后，信号量是比期望真实意义下的计数多1。而原书的模式，信号量计数会混乱得多。

> 其实想想，没准某个线程检测到终止条件时，杀掉所有同类线程更直接。但是线程应设置立即终止(而不是延后终止)，但也可能出现某线程处理数据完毕，再做其他事情(比如打印)时被强行终止，出现坏数据的情况。

## 10.11 多个缓冲区

本节可以认为是多生产-多消费者的一个具体例子。

在处理一些数据的典型程序中，下面的循环很常见：
```c
while( (n=read(fdin,buff,BUFFSIZE))>0 ){
    /* deal with data */
    write(fdout,buff,n);
}
```
这种模式的时序为：[读入-> 处理 -> 输出]，而且只使用一个固定的缓冲区。

为了便于说明，我们只认为处理过程分为读入和输出两个步骤。

对于此类情况，下图给出了三种方案：

![c10_multi_thread_buff](c10_multi_thread_buff.svg)

图中演示了三种情况
1. 单线程单缓冲：逐步进行读写
2. 多线程单缓冲：两个线程一个读一个写; 但是缓冲区只有一个，所以写线程完成后，读线程才能读; 反之亦然。所以线程间需要互相通知，而且没有时间上的优势。
3. 多线程多缓冲：一个读入一个输出。读入的线程只管读取到缓冲区，输出的线程只管从缓冲区输出。一个线程读的同时，另一个线程可以写。使用多个缓冲区，打破了单缓冲的限制。读入线程会读入多条数据，以备输出线程逐个处理。此时的约束在于：某个缓冲区读入数据后，才可以被写出；某个缓冲区写出数据后，才可以被重新读入。 

所以上述是一个生产消费问题。

经典的双缓冲方案：两个线程两个缓冲区。相当于单生产单消费，两格的环形缓冲区。

线程间通知
- 读入线程读取后需要通知输出线程，可以输出。
- 已输出后，输出线程通知读入线程，缓冲区已处理完毕，可以再次写入。(当然，这里假设缓冲区是重复利用的状态，如环形。如果不需重复利用，则不必通知)

思考：两个线程一个读一个写，而不是多线程，每个线程各自完成读和写。原因在于从文件中读写应该是有顺序的。当前文件指针的位置是唯一的。文件的多线程读写可能需要使用某些同步，暂不明。

#### 主程序代码

使用内存信号量，NBUFF指定缓冲区个数。

有NBUFF个缓冲区，每个缓冲区由一个数组data和长度值n构成。

```c
#include "unpipc.h"
#define NBUFF 8
struct {                /* data shared by producer and consumer */
    struct {
        char    data[BUFFSIZE]; /* a buffer */
        ssize_t n;      /* count of #bytes in the buffer */
    } buff[NBUFF];      /* NBUFF of these buffers/counts */
    sem_t mutex, nempty, nstored;   /* semaphores, not pointers */
} shared;

int fd;         /* input file */
void *produce(void*), *consume(void*);

int main(int argc, char **argv){
    pthread_t tid_produce, tid_consume; 
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
#### 子函数

```c
void *produce(void arg){
    int i;
    for(i = 0; ; ) {
        Sem_wait(&shared.nempty);       /* wait for at least 1 empty slot */
        Sem_wait(&shared.mutex);
        /* critical region */
        Sem_post(&shared.mutex);
        shared.buff[i].n = Read(fd, shared.buff[i].data, BUFFSIZE);
        if (shared.buff[i].n == 0) {
            Sem_post(shared.nstored);
            return(NULL);
        }
        if (++i >= NBUFF)
            i=0;                /* circular buffer */
        
        Sem_post(&shared.nstored );  /* 1 more stored item */
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
            return(NULL); 
        Write(STDOUT_FILENO, shared.buff[i].data, shared.buff[i].n);
        if(++i >= NBUFF)
            i = 0;          /* circular buffer */
        Sem_post(&shared.nempty);        /* 1 more empty slot * /
    }
}
```

要点
- 使用互斥锁作为操作保护，尽管在单生产单消费没有必要。因为信号量之间的约束已经可以完成互斥锁的功能。[不过感觉互斥锁位置不太对, 共享数据应该包在互斥锁内部的]
- 生产者结束条件：read到EOF
- 消费者结束条件：碰到长度为0的缓冲区表示都处理完毕。因为是环形依次处理的，结束前不应遇见空缓冲区。

## 10.12 进程间共享信号量
有名信号量总可以在进程间共享。特定名字会索引到同一个信号量。
> 每个进程sem_open可能返回不同的指针(猜测是内存映射，不明)，但是这些指针索引同一个信号量。

如果在sem_open返回指针后，接着调用fork，那么父进程的信号量仍在子进程打开，依然可以用指针进行操作。

以下可以正常运行

```c
sem_t* mysem;
mysem=sem_open(...)
if( fork()==0 ){
    sem_wait(mysem);
}
sem_post(mysem);
```
思考：可能因为有名信号量具有文件的特性，所以进程中信号量实体实际上类似于文件描述符，是对资源的引用，而非资源本身。而基于内存的信号量，资源就在其本体中。

思考：而基于内存的信号量在内存中，随着子进程对父进程的内存空间复制，它也会复制并且失效，因为之前章节说过，对信号量副本的访问可能与预期不符。

基于内存的信号量在进程间共享条件：位于共享内存中，sem_init的第二个参数为1。
> 对照：进程间共享互斥锁/条件变量/读写锁的情况类似，必须在共享内存且指定PHTREAD_PROCESS_SHARED属性。

> 造成有名和内存信号量情况不同的主要因素，是前者存放在文件或内核(表现更接近文件)，使用时类似于文件描述符的索引机制，所以跨进程很容易。后者存放于内存，是一个内存变量，所以依托于内存。

## 10.13 信号量限制
Posix定义两个常量限制

- SEM_NSEMS_MAX 一个进程可同时打开的最大信号量数(要求至少256)
- SEM_VALUE_MAX 一个信号量的最大值(Posix要求至少32767)

它们通常定义在unistd.h中，可在运行中调用sysconf函数获取:

```c
long nmax=sysconf(_SC_SEM_NSEMS_MAX);
long vmax=sysconf(_SC_SEM_VALUE_MAX);
```

## 10.14 使用FIFO实现信号量(略)
## 10.15 使用内存映射IO实现信号量(略)
## 10.16 使用SystemV信号量实现Posix信号量(略)

## 习题

Tip: 在获取信号量后进程崩溃，不会自动释放信号量，可能造成错误。

Tip: posix1指定了一个可选功能：sem_wait可被信号中断返回EINTR

