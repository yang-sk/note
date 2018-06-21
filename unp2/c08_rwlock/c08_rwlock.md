# 第8章 读写锁

## 8.1 概述

互斥锁试图把所有对共享数据的访问都理解为互斥操作。然而多线程(进程)对数据的读操作是可以并发的，读写锁就是为了改善“并发读操作”而产生的。

读写锁对读操作和写操作进行区分。访问规则如下：
- 只要没有线程持有给定的读写锁用于写，则其他线程可以持有该读写锁进行读
- 仅当没有线程持有给定的读写锁用于读或用于写时，才能分配该读写锁用于写

简单来说：
- 只要没有线程写，所有线程都可以读; 
- 如果当前线程希望写，则必须在没有线程读和写的时候进行。

简单来说，读写锁可以并发读，此外所有情况与互斥锁一致。因此对读操作频繁的情况改善较大。

这种模式也称共享-独占上锁。获取锁用于读称共享锁，获取锁用于写称独占锁。

> 原书中注明：本章函数由Unix98定义，不属于posix1标准的一部分。

## 8.2 获取与释放读写锁

读写锁数据类型 `pthread_rwlock_t`

初始化：如果是静态分配的，可用常值`PTHREAD_RWLOCK_INITIALIZER`初始化。

获取锁与释放锁
- pthread_rwlock_rdlock获取一个读出锁， 如果对应的读写锁已由某个写入者持有， 则阻塞。
- pthread_rwlock_wrlock获取一个写入锁，如果对应的读写锁已由另外的读出者或写入者持有，则阻塞。 
- pthread_rwlock_unlock释放一个读写锁。

```c
#include <pthread.h>
int pthread_rwlock_rdlock(pthread_rwlock_t * rwptr); 
int pthread_rwlock_wrlock(pthread_rwlock_t * rwptr); 
int pthread_rwlock_unlock(pthread_rwlock_t * rwptr) ; 
均返回： 若成功则为0, 若出错则为正的EXXX值
```

下面是获取读出或写入锁的非阻塞版本。如果该锁不能马上取得，则返回EBUSY错误。
```c
#include <pthread.h>
int pthread_rwlock_tryrdlock(pthread_rwlock_t *rwptr ); 
int pthread_rwlock_trywrlock(pthread_rwlock_t *rwptr ) ; 
均返问： 若成功则为0, 若出错则为正的EXXX值
```

## 8.3 读写锁属性

我们提到过，可通过给一个静态分配的读写锁赋常值PTHREAD_LRWLOCK_INITIALIZER来初始化它。读写锁变量也可以通过调用pthread_rwlock_init来动态地初始化。当一个线程不再需要某个读写锁时，可以调用pthread_rwlock_destroy摧毁它。

```c
#include <pthread.h>
int pthread_rwlock_init(pthread_rwlock_t *rwptr, const pthread_rwlockattr_t *attr);
int pthread_rwlock_destroy(pthread_rwlock_t *rwptr);
均返回： 若成功则为0, 若出错则为正的Exxx值
```
初始化某个读写锁时， 如果属性指针为空，则使用默认属性。

要赋予它非默认的属性，需使用下面两个函数。
```c
#include <pthread.h>
int pthreac_rwlockattr_init(pthread_rwlockattr_t *attr); 
int pthread_rwlockattr_destroy(pthread_rwlockattr_t *attr); 
均返回： 若成功则为0, 若出错则为止的Exxx值
```
数据类型为pthread_rwlockattr_t的某个对象一旦初始化，就通过调用不同的函数来启用或禁止特定属性。当前定义的唯一属性是PTHREAD_PROCESS_SHARED， 它指定相应的读写锁将在不同进程间共享，而不仅仅是在单个进程内的不同线程间共享。 以下两个函数分别获取和设置这个属性。
```c
#include <pthread.h>
int pthread_rwlockattr_getpshared(const pthread_rwlockattr_t *attr, int *valptr);
int pthread_rwlockattr_setpshared(pthread_rwlockattr_t *attr, int value);
均返回： 若成功则为0, 若出错则为正的EXXX值
```
要点
- 第一个函数在由valptr指向的整数中返回该属性值。
- 第二个函数设置属性为value, 其值或为PTHREAD_PROCESS_PRIVATE， 或为PTHREAD_PROCESS_SHARED。

## 8.4 使用互斥锁和条件变量实现读写锁(略)
## 8.5 线程取消

线程在持有互斥锁的情况下取消，不会自动释放锁。

一个线程可以被同进程内其他线程取消。

```c
#include<pthread.h>
pthread_cancel(pthread_t tid);
返回成功0，出错为正的EXXX值
```
pthread_cancel是向某个线程发出信号。调用成功仅表示信号发送成功。

安装和删除处理函数
```c
#include <pthread.h>
void pthread_cleanup_push(void (*func)(void*), void *arg);
void pthread_cleanup_pop(int execute);
```
如果安装，则处理函数发生于

- 调用线程被pthread_cancel函数取消
- 调用线程自愿终止(pthread_exit或从线程函数返回)

可以在处理函数内释放锁和信号量。

func参数即是处理函数，arg是其参数。

cleanup_pop(卸载)弹出栈顶的处理函数。如果execute不为0，那就在卸载前调用处理函数

原书测试例程中，线程阻塞于pthread_cond_wait时被取消，此时相关的互斥锁不会被释放。

在阻塞于条件变量等待时的线程被取消时，要再次取得与条件变量相关的互斥锁，然后调用线程处理函数(如果安装)，然后终止线程。所以默认情况下线程取消后，互斥锁没有释放。

```c
pthread_cleanup_push(func,&mutex);
pthread_cond_wait(...);
pthread_cleanup_pop(0);
```

清理线程的安装和删除处理函数，括住了条件变量等待函数。即，如果等待函数成功返回，就不需要该处理函数了。处理函数仅仅是为了处理等待函数阻塞时线程取消的情况。

也就是说，清理函数应该括住获取和释放锁的代码。这样在获取锁后线程被取消，可以转入处理函数去解锁；在释放锁后，就卸载处理函数(因为已经释放锁了)。如下所示：

```c
pthread_cleanup_push ...
pthread_xxxx_lock()
...
pthread_xxxx_unlock()
pthread_cleanup_pop ...
```

在处理函数内，对互斥锁进行解锁。互斥锁可用arg参数传入处理函数func。也可以加入别的收尾工作。

pop参数为0，表示不调用处理函数，不为0表示先调用处理函数，再卸载处理函数。

#### 思考：线程取消
线程收到取消信号时，可以设置行为：忽略信号、立即终止、延时终止(默认)。最后一项会使得线程执行至下一个取消点（cancelation-point）时终止线程。

根据POSIX标准，pthread_join()、pthread_testcancel()、pthread_cond_wait()、pthread_cond_timedwait()、sem_wait()、sigwait()等函数以及read()、write()等会引起阻塞的系统调用都是cancelation-point，而其他pthread函数都不会引起cancelation动作。

但是pthread_cancel的手册页声称，由于LinuxThread库与C库结合得不好，因而目前C库函数都不是cancelation-point；但CANCEL信号会使线程从阻塞的系统调用中退出，并置EINTR错误码，因此可以在需要作为cancelation-point的系统调用前后调用pthread_testcancel()设置取消点，从而达到POSIX标准所要求的目标.

测试：sleep是取消点，printf不是取消点。

注意：线程取消时可能依然发生更新数据到一半时被中断，产生坏数据，所以尽力避免cancel函数的使用。可以用全局变量记录终止条件，线程中手动检查该条件并自行终止。

具体参考 yang-sk/note/unix/pthread/ 目录中关于pthread_cancel的内容。