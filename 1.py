python_list=[1,2,3,4,5]
print(python_list)

import numpy as np
numpy_array=np.array([1,2,3,4,5])
print(numpy_array) 
ones_array=np.ones([2,3])
print(ones_array)
arr=np.arange(1,10,2)
print(arr)

identity_matrix=np.eye(3)
print(identity_matrix)

sie=np.array([[1,2,3],[3,4,5],[6,7,8]])
print(sie.size)
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

new_arr=np.insert(multi,1,[3,5,8],axis=1)
print(new_arr)