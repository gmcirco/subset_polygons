subset_polygons <- function(p,a,g, plot_map = F, data_return = "polygon"){
  
  # mimicks 'subset_polygon' feature from ArcGIS
  # function takes 3 main arguments
  # point shapefile p
  # polygon shapefile a
  # desired group number g
  
  # get number of obs per group
  n <- round (nrow(p)/g )
  
  # cluster data into equal-sized groups
  # using nnid
  # set up matrix
  k_mat <- as.matrix(st_coordinates(p))
  
  # calculate clusters
  nn_id <- nnit(k_mat, clsize = n)
  
  # bind into dataframe
  clst_df <- data.frame(st_coordinates(p), grp = nn_id)
  
  # convert back to sf
  clst_df <- st_as_sf(clst_df, coords = c("X","Y"), crs = st_crs(p))
  
  # merge theissen polygons w/ group ids
  # code taken from:
  # https://gis.stackexchange.com/questions/362134/
  g <- st_combine(st_geometry(clst_df)) # make multipoint
  v <- st_voronoi(g)
  v <- st_collection_extract(v)
  out <- v[unlist(st_intersects(clst_df, v))]
  pv <- st_set_geometry(clst_df, out)
  
  # merge polygons back, dissolve by group id
  suppressWarnings(
    j_area_poly <- st_intersection(st_cast(pv), st_union(a)) %>%
      group_by(grp) %>% summarise(st_union(geometry))
  )
  
  # plot?
  if(plot_map == T)
    plot(j_area_poly)
  
  # export data
  if(data_return == "polygon")
    return(j_area_poly)

  if(data_return == "point")
    return(clst_df)
  
  
}

# function to calculate
# iterative nearest neighbor
# code taken from:
# http://jmonlong.github.io/Hippocamplus/2018/06/09/cluster-same-size/
nnit <- function(mat, clsize = 10){
  clsize.rle = rle(as.numeric(cut(1:nrow(mat), ceiling(nrow(mat)/clsize))))
  clsize = clsize.rle$lengths
  lab = rep(NA, nrow(mat))
  dmat = as.matrix(dist(mat))
  cpt = 1
  
  # compute iterative nearest neighbors using max distance rule
  while(sum(is.na(lab)) > 0){
    lab.ii = which(is.na(lab))
    dmat.m = dmat[lab.ii,lab.ii]
    ii = which.max(rowSums(dmat.m))
    lab.m = rep(NA, length(lab.ii))
    lab.m[head(order(dmat.m[ii,]), clsize[cpt])] = cpt
    lab[lab.ii] = lab.m
    cpt = cpt + 1
  }
  if(any(is.na(lab))){
    lab[which(is.na(lab))] = cpt
  }
  lab
}
