read_tracks <- function(rfbo_path) {
  # Cut tracks into daily bursts
  assign_burst <- function(id, date_utc) {
    burst_date <- with_tz(date_utc, "Etc/GMT+10") %>%
      format("%Y%m%d")
    sprintf("%s.%s", id, burst_date)
  }
  read_csv(rfbo_path) %>%
    # Filter out acceleration data
    filter(sensor.type == "gps") %>%
    transmute(
      id = DeployID,
      date = ymd_hms(Timestamp, tz = "UTC"),
      burst = assign_burst(id, date),
      x = gps.location.long,
      y = gps.location.lat
    ) %>%
    # There are some duplicate timestamps from GPS bursts; keep the first record
    group_by(id, date) %>%
    slice(1) %>%
    ungroup()
}

# Use adehabitatLT to re-discretize tracks and cut into day-long bursts
redis_tracks <- function(rfbo_tracks) {
  rfbo_traj <- rfbo_tracks %>%
    dl(proj4string = CRS("+proj=longlat +datum=WGS84")) %>%
    redisltraj(120, type = "time") %>%
    ld()
}

# Only keep full-day tracks without gaps within environmental data coverage
filter_tracks <- function(rfbo_tracks) {
  rfbo_tracks %>%
    group_by(burst) %>%
    summarize(no_gaps = all(!is.na(x)),
              full_day = n() == 24 * 60 / 2,
              in_coverage = max(y) < 25) %>%
    filter(no_gaps & full_day & in_coverage) %>%
    semi_join(rfbo_tracks, ., by = "burst")
}

# All together
get_tracks <- function(rfbo_path) {
  rfbo_path %>%
    read_tracks() %>%
    redis_tracks() %>%
    filter_tracks()
}
