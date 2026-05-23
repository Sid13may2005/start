#include<stdio.h>
int main()
{
    int n;
    printf("Enter the number of rows :");
    scanf("%d",&n);
    int a=1;
   /*for(int i=1;i<=n;i++)
   {   
    int a=65;
    for(int j=1;j<=n;j++)
    {
        printf("%c ",a);
        a++;
    }
    printf("\n");
   }*/
  for(int i=1;i<=n;i++)
  {
    int a=1;
    for(int j=1;j<=n;j++)
    {
        int d=64+a;//d=65
        char ch=(char)d;//ch=(char)65='A'
        printf("%c ",ch);
        a++;
    }
    printf("\n");
  }
   return 0;
}