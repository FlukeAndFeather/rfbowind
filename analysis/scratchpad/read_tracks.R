library(lubridate)
library(tidyverse)

rfbo_path <- here::here("analysis", "data", "raw_data", "RFBO_eObs_clean.csv")
rfbo_tracks <- read_csv(rfbo_path) %>%
  filter(sensor.type == "gps") %>%
  transmute(
    deployid = DeployID,
    datetime = ymd_hms(Timestamp, tz = "UTC"),
    longitude = gps.location.long,
    latitude = gps.location.lat,
    gps_spd = gps.ground.speed,
    gps_spd_acc = gps.speed.accuracy.estimate
  )
glimpse(rfbo_tracks)
rfbo_tracks %>%
  group_by(deployid) %>%
  mutate(timestep = as.numeric(lead(datetime) - datetime, unit = "secs")) %>%
  count(timestep)
