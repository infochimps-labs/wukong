# Find the Regional Flavor of topics using Geolocated Wikipedia Articles

(Chapter 1 of "Big Data for Chimps")

1. article -> wordbag
2. join on page data to get geolocation
3. use pagelinks to get larger pool of implied geolocations
  - create mapping from wiki id -> lat/long
  - n1 neighborhood of each article generates id list
  - map each id
4. turn geolocations into quadtile keys
5. aggregate topics by quadtile
6. take summary statistics aggregated over term and quadkey
7. combine those statistics to identify terms that occur more frequently than the base rate would predict
8. explore and validate the results
9. filter to find strongly-flavored words, and other reductions of the data for visualization

