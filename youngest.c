#include<stdio.h>
int main()
{
    int ram,shyam,ajay;
    printf("enter the age of ram :");
    scanf("%d",&ram);
        printf("enter the age of shyam :");
    scanf("%d",&shyam);
        printf("enter the age of ajay :");
    scanf("%d",&ajay);
    if(ram<shyam)
    {
        if(ram<ajay)
        {
            printf("ram is youngest");//ram shyam se chota hai aur ram ajay se bhi chota ho gya then ram is the youngest
        }
        else
        {
            printf("ajay is the youngest");//ram shyam se chota hai aur ajay chota hai ram se then ajay is the youngest
        }
    }
        else
        {
            if(ajay<shyam)
            {
                printf("ajay is the youngest");
            }
            else
            {
                printf("shyam is the youngest");
            }
        }
        return 0;
    }

