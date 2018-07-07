#include<stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

int main(int argc,char** argv){
    int fd;
    size_t i,j,col,row;
    char str[100];

    if(argc!=3){
        printf("need cols rows\n");
        exit(-2);
    }

    col=atoi(argv[1]);
    row=atoi(argv[2]);

    if( (fd=open("data.txt",O_WRONLY)) == -1 ){
        printf("Err open file: %s\n",strerror(errno));
        exit(-1);
    }

    for(i=0;i<row;i++) {
        printf(" ---%d--- ",i);
        for (j = 0; j < col; j++) {
            snprintf(str, sizeof(str) - 1, "%d-%d\t", i, j);
            write(fd, str, strlen(str));
        }
        write(fd, "\n", 1);
    }
    close(fd);
}