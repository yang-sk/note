#include "unp.h"
void str_echo(int sockfd);
void sig_chld(int signo);
int main(){
    int listenfd,connfd;
    pid_t childpid;
    socklen_t clilen;
    struct sockaddr_in cliaddr,servaddr;
    void sig_chld(int);

    listenfd=Socket(AF_INET,SOCK_STREAM,0);

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family=AF_INET;
    servaddr.sin_addr.s_addr=htonl(INADDR_ANY);
    servaddr.sin_port=htons(SERV_PORT);

    Bind(listenfd,(SA*)&servaddr,sizeof(servaddr));

    Listen(listenfd,LISTENQ);

    Signal(SIGCHLD,sig_chld);
    for(;;){
        clilen=sizeof(cliaddr);
        if( (connfd=accept(listenfd,(SA*)&cliaddr,&clilen))<0){
            if(errno==EINTR)
                continue;
            else
                error_quit("accpet error");
        }
        if( (childpid=Fork())==0){
            Close(listenfd);
            str_echo(connfd);
            exit(0);
        }
        Close(connfd);
    }
}
void str_echo(int sockfd){
    ssize_t n;
    char buf[MAXLINE];

    again:
    while( (n=read(sockfd,buf,MAXLINE))>0)
        Writen(sockfd,buf,n);
    if(n<0 && errno==EINTR)
        goto again;
    else if(n<0)
        error_quit("str_echo:read error");
}
void sig_chld(int signo){
    pid_t pid;
    int stat;
    wait(&stat);       //------------------------
    printf("child %d over.\n",pid);
    sleep(10);        //----------------------
}