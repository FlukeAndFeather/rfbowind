# Downloading data

This analysis relies on two open data sources: seabird tracking data collected by the US Geological Survey (USGS) and wind vectors from the Pacific Islands Ocean Observing System (PacIOOS) regional atmospheric model. These data are too large to store in the analysis repository, so this document walks the reader through the download process.

## Seabird tracks

The Red-footed Booby (RFBO) is a pan-tropical seabird that breeds on small islands and feeds on fish and squid at or near the ocean's surface (or above the surface, in the case of flying fish/squid). In 2016, USGS tracked RFBOs with GPS/accelerometer bio-loggers (e-obs GmbH, Gruenwald, Germany) as part of a study on the distribution of seabirds breeding in the Main Hawaiian Islands. These data are archived in USGS' ScienceBase as part of a larger data release (DOI 10.5066/P9NTEXM6). Follow these steps to download the data and put them in the correct location for analysis.

1. Direct your browser to [http://doi.org/10.5066/P9NTEXM6](http://doi.org/10.5066/P9NTEXM6).
2. Navigate to the second child item entitled "2. GPS (e-obs) Tracking and Accelerometry Data of Seabirds Breeding in the Main Hawaiian Islands".
3. Under "Attached Files", follow the link to "RFBO_eObs.zip" and download the file.
4. Unzip "RFBO_eObs.zip" and move "RFBO_eObs_clean.csv" to "analysis/data/raw_data" in this project directory. *NOTE:* the default archive utility on MacOS doesn't handle files this size appropriately and throws "Error 79 - Inappropriate file type or format." The authors suggest installing [The Unarchiver](https://theunarchiver.com/) and using that to unzip the file.

## Wind vectors

PacIOOS provides wind vectors for the Main Hawaiian Islands from an atmospheric model (cite). The following cade chunk downloads these data from an ERDDAP server to the raw_data/ directory. Note: some of the seabird tracks extend beyond the range of the wind model.

```r
wind_filepath <- here::here("analysis", "data", "raw_data", "wrf_hi_wind")
time_range <- c("2016-05-28T01:00:00Z", "2016-09-18T03:00:00Z")
lon_range <- c(-161.8, -157.3)
lat_range <- c(20.2, 24.29)
wrf_wind <- rerddap::griddap(
  datasetx = "wrf_hi",
  time = time_range,
  longitude = lon_range,
  latitude = lat_range,
  fields = c("Uwind", "Vwind"),
  fmt = "nc",
  store = rerddap::disk(wind_filepath)
)
```
