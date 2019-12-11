############# Authors and Contact Details #############
#=
Yossi Bokor								Chris Williams
yossi.bokor@anu.edu.au					christopher.williams@anu.edu.au
Mathematical Sciences Institute
Australian National University
=#


############# General functions used in main function 'wasserstein_distance' #############

function pad(u1,u2)

    	#=
    	Given 2 by n1 and 2 by n2 matrices, returns two 2 by (n1+n2) matrices.
    	This is done by adding points to u1 by projecting the points in u2 to
    	the diagonal {(x,y) : x = y }. This is also done to u2.
    	=#

    	#check that columns of matrices match
    	#println(size(u1))
    	@assert size(u1)[2] == size(u2)[2] == 2
    	
    	#need transpose as sometimes a 1D vector
		n1 = size(u1)[1]
		n2 = size(u2)[1]
		# note total n = n1 + n2
			v1 = vcat(u1, zeros(n2,2))
			v2 = vcat(u2, zeros(n1,2))
			#project to diagonal
		for i = 1:n2
				z = (v2[i,1]+v2[i,2])/2
				v1[n1+i,1] = z
				v1[n1+i,2] = z
		end
		################
		for i = 1:n1

			z = (v1[i,1]+v1[i,2])/2

			v2[n2+i,1] = z
			v2[n2+i,2] = z

		end

    	return v1,v2,n1,n2
end

function pad_infinite(u1,u2)

    	#=
    	Given 2 by n1 and 2 by n2 matrices, returns two 2 by (n1+n2) matrices.
    	This is done by adding points to u1 by projecting the points in u2 to
    	the diagonal {(x,y) : x = y }. This is also done to u2.
    	=#

    	#check that columns of matrices match
    	#println(size(u1))
    	@assert size(u1)[2] == size(u2)[2] ==1
	
	
		#need transpose as sometimes a 1D vector
		n1 = size(u1)[1]
		n2 = size(u2)[1]
		# note total n = n1 + n2
			v1 = vcat(u1, zeros(n2,1))
			v2 = vcat(u2, zeros(n1,1))
			#project to diagonal
		for i = 1:n2
				#z = (v2[i,1]+v2[i,2])/2
				v1[n1+i,1] = v2[i,1]
				#v1[n1+i,2] = z
		end
		################
		for i = 1:n1
			#z = (v1[i,1]+v1[i,2])/2
			v2[n2+i,1] = v1[i,1]
			#v2[n2+i,2] = z
		end
		
		

    	return v1,v2,n1,n2
end

function dist_mat(v1,v2,n1,n2; p = 2)

		#=  Accepts two equal size vectors and their original lengths and finite values.Returns the minimal Lp distance of their persistence diagrams.  =#

    #check vectors are of the same length
    @assert size(v1) == size(v2)

    #take the length of columns, note this is always bigger than 2.
    n = size(v1)[1]
    println("in dist_mat n is $n")

    #set up cost matrix
	cost = zeros(n,n)

    #if l1 compute here in faster way.
    if p == 1
        for i = 1:n
			for j in 1:n
				cost[i,j] = abs(v1[i,1]-v2[j,1]) + abs(v1[i,2] - v2[j,2]) 
			end
        end

	elseif p == Inf
		for i = 1:n
			for j in 1:n
				cost[i,j] = maximum(broadcast(abs,v1[i,:]-v2[j,:]))
			end
        end
    else
        for i = 1:n
			for j in 1:n
				cost[i,j] = ((abs(v1[i,1]-v2[j,1])^p)+ abs(v1[i,2]-v2[j,2])^p)^(1/p)
			end
		end

    end

    #set distance between diagonal points to be 0.
    #this could just not be calculated if not using broadcast.
	cost[(n-n2+1):n,(n-n1+1):n] = zeros(n2,n1)
	#print("cost matrix is ", cost,"\n")
	
    return cost

end

function dist_inf(v1,v2)
    #=
    takes in two vectors with all y points at infinity.
    returns the distance between their persitance diagrams.
    =#
    println(size(v1))
    #= c_1_inf = 0
    c_2_inf = 0
    for i in 1:size(v1)[1]
    print(v1)
    println("i is $i")
	println(v1[i,2])
		if v1[i,2] == Inf
			c_1_inf += 1
		end
    end
    
    for i in 1:size(v2)[1]
		if v2[i,2] == Inf
			c_2_inf += 1
		end
	end
	
	@assert c_1_inf == c_2_inf
	=#
	
	#if the point (Inf,Inf) exists return Inf.
	if any(i->(i==Inf), v1[:,1]) || any(i->(i==Inf), v2[:,1])

		return Inf
    else
		n = size(v1)[1]
		
		cost = zeros(n,n)
		for i = 1:n
			for j in 1:n
				cost[i,j] = abs(v1[i]-v2[j])
			end
		end
		println("n is $n cost matrix from dist_inf is", cost)
		return cost, hungarian(cost)[1]
	end
end
############# Main function #############

function wasserstein_distance(dgm1,dgm2; p = 2,q=p)
	
	
	u1 = vcat([0 0], dgm1) # this is to avoid issues with empty diagram parts
	u2 = vcat([0 0], dgm2)
	print(u1, u2)
	#=
	takes two (possibly unequal size) vectors and calculates the W_(q,p)distance between their persistence diagrams. The default is that q=p=2
	Can calculate lp distance between diagrams, l1 should be the fastest.
	Can handle values of Inf in vectors.
	=#
	
	#if no Inf is present in either vector calculate as normal.
	if all(i->(i!=Inf), u1) && all(i->(i!=Inf), u2)
		println("padding", u1, u2)
		v1,v2,n1,n2 = pad(u1,u2)
	
		cost = dist_mat(v1,v2,n1,n2,p=p)
		println("cost matrix is", cost)
		assignment = hungarian(cost)[1]
	
		if q == Inf
			values = [cost[i, assignment[i]] for i in 1:(n1+n2)]
			distance = maximum(values)
			return distance
	
		else
			distance = 0
			for i in 1:length(assignment)
				distance += cost[i, assignment[i]]^(q)
			end
			return distance^(1/q)
	
		end
	
	
	
	
	#if there are equal amounts of infinity calculate possibly finite distance.
	elseif sum(u1[:,2] .== Inf) == sum(u2[:,2] .== Inf)
	
			#get the number of infinities.
			N_inf = sum(u1[:,2] .== Inf)
			#sort vectors by increasing amount in y component.
			u_sort_1 = copy(u1)
			u_sort_2 = copy(u2)
			order_1 = sortperm(u1[:,2], rev = true)
			order_2 = sortperm(u2[:,2], rev = true)
			
			for i in 1:size(u1)[1]
				u_sort_1[i,:] = u1[order_1[i],:]
			end
			for i in 1:size(u2)[1]
				u_sort_2[i,:] = u2[order_2[i],:]
			end
			
			#split into infinity part and finite part
			u_sort_1_2 = u_sort_1[1:N_inf,:]
			u_sort_2_2 = u_sort_2[1:N_inf,:]
			u_sort_1_1 = u_sort_1[(1+N_inf):end,:]
			u_sort_2_1 = u_sort_2[(1+N_inf):end,:]
	
			#calculate infinite cost.
			println("\n now matrices are", u_sort_1_1,u_sort_1_2,u_sort_2_1,u_sort_2_2)
			cost, assignment_inf = dist_inf(u_sort_1_2,u_sort_2_2)
	
			if q == Inf
				costs = [cost[i, assignment_inf[i]] for i in 1:(N_inf)]
				cost_inf = maximum(costs)
			else
				cost_inf = 0
				for i in 1:N_inf
					cost_inf += cost[i, assignment_inf[i]]^(q)
				end
			end
			#calculate finite cost without self-reference.
			println("now matrices are", u_sort_1_2,u_sort_2_2)
			v1,v2,n1,n2 = pad(u_sort_1_1,u_sort_2_1)
			println(v1,v2,n1,n2)
			cost = dist_mat(v1,v2,n1,n2,p=p)
			println("cost matrix is", cost," i think it is here")
			
			assignment = hungarian(cost)[1]
		
			if q == Inf
				values = [cost[i, assignment[i]] for i in 1:(n1+n2)]
				distance = maximum(values)
				cost_h = distance
		
			else
				distance = 0
				for i in 1:length(assignment)
					distance += cost[i, assignment[i]]^(q)
				end
				cost_h =  distance
			end
			
	
			if q == Inf
				return maximum(cost_h, cost_inf)
			else
				return (cost_h + cost_inf)^(1/q)
			end
	
	#unequal infinity return infinity.
	else
			return Inf
	
	end
	
end


############# Tests #############

# 

function wd_test_1()
	val = wasserstein_distance([1 2], [1 2])
	
    if val == 0
	    return []
    else
        print("Error: wd_test_1, value = ")
        return val
    end
end

function wd_test_2()
	val = wasserstein_distance([1 2],[3 4], p=Inf )
	
    if val == 0.5
	    return []
    else
        print("Error: wd_test_2, value = ")
        return val
    end
end

function wd_test_3()
    val = wasserstein_distance([1 2],[3 3.5],p=1,q=Inf )

    if val == 1
	    return []
    else
        print("Error: wd_test_3, value = ")
        return val
    end
end

function wd_test_4()
	val = wasserstein_distance([0 1], [3 5; 7 9], p=Inf, q=1)

	if val == 2.5
		return []
	else print("Error: wd_test_4, value = ")
		return val
	end
end

function wd_test_5()
	val = wasserstein_distance([1 1], [2 2])
	
    if val == 0
	    return []
    else
        print("Error: wd_test_5, value = ")
        return val
    end
end
