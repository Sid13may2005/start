#include<bits/stdc++.h>
using namespace std;
/*void updateref(int *x, int *y){
    int sum= *x + *y;
    int diff= *x - *y;
    *x=sum;
    *y=diff;
}
int main(){
    int a,b;
    int *pa=&a, *pb=&b; 
    cout<<"Enter two numbers:";
    cin>>a>>b;
    cout<<"Before update: "<<endl;
    cout<<"a: "<<a<<endl;
    cout<<"b: "<<b<<endl;
    update(pa,pb);
    cout<<"Sum: "<<a<<endl;
    cout<<"Difference: "<<b<<endl;
    return 0;
}*/
void update(int a, int b){
     a=a+b;
     b=a-b;
     a=a-b;
}
int main(){
    int a,b;
    cout<<"Enter two numbers:";
    cin>>a>>b;
    cout<<"Before update: "<<endl;
    cout<<"a: "<<a<<endl;
    cout<<"b: "<<b<<endl;
    update(a,b);
    cout<<"a: "<<a<<endl;
    cout<<"b: "<<b<<endl;
    return 0;
}