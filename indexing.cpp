class Solution {
public:
    char processStr(string s, long long k) {
        long long current_len=0;
        vector<long long> lengths;//storing elements size in each operation;
        lengths.reserve(s.size());
        //length calculation of the result string 
        for(char ch : s){
            if(ch == '#'){
                current_len = current_len*2;
            }
            else if(ch == '*'){
                if(current_len>0) current_len--;
            }
            else if(ch == '%'){

            }
            else{
                current_len++;
            }
            //checking the boundary condition
            if (current_len > 2e18) current_len = 2e18;
            lengths.push_back(current_len);
        }
        //bound
        if (k >= current_len || k < 0) return '.';
        //staring from back
        for(int i=s.size()-1 ; i >= 0 ; --i){
            char ch = s[i];
            long long prev_len = (i==0) ? 0 : lengths[i-1];
            //updating the position of the result element to be found by k
            if( ch == '#'){
                //dublicate hua means index 0 wala element 2 pe gya thus divide by the prev length or size of result string
                if( prev_len > 0){
                    k %= prev_len;
                }
            }
            // updating k since reverse
            else if( ch == '%'){
                if( prev_len > 0){
                    k = prev_len-1-k;
                }
            }
            else if( ch == '*'){

            }
            else{
                if(k == prev_len){
                    return ch;
                }
            }
        }
        return '.';


    }
};
