#include<stdio.h>
int main()
{
    int x;
    printf("Enter the positive number =");
    scanf("%d",&x);
    if(x%2==0)
    {
        printf("Even number");
    }
    else{
        printf("odd number");
    }
    return 0;
}