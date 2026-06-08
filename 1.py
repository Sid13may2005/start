python_list=[1,2,3,4,5]
print(python_list)

import numpy as np
#import numpy as np
#nump=np.array([1,2,3,4])
numpy_array=np.array([1,2,3,4,5])
print(numpy_array) 
ones_array=np.ones([2,3]) #name=np.ones([2,3])
print(ones_array)
arr=np.arange(1,10,2)#name3=np.arrange(1,10,2)
print(arr)

identity_matrix=np.eye(3) #identity=np.eye(3)
print(identity_matrix)

sie=np.array([[1,2,3],[3,4,5],[6,7,8]])
print(sie.size) #name.size
print(sie.ndim)
print(sie.dtype)

con=np.array([1.1,3,4.2])
ass=con.astype(int)
print(ass)
print(np.sum(arr))
print(np.mean(arr))
print(np.min(arr))
print(np.max(arr))
print(np.std(arr))
print(np.var(arr))

#fancy indexing
fancy=np.array([2,3,5,6,7,23,57,11,76,33,6,0])
print(fancy[[1,4,5]])
#2,3,4
#boolean indexing
print(fancy[fancy>23])
#reshaping
reshaped=fancy.reshape(3,4)
print(reshaped) #it doesnt create a copy it returns view
print(fancy)

#for changing 2D or multidimensional array too 1D we use flattering and ravel function
multi=np.array([[1,2,4],[6,7,9]])
#print(multi.ravel())#view
#print(multi.flatten())#copy

new_arr=np.insert(multi,1,[3,5,8],axis=0)
print(new_arr)
conc=np.concatenate([new_arr,multi])
print(conc)
conc=np.delete(conc,0,axis=1)
print(conc)

arr1=np.array([4,2,3,1,3])
arr2=np.array([5,6,9,5,2])
print(np.vstack((arr1,arr2)))
print(np.hstack((arr1,arr2)))

spi=np.array([10,8,9,4,2,7,1,34])
print(np.split(spi,2))  #split size does not match value erro


#Brodcasting
prices=np.array([100,200,300])
discount=10
final_prices=prices-(prices * discount/100)
print(final_prices)


final_prices=final_prices*2
print(final_prices)


#brodccasting 1d array to 2d array
mat=np.array([[1,2,3],[4,8,9]])  #2X3 mstrix
vector=np.array([10,20,30])      #1D array

result= mat + vector
print(result)


vec=np.array([1,4])
#result=mat+vec
print(result)  #There will be error since dimension did not match 3!=2

#brodcasting is expanding smaller array to larger  

#vectoriztion is converting iD array to be used in 2d array


#is NAN
No=np.array([[[1,3,41],[2,np.nan,45],[7,8,9]]])
print(np.isnan(No))  #true matlab presnt hai vacancy

#ky hm npisnan value ko compare kar sakte hai answer is no

#replace np.nan values
No=np.nan_to_num(No,nan=13)
print(No)


inf=np.array([[[1,-np.inf,41],[2,np.inf,45],[np.inf,8,9]]])
print(np.isinf(inf))
cleaned=np.nan_to_num(inf,posinf=13,neginf=-26)
print(cleaned)

