#include<stdio.h>
int main()
{
    int n,r,reverse,k,sum;
    reverse=0;
    r=0; 
    printf("Enter the number :");
    scanf("%d",&n);
    k=n;
    while(n!=0)
    {
        r=n%10;
        reverse=reverse*10+r;
        n=n/10;
    }
    printf("Reverse of the number is :%d",reverse);
    sum=(k+reverse);
    printf("Sum of the number and its reverse is :%d",sum);
    return 0;
}