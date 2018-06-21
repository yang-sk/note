# 第7章 互斥锁和条件变量

## 7.1 概述

互斥锁和条件变量出自posix1线程标准，用于实现线程间同步。如果存放在共享内存，还可以用于进程同步。

本章主要以线程的情况进行表述，基本也适用于进程。

## 7.2 互斥锁：上锁与解锁

互斥锁用于保护临界区，以保证任何时刻只有一个线程(或进程)执行其中的代码。

保护一个临界区的通常形式：
```fakec
lock_the_mutex(mutex);
临界区
unlock_the_mutex(mutex);
```

任何时刻只能有一个线程能够锁住一个给定的互斥锁。从而保证任何时刻只有一个线程进入被该互斥锁保护的临界区。

互斥锁变量类型：`pthread_mutex_t`

互斥锁变量的初始化：
- 如果是静态分配的，可以初始化为常值 `PTHREAD_MUTEX_INITIALIZER`
- 如果是动态分配的(例如通过调用malloc)或者分配在共享内存中，那么必须调用`pthread_mutex_init`函数进行初始化

上锁和解锁：
```c
#include<pthread.h>
int pthread_mutex_lock(pthread_mutex_t *mptr);
int pthread_mutex_trylock(pthread_mutex_t *mptr);
int pthread_mutex_unlock(pthread_mutex_t *mptr);
均返回：成功0，出错为正的EXXX值
```
如果尝试给一个已被其他线程锁住的互斥量上锁，则pthread_mutex_lock将阻塞到该互斥锁被解锁为止。

pthread_mutex_trylock是对应的非阻塞版本，如果该互斥锁已锁住，则返回EBUSY错误。

思考：互斥锁和第8章的读写锁，在一个线程中可以重复上锁，不会造成阻塞。影响上锁的是其他线程。

> 关于解锁优先级：如果多个线程等待同一个互斥锁，那么解锁后会优先启用哪个线程？不同线程可以授予不同优先级，同步函数(互斥锁/读写锁/信号量)将唤醒优先级高的线程。

互斥锁直接的保护对象是临界区，间接来说是在临界区中被访问的共享数据。

互斥锁是协作性锁，它的使用建立在各线程自发协作的基础上。
- 共享某数据的所有线程应该使用同一个互斥锁。
- 无法防止某线程无视互斥锁并直接访问共享数据的情况。

## 7.3 生产者-消费者问题

生产者-消费者问题，也称有界缓冲问题。一个或多个生产者创建数据条目，这些条目被一个或多个消费者处理。

隐式同步与显式同步

- 对于某些需要传输数据的IPC(如管道)，内核隐式(implicit)进行同步，通过控制生产者的write和消费者的read。当生产者超前消费者(管道被填满)，则生产者write阻塞，直至管道有空余空间。如果消费者超前生产者(管道为空)，则消费者read阻塞，直至管道有可用数据为止。消息队列的同步同样也是隐式的。
- 当共享内存区作为IPC时，必须执行某种显式(explicit)同步。上述的共享内存既包括线程间共享的进程内存(中的全局变量)，也包括进程间的共享内存。一个进程的所有线程总是共享该进程的内存空间，一般共享内存指的是进程间共享内存。

问题类型：多个生产者和一个消费者

- 共享数据：buff有界数组
- 生产者：将递增的数值填入buff
- 消费者：取出数组元素数值进行验证

#### 例子: 多生产者间的同步

所有生产者结束后才启动消费者。此时问题集中于生产者间的同步。

共享数据与互斥锁可以封装结构体，以强调关联性。

设置并发级别：set_concurrency告诉系统期望并发的线程数(除主线程外)。某些实现中，如果忽略该调用，只会产生一个线程;某些实现中该函数不做任何事，因为默认各个线程竞争使用处理器。

思考：这个函数更像一种建议，因为创建线程有专门的函数。另外，ubuntu16.04测试发现未定义该函数。

#### 主函数

```c
#define MAXTHREADS 100
#define MAXITEMS 1000
int nitems = 1000; /* 共需要处理多少条目，只读 */
struct {
    pthread_mutex_t mutex;
    int buff[MAXNITEMS];
    int nput;   /* 下一次访问的位置 */
    int nval;   /*  下一次填充的值 */
} shared = {
   PTHREAD_MUTEX_INITIALIZER  /* 初始化锁 */
};

void *produce(void *), *consume(void *);
int main(int argc, char **argv) {
    int i, nthreads, count[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS], tid_consume;
    nthreads = 20;
    Set_concurrency(nthreads);
    /* start all the producer threads */
    for (i = 0; i < nthreads; i++) {
        count[i]=0;
        Pthread_create(&tid_produce[i], NULL, produce, &count[i]);
    }
    /* wait for all the producer threads */
    for (i = 0; i < nthreads; i++)(
        Pthread_join(tid_produce[i], NULL);
        printf("count[%d] = %d\n", i, count[i]);
    }
    Pthread_create(&tid_consome, NULL, consume, NULL);
    Pthread_join(tid_consume, NULL);
    exit(0);
} // code 7-2
```
要点
- nitems作为只读数据在生产和消费线程共享，故定义为全局变量且不需访问保护
- 创建生产者线程，每个线程执行produce，在tid_produce数组中保存每个线程ID
- count数组统计每个生产者的工作量，并把数组元素地址(以指针类型)传递给每个生产者线程
- 等待生产者线程结束，然后启动消费者线程

#### 生产函数

```c
void * produce(void *arg){
    for(;;){
        Pthread_mutex_lock(&shared.mutex);
        if (shared.nput >= nitems) {
            Pthread_mutex_unlock(&shared.mutex);	// unlock before exit
            return(NULL);      /* array is full, work done */
        }
        shared.buff[shared.nput]=shared.nval;
        shared,nput++;
        shared.nval++;
        Pthrcad_mutex_unlock(&shared.mutex);
        *((int*) arg) += 1;
    }
}  // code 7-3(1)
```
要点
- 结束条件：nput数值已经达到条目数
- 结束时记得解锁
- 临界区原则：尽量减少和共享数据无关的代码

#### 消费函数

本例程中只有一个消费者且在所有生产者结束后启动，故不需要任何同步。

```c
void * consume(void *arg){
    int i;
    for(i = 0; i < nitems; i++) {
        if(shared.buff[i] ! = i)
            printf("buff[%d] = %d \n", i, shared.buff[i]);
    }
    return(NULL);
} // code 7-3(2)
```

## 7.4 对比上锁和等待

互斥锁用于上锁而不能用于等待。

本节中，所有生产者线程启动后立即启动消费者线程(而非在所有生产者结束后)。这样生产者和消费者线程可以并存，但必须同步生产者和消费者，因为只有在生产者完成某条目时，消费者才能处理该条目。

#### 主函数

```c
int main(int argc, char **argv) {
    int i, nthreads, count[MAXNTHREADS];
    pthread_t tid_produce[MAXNTHREADS] , tid_consume;
    nthreads = 20;
    Set_concurrency(nthreads+1);	// one more
    // start all threads 
    for (i = 0; i < nthreads; i++) {
        count[i]=0;
        Pthread_create(&tid_produce[i], NULL, produce, &count[i]);
    }
    Pthread_create(&tid_consome, NULL, consume, NULL);  /* consume */
    
    /* wait for all threads */
    for (i = 0; i < nthreads; i++)(
        Pthread_join(tid_produce[i], NULL);
        printf("count[%d] = %d\n", i, count[i]);
    }
    Pthread_join(tid_consume, NULL);
    exit(0);
} // code 7-4
```
主函数和上节相比，变动有：
- 创建生产者线程之后，立即创建消费者线程
- 额外并发线程数是生产者线程数+消费者线程数

#### produce函数

produce函数没有变化.

#### consume函数

```c
void consume_wait(int i){
    for ( ; ; ) {
        Pthread_mutex_lock(&shared.mutex) ;
        if (i < shared.nput) {
            Pthread_mutex_unlock(&shared.mutex);
            return;         /* an item is ready */
        }
        Pthread_mutex_unlock(&shared.mutex) ;
    }
}

void *consume(void *arg){
    int i;
    for (i = 0; i < nitems; i++) {
        consume_wait(i);
        if (shared.buff[i] != i)
            printf( "buff[%d] = %d\n", i, shared.buff[i]);
    }
    return(NULL);
}  // code 7-5
```
要点
- consume函数唯一变化是取条目前调用consume_wait函数
- consume_wait需要等待生产者产生了第i个条目，因此需要反复比较i和nput值。但是生产者线程也需要访问和更改nput，因此在访问nput时需要加互斥锁以避免与生产者的线程冲突
- 生产者访问nput时加了mutex锁，因此consume_wait加相同的锁即可
- 上述代码中的轮询是对CPU时间的浪费。因此我们需要某种同步，可以等待某个条件发生

## 7.5 条件变量：等待与信号发送

互斥锁用于上锁，条件变量用于等待。两者通常需要配合使用。

条件变量数据类型：`pthread_cond_t`

条件变量的主要操作：等待信号与产生信号
```c
#include <pchread.h>
int pthread_cond_wait(pthread_cond_t *cptr , pthread_mutex_t *mptr);
int pthread_cond_signal(pthread_cond_t *cptr);
均返回：若成功则0，出错则为正的EXXX值
```
要点
- 这里的信号不是Unix的SIGXXX信号
- 每个条件变量总是由一个互斥锁与之关联。pthread_cond_wait函数中指定了相关的互斥锁。

#### 重新定义全局变量和相关函数

```c
/* globals shared by threads */
#define MAXNITEMS 2000
#define MAXNTHREADS 20
nitems=1000;
struct {
    pthread_mutex_t mutex;
    int buff[MAXNITEMS];
    int nput;   /* 下一次访问的位置 */
    int nval;   /*  下一次填充的值 */
} shared= {
   PTHREAD_MUTEX_INITIALIZER  /* 初始化锁 */
};

struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int nready;     /* number ready for consumer */
} nready = {
    PTHREAD_MUTEX_INITIALIZER, PTHREAD_COND_INITIALIZER
};	// code 7-6
```
要点
- nready表示准备好给消费者的条目数

#### main函数

main函数没有变动

#### 生产和消费函数

```c
void *produce(void *arg}{
    for ( ; ; ) {
        Pthread_mutex_lock(&shared.mutex);
        if (shared.nput >= nitems) {
            Pthread_mutex_unlock(&shared.mutex);
            return(NULL);
        }
        shared.buff[shared.nput] = shared.nval;
        shared.nput++;
        shared.nval++;
        Pthread_mutex_unlock(&shared.mutex);

        Pthread_mutex_lock (&nready.mutex);
        if (nready.nready == 0)
            Pthread_cond_signal(&nready.cond);
        nready.nready++;
        Pthread_mutex_unlock(&nready.mutex);
       
        *((int*) arg) += 1;
    }
}
 
void *consume(void *arg){
    int i;
    for (i = 0; i < nitems; i++) {
        Pthread_mutex_lock(&nready.mutex);
        while(nready.nready == 0)
            Pthread_cond_wait(&nready.cond, &nready.mutex);
        nready.nready--;
        Pthread_mutex_unlock(&nready.mutex);
    
        if (buff[i] != i)
            printf("buff[%d] = %d\n", i, buff[i]);
    }
    return(NULL);
}  // code 7-7
```
要点
- 我们希望实现：消费者阻塞等待特定的条件。实现机制为：条件达成时发出信号，消费线程阻塞等待该信号。
- 条件：可用条目数不为零。代码中当nready==0时，下一步的nready++使其为1,此时达成条件

通常来说，跟条件相关的变量(本例中是nready数值)也是共享数据，同样受互斥锁的保护。测试和修改条件时涉及变量操作，需要使用互斥锁进行访问保护。

条件变量、互斥锁、条件相关的变量这三者是相关的，建议放在一个结构体中。

发出的信号唤醒某个等待信号的线程。注意如果没有线程等待某个信号，则信号发出后会丢失

pthread_cond_wait函数原子地执行以下两个动作
1. 给互斥锁nready.mutex解锁
2. 把线程投入睡眠，直至其他线程使用pthread_cond_signal发出对应信号

pthread_cond_wait在返回前重新给互斥锁nready.mutex上锁。因此当它返回并且我们发现计数器nready.nready不为0时，我们将把该计数器减1 (前提是我们肯定已锁住了该互斥锁)，然后给该互斥锁解锁。

计数器减1表示消费掉了一个条目。

注意，当pthread_cond_wait返回时，我们总是再次测试相应条件成立与否，因为可能发生虚假的(spurious)唤醒：期待的条件尚不成立时的唤醒。各种线程实现都试图最大限度减少这些虚假唤醒的数量，但是仍有可能发生。

总地说来，给条件变量发送信号的代码大体如下：
```c
struct {
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	维护本条件的各个变量
} var = { PTHREAD_MUTEX_INITIALI2ER, PTHRFAD_COND_INITIALIZER, … };

pthread_mutex_lock(&var.mutex);
设置条件为真
pthread_cond_signal(&var.cond);
pthread_mutex_unlock(&var.mutex);
```
测试条件并进入睡眠以等待该条件变为真的代码大体如下：
```c
pthread_mutex_lock(&var.mutex);
while (条件为假)
    pthread_cond_wait(&var.cond, &var.mutex);
修改条件
pthread_mutex_unlock(&var.mutex);
```

### 避免上锁冲突
条件变量关联了一个互斥锁。上述代码中，某个线程先锁住互斥锁，然后发出信号，最后解锁。

我们可以设想最坏情况,当该条件变量被发送信号后，还没来得及解锁，系统就立即调度其他等待信号的线程。该线程开始运行，但立即停止，因为它没能获取相应的互斥锁。

为避免这种上锁冲突，可作如下变动: 用某个标志记录是否触发信号，解锁后再根据标志发送信号。

```c
int dosignal;

Pthread_mutex_lock(&nready.mutex);
dosignal = (nready.nready == 0);
nready.nready++;
Pthread_mutex_unlock(&nready.mutex);

if (dosignal)
    Pthread_cond_signal(&nready.cond);
```
在这儿，我们直到释放互斥锁nready.mutex后才给与之关联的条件变量nready.cond发送信号。Posix明确允许这么做：线程调用pthread_cond_signal时，不必持有相关的互斥锁。不过Posix接着说：如果需要可预见的调度行为，那么调用pthread_cond_signal的线程必须锁住该互斥锁。

注意dosigal只在生产线程使用，不是共享数据，因而不必担心同步问题。

## 7.6 条件变量：定时等待和广播

通常pthread_cond_signal只唤醒等待在相应条件变暈上的一个线程。在某些情况下一个线程认定有多个其他线程应被唤醒，这时它可调用pthread_cond_broadcast唤醒阻塞在相应条件变量上的所有线程。

> 例如：有多个线程读取共享数据。读取数据不会冲突，可以唤醒所有读取线程。
> 如果没有特定的优先级，坚持使用广播是较为安全的方式。

```c
#include <pthread.h>
int pthread_cond_broadcast(pthroad_cond_t *cptr) ;
int pthread_cond_timedwait(pthread_cond_t *cptr, pthread_mutex_t *mptr, const struct timespec *abstime);
均返回：若成功则为0, 若出错则为正的Exxx值
```
pthread_cond_timedwait允许线程设置阻塞时限。abstime参数是一个timespec结构：
```c
struct timespec {
    time_t tv_sec;  /* seconds */
    long tv_nsec;   /* nanoseconds */
};
```
该结构指定这个函数限定结束的系统时间，即便那时相应的条件变量还没有收到信号。如果发生这种超时情况，该函数就返回ETIMEDOUT错误。

时间值是绝对时间(absolute time)，而不是时间差。这就是说，abstime是该函数返回时刻的系统时间。这与select、pselect和poll不同。

使用绝对时间而不是时间差的好处是：如果函数过早返回了(也许是因为捕获了某个信号)，那么同一函数无需改变其参数中timespec结构的内容就能再次被调用。

## 7.7 互斥锁和条件变量的属性

本章中的互斥锁和条件变量例子把它们作为一个进程中的全局变量存放，以用于该进程内各线程间的同步。

我们用两个常值PTHREAD_MUTEX_INITIALIZER 和 PTHREAD_COND_INITIALIZER来初始化它们。由这种方式初始化的互斥锁和条件变最具备默认属性，不过我们还能以非默认属性初始化它们。

首先，互斥锁和条件变量是用以下函数初始化或摧毁的。

```c
#include <pthread.h>
int pthread_mutex_init(pthread_mutex_t *mptr, const pthread_mutexattr_t *attr);
int pthread_mutex_destroy(pthread_mutex_t *mptr);
int pthread_cond_init(pthread_cond_t *cptr, const pthread_condattr_t *attr);
int pthread_cond_destroy(pthread_cond_t *cptr);
均返回：若成功则为0, 若出错则为正的EXXXX值
```

考虑互斥锁情况，mptr必须指向一个已分配的pthread_mutex_t变量，并由pthread_mutex_init函数初始化该互斥锁。由该函数第二个参数指向的pthread_mutexattr_t值指定其属性。如果该参数是个空指针，那就使用默认属性。

互斥锁属性的数据类型为pthread_mutexattr_t，条件变量属性的数据类型为pthread_condattr_t，它们由以下函数初始化或摧毁。

```c
#include <pthread.h>
int pthread_mutexattr_init(pthread_mutexattr_t *attr);
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr);
int pthread_condattr_init(pthread_condattr_t *attr);
int pthread_condattr_destroy(pthread_condattr_t *attr);
均返冋：若成功则为0, 若出错则为正的EXXX值
```

一旦某个互斥锁属性对象或某个条件变景属性对象已被初始化，就通过调用不同函数启用或禁止特定的属性。举例来说，我们将在以后各章中使用的一个属性是：指定互斥锁或条件变量在不同进程间共享，而不是只在单个进程内的不同线程间共享。这个属性是用以下函数取得或存入的。

```c
#include <pthread.h>
int pthread_mutexattr_getpshared(const pthread_mutexattr_t *attr , int *valptr ) ;
int pthread_mutexattr_setpshared(pthread_mutexattr_t *attr , int value );
int pthread_condattr_getpshared(const pthread_condattr_t *attr , int *valptr);
int pthread_condattr_setpshared(pthread_condattr_t *attr, int value);
均返回：若成功则为0, 若出错则为正的EXXX值
```

其中两个get函数返回在由valptr指向的整数中的这个属性的当前值，两个set函数则根据value的值设置这个属性的当前值。value可以是PTHREAD_PROCESS_PRIVATE或PTHREAD_PROCESS_SHARED。后者也称为进程间共享属性。

> 这个特性只在头文件unistd.h中定义了常值_POSIX_THREAD_PROCESS_SHARED时才得以支持。 它在Posix.l 中是可选特性，在Unix 98中却是必需的.

以下代码片段给出初始化一个互斥锁以便它能在进程间共享的过程:
```c
    pthread_mutex_t *mptr;      /* pointer to the mutex in shared memory */
    pthread_mutexattr_t mattr;
    ...
    mptr = /* some value that points to shared memory */ 
    pthread_mutexattr_init(&mattr);
#ifdef _POSIX_THREAD_PROCESS_SHARED
    pthread_mutexattr_setpshared(&mattr, PTHREAD_PROCESS_SHARED);
#else
# error: this implementation does not support
#endif
    pthread_mutex_init(mptr,&mattr);
```

我们声明一个名为mattr的pthread_mutexattr_t数据类型的变量，把它初始化成互斥锁的默认属性，然后给它设罝PTHREAD_PROCESS_SHARED属性，意思是该互斥锁将在进程间共享。

pthread_mutex_init然后照此初始化该互斥锁。必须分配给该互斥锁的共亨内存区空间大小为sizeof(pthread_mutex_t)。

用于给存放在共享内存中供多个进程使用的一个条件变量设置PTHREAD_PROCESS_SHARED属性的一组语句跟用于互斥锁的语句几乎相同，只需把其中的5处mutex替换成cond即可。

### 持有锁期间进程终止
当在进程间共享一个互斥锁时，持有该互斥锁的进程在持有期间终止(也许是非自愿地)的可能总是有的。没有办法让系统在进程终止时自动释放所持有的锁。读写锁和Posix信号量也具备这种属性。进程终止时内核总是自动清理的唯一同步锁类型是fcntl记录锁。使用SystemV信号量时，应用程序可以选择进程终止时内核是否自动清理某个信号量锁(将在11.3节中讨论的SEM_UNDQ特性)。

一个线程也可以在持有某个互斥锁期间终止，起因是被另一个线程取消或自己去调用了pthread_exit。后者没什么可关注的，因为如果该线程调用pthread_exit自愿终止的话，它应该知道自己还持有一个互斥锁。如果是被另一个线程取消的情况，那么该线程可以安装在被取消时调用的清理处理程序。

对于一个线程致命的条件通常还导致整个进程的终止。例如，某个线程执行了无效指针访问，从而引发了SIGSEGV信号，那么一旦该信号未被捕获，整个进程就被它终止，我们于是回到了上文处理进程终止的情况。

即使一个进程终止时系统会自动释放某个锁，那也可能解决不了问题。该锁保护某个临界区很可能是为了在执行该临界区代码期间更新某个数据。如果该进程在执行该临界区的中途终止，该数据处于什么状态呢？该数据处于不一致状态的可能性很大：举例来说，一个新条目也许只是部分插入某个链表中，要是该进程终止时内核仅仅把那个锁解开的话， 使用该链表的下一个进程就可能发现它已损坏。

然而在某些例子中，让内核在进程终止时清理某个锁(若是信号量情况则为计数器)不成问题。例如，某个服务器可能使用一个SystemV信号量(打开其SEM_UNDO特性)来统计当前被处理的客户数。每次fork一个子进程时，它就把该信号量加1,当该子进程终止时，它把该信号量减1。如果该子进程非正常终止，内核仍会把该计数器减1。

9.7节给出了一个例子，说明内核在什么时候释放一个锁(不是我们刚讲的计数器)合适。那儿的守护进程一开始就在自己的某个数据文件上获得一个写入锁，然后在其运行期间一直持有该锁。如果有人试图启动该守护进程的另一个副本，那么新的副本将因为无法取得该写入锁而终止，从而确保该守护进程只有一个副本在一直运行。但是如果该守护进程不正常地终止了，那么内核会释放该写入锁，从而允许启动该守护进程的另一个副本。

重点：
- 线程结束时可以安装清理函数自动释放锁或信号量，进程结束时无法自动释放(除了记录锁)
- 进程的意外性结束可能导致临界区某些数据更新操作中断，导致难以预知的后果。此时即使可以自动释放锁也无济于事

## 习题
问：如果只调用pthread_mutexattr_init和pthread_condattr_init，而不调用相应的destroy函数，是否会内存泄漏？

答：不同的实现情况不同，某些实现下是动态分配的。注意原书提到初始化时，互斥量指针必须指向已分配的变量，也就是说，函数只管初始化不管分配。但未详细说明条件变量的情况。但是书中说道destroy仍是需要的。