#include<stdio.h>
int main()
{
    int n;
    printf("Enter the number");
    scanf("%d",&n);
    if(n>99 && n<999)
    {
        printf("three digit number");
    }
    else
    {
        printf("not a three digit number");
    }
    return 0;
}