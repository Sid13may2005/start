#include<stdio.h>
#include<stdlib.h>
void insert_record();
void display_record();
void search_record();
void del_record();
void update_record();
void sort_record();

struct student
{
    int slno;
    int roll;
    char name[40];
    char gen[10];
    char cat[10];
    char dob[10];
    float cgpa;
};
 struct student s;

 int main()
 {
        int ch;
        system("cls");

        while(ch!=7)
        {
            system("cls");
            printf("\t*************************************************************************************\n");
            printf("\t\tWELCOME TO STUDENT MANAGEMENT SYSTEM \n");
            printf("\t*************************************************************************************\n");
            printf("\n\n");

                printf("\t**** AVAILABLE FUNCTIONALITIES ****\n\n");
                printf("\t\t1: Insert Student record\n");
                printf("\t\t2: Display Student record\n");
                printf("\t\t3: Search Student record\n");
                printf("\t\t4: Delete Student record\n");
                printf("\t\t5: Update Student record\n");
                printf("\t\t6: Sort Student record\n");
                printf("\t\t7: Exit\n\n");
                printf("\t\tEnter your choice : ");
                scanf("%d",&ch);
                switch(ch)
                {
                    case 1:
                        {
                            system("cls");
                            insert_record();
                            break;
                        }
                    case 2:
                        {
                            system("cls");
                            display_record();
                            break;
                        }
                    case 3:
                        {
                            system("cls");
                            search_record();
                            break;
                        }
                    case 4:
                        {
                            system("cls");
                            del_record();
                            break;
                        }
                    case 5:
                        {
                            system("cls");
                            update_record();
                            break;
                        }
                    case 6:
                        {
                            system("cls");
                            sort_record();
                            break;
                        }
                    case 7:
                    {
                        printf("Thank you !!!");
                        exit(1);
                    }
                    default:
                        printf("\n\t\tWrong Choice Entered");
                }
                printf("\n\t\tPress any Key to continue");
                getch();

        }
        return 0;

 }

void insert_record()
{
    FILE *fptr;
    fptr=fopen("stu.txt","ab+");

    if(fptr==NULL)
    {
        printf("\n\t\tError: Cannot Open the File!!!");     
        return;
    }
    printf("\t\t*******Previous Stored Data******\n\n");
    display_record();

    printf("\n\n\t*****Enter Student Data*****\n\n");
    s.slno +=1;
    printf("\n\tEnter Student Roll Number : ");
    scanf("%d",&s.roll);
    fflush(stdin);
    printf("\n\tEnter Student Name : ");
    gets(s.name);
    fflush(stdin);
    printf("\n\tEnter Student Gender : ");
    gets(s.gen);
    fflush(stdin);
    printf("\n\tEnter Student Category : ");
    gets(s.cat);
    fflush(stdin);
    printf("\n\tEnter Student Date of Birth : ");
    scanf("%s",&s.dob);
    fflush(stdin);
    printf("\n\tEnter Student cgpa: ");
    scanf("%f",&s.cgpa);
    fwrite(&s,sizeof(s),1,fptr);
    {
        printf("\n\n\t !!! Student Record Inserted Successfully\n");
    }
    fclose(fptr);
    printf("\n\t\t Updated Record !!\n");
    display_record();

}

void display_record()
{
    FILE *fptr;
    fptr =fopen("stu.txt","rb");
    if(fptr==NULL)
    {
        printf("\n\t\tError : Cannot open the File !!!");
        return;
    }
    printf("\n\t\t***** Students Details Are As Follows *****\n");
    s.slno=0;
    printf("\n  Sl. No.\tRoll Number\tName  of  Student\t\t\tGender\t\tCategory\tD . O . B.\tcgpa\n");
    while(fread(&s,sizeof(s),1,fptr)==1)
    {
        printf("\n  %d\t\t%d\t\t%s\t\t\t%s\t\t%s\t\t%s\t%f\n",s.slno,s.roll,s.name,s.gen,s.cat,s.dob,s.cgpa);
    }
    fclose(fptr);
}

void search_record()
{
    int ro,flag=0;
    FILE *fptr;
    fptr=fopen("stu.txt","r");
    if(fptr==NULL)
    {
        printf("\n\t\tError : Cannot open the file");
        return;
    }
    printf("\n\t\tEnter the Student Roll Number You Want To Search : ");
    scanf("%d",&ro);
    while(fread(&s,sizeof(s),1,fptr)>0 && flag==0)
    {
        if(s.roll==ro)
        {
            flag=1;
            printf("\n\t\tSearch Successful and the Student record is as follows ");
            printf("\n  Sl. No.\tRoll Number\tName  of  Student\t\t\tGender\t\tCategory\tD . O . B.\tcgpa\n");
            printf("\n  %d\t\t%d\t\t%s\t\t\t%s\t\t%s\t\t%s\t%f\n",s.slno,s.roll,s.name,s.gen,s.cat,s.dob,s.cgpa);
        }   
    }
    if(flag==0)
        {
            printf("\n\t\tNo as such record found !!!\n");
        }
    fclose(fptr);
}

void del_record()
{
    //char name[40];
    int ro;
    unsigned flag=0;
    FILE *fptr,*ft;
    fptr=fopen("stu.txt","rb");
    if (fptr==NULL)
    {
       printf("\n\t\tError : Cannot open the the file !!!");
       return;
    }
    printf("\n\t\t****** Previous stored Data ******");
    display_record();
    //printf("\n\t\tEnter the Student Name you Want to Delete : ");
    //scanf("%s",&name);
    printf("\n\t\tEnter the Student Roll Number you Want to Delete : ");
    scanf("%d",&ro);
    ft = fopen("stu1.txt","a+");
    while(fread(&s,sizeof(s),1,fptr)==1)
    {
        
        if(ro == s.roll)
        {
            
            printf("\n\t\tRecord Deleted Successfully \n");
            //fwrite(&s,sizeof(s),1,ft);
        }
        else
        {
            flag=1;
            fwrite(&s,sizeof(s),1,ft);
        }
    }
    if(flag ==0)
    {
        printf("\n\t\tNo Such Record Found !!!");
    }
    fclose(fptr);
    fclose(ft);
    remove("stu.txt");
    rename("stu1.txt","stu.txt");
    printf("\n\t\t Updated Record !!!\n");
    display_record(); 
}

void update_record()
{
    int ro,flag=0;
    FILE *fptr;
    fptr=fopen("stu.txt","rb+");
    if(fptr==NULL)
    {
        printf("\n\t\tError : Cannot Open the File !!!");
        return;
    }
    printf("\n\t\tEnter the roll  Number of Student Whose Record You Want to Update : ");
    scanf("%d",&ro);
    printf("\n\t\t***** Previously Stored Record of Given Roll Number *****");
    while(fread(&s,sizeof(s),1,fptr)>0 && flag==0)
    {
        if (s.roll==ro)
        {
            flag=1;
            printf("\n  Sl. No.\tRoll Number\t\tName  of  Student  \t\tD . O . B.\t\tGender\t\tCategory\tcgpa\n");
            printf("\n  %d\t%d\t\t%s  \t\t%s\t\t%s\t\t%s\t%d\n",++s.slno,s.roll,s.name,s.dob,s.gen,s.cat,s.cgpa);
            printf("\n\t\t***** Now Enter the New Record*****\n\n");
            s.slno +=1;
            printf("Updated Student Roll Number : ");
            scanf("%d",&s.roll);
            printf("Updated Student Name : ");
            gets(s.name);
            printf("Updated Student Date of Birth : ");
            gets(s.dob);
            printf("Updated Student Gender : ");
            gets(s.gen);
            printf("Updated Student Category : ");
            gets(s.cat);
            printf("Updated Student cgpa : ");
            scanf("%f",&s.cgpa);

            fseek(fptr,-(long)sizeof(s),1);
            fwrite(&s,sizeof(s),1,fptr);
            printf("\n\t\tRecord Updated Successfully Check the Display  Option");
        }
    }
    if(flag==0)
    {
        printf("\n\t\tError : Something Went Wrong !!!");
    }
    fclose(fptr);
}

void sort_record()
{
    struct student temp;
    struct student arr[72];
    
    int i=0,j,k=0;
    FILE *fptr;
    fptr=fopen("stu.txt","rb");
    if(fptr==NULL)
    {
        printf("\n\t\tError : Cannot Open File !!!\n");
    }
    
    while(fread(&arr[i],sizeof(arr[i]),1,fptr)==1)
    {
        i++,k++;
    }

    for(i=0;i<k;i++)
    {
        for(j=0;j<k-i-1;j++)
        {
            if(arr[j].roll>arr[j+1].roll);
            {
                temp=arr[j];
                arr[j]=arr[j+1];
                arr[j+1]=temp;
            }

        }
    }

    printf("\n\t\tAfter Sorting Student Details !!!\n\n");
    for(j=0;j<k;j++)
    {
        arr[j].slno=j+1;
        printf("\n  %d\t%d\t\t%s\t\t\t%s\t\t%s\t\t%s\t%d\n",arr[j].slno,arr[j].roll,arr[j].name,arr[j].dob,arr[j].gen,arr[j].cat,arr[j].cgpa);
    }
    fclose(fptr);
}