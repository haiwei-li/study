#include <stdio.h>
#include <malloc.h>
struct NODE {
    char         data;
    struct NODE *U;//上
    struct NODE *R;//右
    struct NODE *D;//下
    struct NODE *L;//左
} *B,*q;
struct NODE *m[10];
char p[3][4];
int i;
void show_node(struct NODE *s,int y,int x) {
    if (NULL==s) return;
    for (i=0;i<10;i++) {
        if (m[i]==s) return;
    }
    for (i=0;i<10;i++) {
        if (NULL==m[i]) {
            m[i]=s;
            break;
        }
    }
    p[y][x]=s->data;
    show_node(s->U,y-1,x  );
    show_node(s->R,y  ,x+1);
    show_node(s->D,y+1,x  );
    show_node(s->L,y  ,x-1);
}
void show_xlinks(struct NODE *b) {//显示整个十字链表
    int y,x;

    for (i=0;i<10;i++) m[i]=NULL;
    for (y=0;y<3;y++) {
        for (x=0;x<4;x++) {
            p[y][x]=' ';
        }
    }
    show_node(b,1,1);
    for (y=0;y<3;y++) {
        for (x=0;x<4;x++) {
            printf("%c",p[y][x]);
        }
        printf("\n");
    }
    printf("----\n");
}
void swap_xlinks(struct NODE **pa,struct NODE **pb) {
    struct NODE *a,*aU,*aR,*aD,*aL;
    struct NODE *b,*bU,*bR,*bD,*bL;
    struct NODE *t;

    if (pa==pb) return;

    a=*pa;
    aU=a->U;
    aR=a->R;
    aD=a->D;
    aL=a->L;

    b=*pb;
    bU=b->U;
    bR=b->R;
    bD=b->D;
    bL=b->L;

    if (aU && aU!=b) aU->D=b;
    if (aR && aR!=b) aR->L=b;
    if (aD && aD!=b) aD->U=b;
    if (aL && aL!=b) aL->R=b;

    if (bU && bU!=a) bU->D=a;
    if (bR && bR!=a) bR->L=a;
    if (bD && bD!=a) bD->U=a;
    if (bL && bL!=a) bL->R=a;

    t=a->U;a->U=b->U;b->U=t;if (a->U==a) a->U=b;if (b->U==b) b->U=a;
    t=a->R;a->R=b->R;b->R=t;if (a->R==a) a->R=b;if (b->R==b) b->R=a;
    t=a->D;a->D=b->D;b->D=t;if (a->D==a) a->D=b;if (b->D==b) b->D=a;
    t=a->L;a->L=b->L;b->L=t;if (a->L==a) a->L=b;if (b->L==b) b->L=a;

    if (a==*pa) *pa=b;
    if (b==*pb) *pb=a;
}
void free_xlinks() {
    for (i=0;i<10;i++) if (NULL!=m[i]) free(m[i]);
}
int main() {
    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='1';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q记录为起始节点B//
    B=q;                //   1
                        //
    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='2';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的上边    //   2
    B->U=q;             //   1
    q->D=B;             //

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='3';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的右边    //   2
    B->R=q;             //   13
    q->L=B;             //

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='4';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的下边    //   2
    B->D=q;             //   13
    q->U=B;             //   4

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='5';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的左边    //   2
    B->L=q;             //  513
    q->R=B;             //   4

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='6';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的左上    //  62
    B->L->U=q;          //  513
    B->U->L=q;          //   4
    q->R=B->U;
    q->D=B->L;

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='7';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的右上    //  627
    B->R->U=q;          //  513
    B->U->R=q;          //   4
    q->L=B->U;
    q->D=B->R;

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='8';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的右下    //  627
    B->R->D=q;          //  513
    B->D->R=q;          //   48
    q->L=B->D;
    q->U=B->R;

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='9';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在B的左下    //  627
    B->L->D=q;          //  513
    B->D->L=q;          //  948
    q->R=B->D;
    q->U=B->L;

    //创建1个节点的十字链表q
    q=(struct NODE *)malloc(sizeof(struct NODE));
    if (NULL==q) return 1;
    q->data='a';
    q->U=NULL;
    q->R=NULL;
    q->D=NULL;
    q->L=NULL;

    //将q放在3的右边    //  627
    B->R->R=q;          //  513a
    q->L=B->R;          //  948

    printf("begin:\n");
    show_xlinks(B);

    printf("swap 1a:\n");
    swap_xlinks(&B,&B->R->R);
    show_xlinks(B);

    printf("swap a3:\n");
    swap_xlinks(&B,&B->R);
    show_xlinks(B);

    printf("swap 34:\n");
    swap_xlinks(&B,&B->D);
    show_xlinks(B);

    printf("swap 45:\n");
    swap_xlinks(&B,&B->L);
    show_xlinks(B);

    printf("swap 52:\n");
    swap_xlinks(&B,&B->U);
    show_xlinks(B);

    printf("swap 28:\n");
    swap_xlinks(&B,&B->R->D);
    show_xlinks(B);

    printf("swap 47:\n");
    swap_xlinks(&B->L,&B->R->U);
    show_xlinks(B);

    free_xlinks();

    printf("end.\n");
    return 0;
}
// begin:
// 627
// 513a
// 948
// ----
// swap 1a:
// 627
// 5a31
// 948
// ----
// swap a3:
// 627
// 53a1
// 948
// ----
// swap 34:
// 627
// 54a1
// 938
// ----
// swap 45:
// 627
// 45a1
// 938
// ----
// swap 52:
// 657
// 42a1
// 938
// ----
// swap 28:
// 657
// 48a1
// 932
// ----
// swap 47:
// 654
// 78a1
// 932
// ----
// end.
//
