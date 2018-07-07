#include "unp.h"

#include <linux/sctp.h> //***%%%%%%%%%55 %%%%%%%%%%%%%%%

int main(int argc,char** argv){
    int sock_fd,msg_flags;
    char readbuf[MAXLINE];
    struct sockaddr_in  servaddr,cliaddr;
    struct sctp_sndrcvinfo sri;
    struct sctp_event_subscribe evnts;

    int stream_increment=1;
    socklen_t len;
    size_t rd_sz;

    if(argc==2)
        stream_increment=atoi(argv[1]);

    sock_fd=Socket(AF_INET,SOCK_SEQPACKET,IPPROTO_SCTP);

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family=AF_INET;
    servaddr.sin_addr.s_addr=htonl(INADDR_ANY);
    servaddr.sin_port=htons(13);

    Bind(sock_fd,(SA*)&servaddr,sizeof(servaddr));

    bzero(&evnts,sizeof(evnts));
    evnts.sctp_data_io_event=1;
    Setsockopt()
    Listen(sock_fd,LISTENQ); //LISTENQ常值，预先在"unp.h"定义
//
//    for(;;){
//        connfd=Accept(listenfd,NULL,NULL); //投入睡眠直到被可用的客户接入唤醒
//
//        ticks=time(NULL);
//        snprintf(buff,sizeof(buff),"%.24s\r\n",ctime(&ticks));
//        Write(connfd,buff,strlen(buff));
//
//        Close(connfd);
//    }
}