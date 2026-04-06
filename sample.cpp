#include<bits/stdc++.h>
using namespace std;
/*int main(){
    vector<int> v;
    for(int i=0;i<5;i++){
        int push;
        cin>>push;
        v.push_back(push);
    }
    int mini=v[0];
    int profit=0;
    for(int j=0;j<5;j++){
        int cost=v[j]-mini;
        profit=max(profit,cost);
        mini=min(mini,v[j]);
    }
    cout<<"profit ="<<profit;
    return 0;
}*/
int main(){
    vector<int> input;
    for(int i=0;i<6;i++){
        int push;
        cin>>push;
        input.push_back(push);
    }
    vector<int> output(input.size(),0);
    int pos=0;
    int neg=1;
    for(int i=0;i<6;i++){
        if(input[i]>0){
            output[pos]=input[i];
            pos+=2;
        }
        else{
            output[neg]=input[i];
            neg+=2;
        }
    }
    for(int i=0;i<6;i++){
        cout<<output[i]<<" ";
    }
    return 0;
}
