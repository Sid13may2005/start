class Solution {
  public:
    int smallestSubstring(string s) {
        // code here
        int min_len=INT_MAX;
        int last0=-1;
        int last1=-1;
        int last2=-1;
        for(int i=0;i<s.size();i++){
            if(s[i]=='0'){
                last0=i;
            }
            else if(s[i]=='1'){
                last1=i;
            }
            else if(s[i]=='2'){
                last2=i;
            }
            
            if(last0!=-1 && last1!=-1 && last2!=-1){
                int start=min({last0,last1,last2});
                int end=max({last0,last1,last2});
                min_len=min(min_len,end-start+1);
            }
        }
        return (min_len==INT_MAX)?-1:min_len;
    }
};
