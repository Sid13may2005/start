#include<stdio.h>
int main()
{
    int m,n,nst,t;
    printf("Enter number of rows : ");
    scanf("%d",&n);
    t=1;
    nst=n;
    for(int j=1;j<=2*n+1;j++)
    {
        printf("*");
    }
    printf("\n");
    for(int i=1;i<=n;i++)
    {
      
        for(int j=1;j<=nst;j++)
        {
            printf("*");
        }
        for(int k=1;k<=t;k++)
        {
            printf(" ");
        }
        t=t+2;
        for(int l=1;l<=nst;l++)
        {
            printf("*");
        }
        nst--;
        printf("\n");
    }
    return 0;
}
