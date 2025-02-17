#include <unistd.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>

void SignHandler(int iSignNo);
void testTimerSign();
void printTime();

int main() {
    testTimerSign();
    while(1){
        int left = sleep(5);
        printTime();
        printf("sleep(5)(left=%d)\n", left);
    }
    return 0;
}

void SignHandler(int iSignNo){
    //printTime();
    if(iSignNo == SIGUSR1){
        printf("Capture sign no : SIGUSR1\n");
    }else if(iSignNo == SIGALRM){
        //printf("Capture sign no : SIGALRM\n");
    }else{
        printf("Capture sign no:%d\n",iSignNo);
    }
}

void testTimerSign(){
    struct sigevent evp;
    struct itimerspec ts;
    timer_t timer;
    int ret;
    evp.sigev_value.sival_ptr = &timer;
    evp.sigev_notify = SIGEV_SIGNAL;
    evp.sigev_signo = SIGALRM;
    signal(evp.sigev_signo, SignHandler);
    ret = timer_create(CLOCK_REALTIME, &evp, &timer);
    if(ret) {
        perror("timer_create");
    }

    while(1) {
	ts.it_interval.tv_sec = 0;
	ts.it_interval.tv_nsec = 1;
	ts.it_value.tv_sec = 0;
	ts.it_value.tv_nsec = 1;
	printTime();
	printf("start\n");
	ret = timer_settime(timer, 0, &ts, NULL);
	if(ret) {
		perror("timer_settime");
	}
    }
}

void printTime(){
    struct tm *cursystem;
    time_t tm_t;
    time(&tm_t);
    cursystem = localtime(&tm_t);
    char tszInfo[2048] ;
    sprintf(tszInfo, "%02d:%02d:%02d",
        cursystem->tm_hour,
        cursystem->tm_min,
        cursystem->tm_sec);
        printf("[%s]",tszInfo);
}