#include "unp.h" // for MAXLINE
void dg_cli(FILE* fp,int sockfd,const SA* pservaddr,socklen_t servlen);
int main(int argc, char** argv){
    int sockfd;                 //套接字
    struct sockaddr_in servaddr;//服务器地址

    if(argc!=2)
        error_quit("need <IPaddress>");


    bzero(&servaddr,sizeof(servaddr));
    servaddr.sin_family=AF_INET;
    servaddr.sin_port=htons(SERV_PORT);
    Inet_pton(AF_INET,argv[1],&servaddr.sin_addr);

    sockfd=Socket(AF_INET,SOCK_DGRAM,0);

    dg_cli(stdin,sockfd,(SA*)&servaddr,sizeof(servaddr));

    exit(0);
}

void dg_cli(FILE* fp,int sockfd,const SA* pservaddr,socklen_t servlen){
    int n;
    char sendline[MAXLINE],recvline[MAXLINE+1];
    socklen_t len;
    struct sockaddr_inet reply_addr;
    char ip_str[INET_ADDRSTRLEN];

    preply_addr=Malloc(servlen);
    while(Fgets(sendline,MAXLINE,fp)!=NULL){
        Sendto(sockfd,sendline,strlen(sendline),0,pservaddr,servlen);
        len=servlen;

        n=Recvfrom(sockfd,recvline,MAXLINE,0,preply_addr,&len);
        if(len!=servlen || memcmp(pservaddr,preply_addr,len)!=0 ){
            Inet_ntop(AF_INET,&(preply_addr.sa))................
            printf("reply from %s (ignored)\n",)....
            continue;
        }

        recvline[n]=0;
        Fputs(recvline,stdout);
    }
}