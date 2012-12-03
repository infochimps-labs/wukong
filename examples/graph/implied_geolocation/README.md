# Implied Geolocation

* Some objects are explicitly geolocated: "Austin, Texas", "Cornell University", the "USS_Constitution".
* Some objects are not only geolocated, they are 'places' -- present as well in the geonames dataset.

The estimator is as follows:

* a best-estimate longitude and latitude
* the radius of uncertainty for the point
* the likelihood the point is erroneous

	 12000 krec articles
	  7000 krec geonames
	   400 krec dbpedia-geo_coordinates_en.json
	    87 krec dbpedia-geonames_links.json
	    


### dispatch geolocation estimates along links

* Send every neighbor your geoestimate

accumulate all neighbors' geoestimates.


In this drawing, the vertical bars show implied locations; six reasonably nearby each other and two with large error.

          |      | |       |  ||               |          |
      ----+------+-+-------+--++------- // ----+---- // --+-----

But of course in some places I _know_ the location

          |    X | |       |  ||               |          |
      ----+----X-+-+-------+--++------- // ----+---- // --+-----
               X
                `-- actual location


Why are the estimates spread from the actual?

* intrinsic size of the actual: the graph neighbors of "Texas" are spread over a much larger area than the graph neighbors of "Yee-Haw Junction, FL".
* strength of the relationship: for example, this naive model can't tell the difference between "X is located in Y" and "X borders Y"
* errors in the relationship: the link might be irrelevant or not explanatory for any reason -- anything from "X has the same area as Virginia" to a hacked page.
* multi-modal location: Davey Crockett (TODO: verify) was from XXX to XXX the representative of Tennesee (location #1) to the US Congress in Washington, DC (locaton #2). Upon losing re-election, he famously said "You can all go to hell, I am going to Texas"; he died during the battle of the Alamo. The most robust assignment of a geolocation to "Davey Crockett" would look something like the following cartoon:
 
         ____          	 
        /    \	      ------
       /      \	     /      \	   +-+
       |       |_____|       |____/   \
       
       Tennesee        Texas        DC


So what we're going to do is track two separate types of error:

* the likelihood the estimate is drawn from purely irrelevant points
* assuming the estimates are relevant, the fuzziness of the implied geolocation.



* ?? only use estimates with some strength ??
* For all known points, the number of neighbors that are irrelevant
       