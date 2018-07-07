#include "unp.h"
void dg_echo(int sockfd,SA* pcliaddr,socklen_t clilen);
int main(int argc,char** argv){
    int listenfd,connfd,udpfd,nready,maxfdp1;
    char mesg[MAXLINE];
    pid_t childpid;
    fd_set rset;
    ssize_t n;
    socklen_t len;
    const int on=1;
    struct sockaddr_in servaddr,cliaddr;
    void sig_chld(int);

    list=Socket(AF_INET,SOCK_DGRAM,0);

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family=AF_INET;
    servaddr.sin_addr.s_addr=htonl(INADDR_ANY);
    servaddr.sin_port=htons(SERV_PORT);

    Bind(sock_fd,(SA*)&servaddr,sizeof(servaddr));
    dg_echo(sock_fd,(SA*)&cliaddr, sizeof(cliaddr));
}
void dg_echo(int sockfd,SA* pcliaddr,socklen_t clilen){
    int n;
    socklen_t len;
    char mesg[MAXLINE];
    for(;;){
        len=clilen;
        n=Recvfrom(sockfd,mesg,MAXLINE,0,pcliaddr,&len);
        Sendto(sockfd,mesg,n,0,pcliaddr,len);
    }
}