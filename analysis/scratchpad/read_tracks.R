library(adehabitatLT)
library(ggOceanMaps)
library(lubridate)
library(sf)
library(tidyverse)

# Read tracking CSV file
rfbo_path <- here::here("analysis", "data", "raw_data", "RFBO_eObs_clean.csv")
rfbo_tracks <- read_csv(rfbo_path) %>%
  # Filter out acceleration data
  filter(sensor.type == "gps") %>%
  transmute(
    deployid = DeployID,
    datetime = ymd_hms(Timestamp, tz = "UTC"),
    longitude = gps.location.long,
    latitude = gps.location.lat
  ) %>%
  # There are some duplicate timestamps from GPS bursts; keep the first record
  group_by(deployid, datetime) %>%
  slice(1) %>%
  ungroup()

# Use adehabitatLT to re-discretize tracks
rfbo_traj <- with(
  rfbo_tracks,
  as.ltraj(xy = cbind(longitude, latitude),
           date = datetime,
           deployid,
           proj4string = CRS("+proj=longlat +datum=WGS84"))
) %>%
  redisltraj(120, type = "time")
# Cut tracks into daily bursts, starting at 4am local time
cut_day <- function(date) {
  dt <- as.POSIXct(date, "UTC") %>%
    with_tz("Etc/GMT+10")
  hour(dt) == 4 & minute(dt) < 2
}
rfbo_traj2 <- cutltraj(rfbo_traj, "cut_day(date)", nextr = TRUE)
rfbo_tracks2 <- ld(rfbo_traj2)

# Retain only whole days without GPS gaps
# Remove one trip that left the wind data coverage region
complete_tracks <- rfbo_tracks2 %>%
  group_by(id, burst) %>%
  summarize(no_gaps = all(!is.na(x)),
            full_day = n() == 24 * 60 / 2,
            in_coverage = max(y) < 25,
            .groups = "drop") %>%
  filter(no_gaps & full_day & in_coverage) %>%
  semi_join(rfbo_tracks2, ., by = "burst")
# Leaves us with 40 days from 13 birds (1-6 days per bird, median 3 days)
complete_tracks %>%
  group_by(id) %>%
  summarize(n_bursts = n_distinct(burst))

# Create map
basemap(data = complete_tracks) +
  geom_path(aes(x = x, y = y, color = id, group = burst),
            complete_tracks)
