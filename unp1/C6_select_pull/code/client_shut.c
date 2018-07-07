#include"unp.h"
int main(int argc, char** argv){
    int sockfd;
    struct sockaddr_in servaddr;
    if(argc!=2)
        error_quit("usage: tcpcli <IPADDRESS>");

    sockfd=Socket(AF_INET,SOCK_STREAM,0);

    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family=AF_INET;
    servaddr.sin_port=htons(SERV_PORT);
    Inet_pton(AF_INET,argv[1],&servaddr.sin_addr);

    printf("connect ...");
    Connect(sockfd,(SA*)&servaddr,sizeof(servaddr));

    printf("done.\n");
    str_cli(stdin,sockfd);
    exit(0);
}

void str_cli(FILE* fp,int sockfd){
    int maxfdp1,stdineof;
    fd_set rset;
    char buf[MAXLINE];
    int n;

    stdineof=0;
    FD_ZERO(&rset);
    for(;;) {
        if(stdineof==0)
            FD_SET(fileno(fp), &rset);
        FD_SET(sockfd, &rset);
        maxfdp1 = max(fileno(fp), sockfd) + 1;
        Select(maxfdp1, &rset, NULL, NULL, NULL);

        if (FD_ISSET(sockfd, &rset)) {
            if ( (n=Read(sockfd, buf, MAXLINE)) == 0){
                if(stdineof==1)
                    return;
                else
                    error_quit("str_cli: server terminated");
            }
            Write(fileno(stdout), buf,n);
        }
        if (FD_ISSET(fileno(fp), &rset)) {
            if( (n=Read(fileno(fp),buf,MAXLINE))==0 ) {
                stdineof = 1;
                Shutdown(sockfd, SHUT_WR);
                FD_CLR(fileno(fp), &rset);
                continue;
            }
            Writen(sockfd,buf,n);
        }
    }
}
