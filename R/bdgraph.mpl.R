## ----------------------------------------------------------------------------|
# For discrete data: to transfer raw data for the algorithm 
## ----------------------------------------------------------------------------|
data_transform = function( raw_data )
{
	all_patterns    = apply( raw_data, 1, function( x ){ paste( x, collapse = '' ) } )   
	unique_patterns = unique( all_patterns )
	   
	length_unique_patterns = length( unique_patterns )
	data  = matrix( 0, nrow = length_unique_patterns, ncol = ncol( raw_data ) + 1 )
	   
	for( i in seq_len( length_unique_patterns ) )
	{
		which_one = which( all_patterns == unique_patterns[i] )
		data[i, ] = c( raw_data[ which_one[1], ], length( which_one ) )
	}
	 
	return( data )
}
   
## ----------------------------------------------------------------------------|
# Main function of BDgraph package: BDMCMC algorithm for graphical models 
## ----------------------------------------------------------------------------|
bdgraph.mpl = function( data, n = NULL, method = "ggm", transfer = TRUE, algorithm = "bdmcmc", 
					iter = 5000, burnin = iter / 2, g.start = "empty",
					multi.update = NULL, alpha = 0.5, save.all = FALSE, 
					print = 1000 )
{
	burnin = floor( burnin )
	
	if( class( data ) == "sim" ) data <- data $ data
	colnames_data = colnames( data )

	if( !is.matrix( data ) & !is.data.frame( data ) ) stop( "Data should be a matrix or dataframe" )
	if( is.data.frame( data ) ) data <- data.matrix( data )
	if( iter <= burnin )   stop( "Number of iteration must be more than number of burn-in" )

	if( any( is.na( data ) ) ) stop( "This method does not deal with missing value. You could choose method = gcgm" )	
		
	p    <- ncol( data )
	if( is.null( n ) ) n <- nrow( data )

	if( method == "ggm" ) 
	{
		if( isSymmetric( data ) )
		{
			if ( is.null(n) ) stop( "Please specify the number of observations 'n'" )
			cat( "Input is identified as the covriance matrix. \n" )
			S <- data
		}else{
 			S <- t(data) %*% data
		}
	}
   
	if( method == "dgm" ) 
	{
		if( transfer == TRUE ) data = data_transform( data )  
	
		p = ncol( data ) - 1
		freq_data = data[ , p + 1 ]
		data      = data[ , -( p + 1 ) ]
		n         = sum( freq_data )
	
		max_range_nodes = apply( data, 2, max )
		length_f_data   = length( freq_data )	
	}
	
	if( class( g.start ) == "bdgraph" ) 
	{
		if( is.matrix( g.start ) ) G = unclass( g.start ) else G <- g.start $ last_graph
	}
	
	if( class( g.start ) == "sim" ) 	G <- as.matrix( g.start $ G )
	
	if( class( g.start ) == "character" && g.start == "empty" ) G = matrix( 0, p, p )
	
	if( class( g.start ) == "character" && g.start == "full" )
	{
		G         = matrix( 1, p, p )
		diag( G ) = 0
	}	

	if( is.matrix( g.start ) )
	{
		G       = g.start
		diag(G) = 0
	}
			
	if( save.all == TRUE )
	{
		qp1           = ( p * ( p - 1 ) / 2 ) + 1
		string_g      = paste( c( rep( 0, qp1 ) ), collapse = '' )
		sample_graphs = c( rep ( string_g, iter - burnin ) )  # vector of numbers like "10100" 
		graph_weights = c( rep ( 0, iter - burnin ) )         # waiting time for every state
		all_graphs    = c( rep ( 0, iter - burnin ) )         # vector of numbers like "10100"
		all_weights   = c( rep ( 1, iter - burnin ) )         # waiting time for every state		
		size_sample_g = 0
	}else{
		p_links = matrix( 0, p, p )
	}

	if( ( save.all == TRUE ) && ( p > 50 & iter > 20000 ) )
	{
		cat( "  WARNING: Memory needs to run this function is around " )
		print( ( iter - burnin ) * object.size( string_g ), units = "auto" ) 
	} 
	
	last_graph = matrix( 0, p, p )

	if( ( is.null( multi.update ) ) && ( p > 10 & iter > ( 5000 / p ) ) )
		multi.update = floor( p / 10 )
	
	if( is.null( multi.update ) ) multi.update = 1
	multi_update = multi.update
	
	if( ( p < 10 ) && ( multi_update > 1 ) )      cat( " WARNING: for the cases p < 10, multi.update must be 1 " )
	if( multi_update > min( p, sqrt( p * 11 ) ) ) cat( " WARNING: multi.update must be smaller " )
	
	if( algorithm != "hc" )
	{
		mes <- paste( c( iter, " iteration is started.                    " ), collapse = "" )
		cat( mes, "\r" )
	}

## ----------------------------------------------------------------------------|
	if( save.all == TRUE )
	{
		if( ( method == "ggm" ) && ( algorithm == "bdmcmc" ) && ( multi_update == 1 ) )
		{
			result = .C( "ggm_bdmcmc_mpl_map", as.integer(iter), as.integer(burnin), G = as.integer(G), as.double(S), as.integer(n), as.integer(p),
						all_graphs = as.integer(all_graphs), all_weights = as.double(all_weights), 
						sample_graphs = as.character(sample_graphs), graph_weights = as.double(graph_weights), size_sample_g = as.integer(size_sample_g),
						as.integer(print), PACKAGE = "BDgraph" )
		}

		if( ( method == "ggm" ) && ( algorithm == "bdmcmc" ) && ( multi_update != 1 ) )
		{
			counter_all_g = 0
			result = .C( "ggm_bdmcmc_mpl_map_multi_update", as.integer(iter), as.integer(burnin), G = as.integer(G), as.double(S), as.integer(n), as.integer(p), 
						all_graphs = as.integer(all_graphs), all_weights = as.double(all_weights), 
						sample_graphs = as.character(sample_graphs), graph_weights = as.double(graph_weights), size_sample_g = as.integer(size_sample_g), counter_all_g = as.integer(counter_all_g),
						as.integer(multi_update), as.integer(print), PACKAGE = "BDgraph" )
		}
      
		if( ( method == "dgm" ) && ( algorithm == "bdmcmc" ) && ( multi_update == 1 ) )
		{
			result = .C( "dgm_bdmcmc_mpl_map", as.integer(iter), as.integer(burnin), G = as.integer(G), 
			            as.integer(data), as.integer(freq_data), as.integer(length_f_data), as.integer(max_range_nodes), as.double(alpha), as.integer(n), as.integer(p),
						all_graphs = as.integer(all_graphs), all_weights = as.double(all_weights), 
						sample_graphs = as.character(sample_graphs), graph_weights = as.double(graph_weights), size_sample_g = as.integer(size_sample_g),
						as.integer(print), PACKAGE = "BDgraph" )
		}

		if( ( method == "dgm" ) && ( algorithm == "bdmcmc" ) && ( multi_update != 1 ) )
		{
			counter_all_g = 0
			result = .C( "dgm_bdmcmc_mpl_map_multi_update", as.integer(iter), as.integer(burnin), G = as.integer(G), 
			            as.integer(data), as.integer(freq_data), as.integer(length_f_data), as.integer(max_range_nodes), as.double(alpha), as.integer(n), as.integer(p), 
						all_graphs = as.integer(all_graphs), all_weights = as.double(all_weights), 
						sample_graphs = as.character(sample_graphs), graph_weights = as.double(graph_weights), size_sample_g = as.integer(size_sample_g), counter_all_g = as.integer(counter_all_g),
						as.integer(multi_update), as.integer(print), PACKAGE = "BDgraph" )
		}
      
	}else{
		
		if( ( method == "ggm" ) && ( algorithm == "bdmcmc" ) && ( multi_update == 1 )  )
		{
			result = .C( "ggm_bdmcmc_mpl_ma", as.integer(iter), as.integer(burnin), G = as.integer(G), as.double(S), as.integer(n), as.integer(p), 
						 p_links = as.double(p_links), as.integer(print), PACKAGE = "BDgraph" )
		}
		
		if( ( method == "ggm" ) && ( algorithm == "bdmcmc" ) && ( multi_update != 1 ) )
		{
			result = .C( "ggm_bdmcmc_mpl_ma_multi_update", as.integer(iter), as.integer(burnin), G = as.integer(G), as.double(S), as.integer(n), as.integer(p), 
						p_links = as.double(p_links), as.integer(multi_update), as.integer(print), PACKAGE = "BDgraph" )
		}				

		if( ( method == "dgm" ) && ( algorithm == "bdmcmc" ) && ( multi_update == 1 )  )
		{
			result = .C( "dgm_bdmcmc_mpl_ma", as.integer(iter), as.integer(burnin), G = as.integer(G), 
			            as.integer(data), as.integer(freq_data), as.integer(length_f_data), as.integer(max_range_nodes), as.double(alpha), 
						as.integer(n), as.integer(p), p_links = as.double(p_links), as.integer(print), PACKAGE = "BDgraph" )
		}

		if( ( method == "dgm" ) && ( algorithm == "bdmcmc" ) && ( multi_update != 1 ) )
		{
			result = .C( "dgm_bdmcmc_mpl_ma_multi_update", as.integer(iter), as.integer(burnin), G = as.integer(G), 
			            as.integer(data), as.integer(freq_data), as.integer(length_f_data), as.integer(max_range_nodes), as.double(alpha), as.integer(n), as.integer(p), 
						p_links = as.double(p_links), as.integer(multi_update), as.integer(print), PACKAGE = "BDgraph" )
		}				
	}
## ----------------------------------------------------------------------------|

	if( algorithm != "hc" )
	{
		last_graph = matrix( result $ G, p, p )

		colnames( last_graph ) = colnames_data[1:p]

		if( save.all == TRUE )
		{
			size_sample_g = result $ size_sample_g
			sample_graphs = result $ sample_graphs[ 1 : size_sample_g ]
			graph_weights = result $ graph_weights[ 1 : size_sample_g ]
			all_graphs    = result $ all_graphs + 1
			all_weights   = result $ all_weights	
			if( multi_update != 1 )
			{ 
				all_weights = all_weights[ 1 : ( result $ counter_all_g ) ]
				all_graphs  = all_graphs[  1 : ( result $ counter_all_g ) ] 
			}

			output = list( sample_graphs = sample_graphs, graph_weights = graph_weights, 
						all_graphs = all_graphs, all_weights = all_weights, last_graph = last_graph )
		}else{
			p_links   = matrix( result $ p_links, p, p ) 
			p_links[ lower.tri( p_links ) ] = 0
			colnames( p_links ) = colnames_data[1:p]
			output = list( p_links = p_links, last_graph = last_graph )
		}
	}else{
		selected_graph = hill_climb_mpl( data = data, freq_data = freq_data, n = n, max_range_nodes = max_range_nodes, alpha = alpha )
		
		colnames( selected_graph ) = colnames_data[1:p]
		output = selected_graph
	}
## ----------------------------------------------------------------------------|
	
	class( output ) = "bdgraph"
	return( output )   
}
         
