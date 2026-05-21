#include<stdio.h>
int main()
{
    float n,j,b;
    printf("Enter the value :");
    scanf("%f",&n);
    b=100;
    for(j=1;j<=n;j++)
    {
        printf("%f ",b);
        b=b/2;
    }
    return 0;
}
