# Reading the tracks is its own step because it takes so long
read_tracks <- function(rfbo_path) {
  read_csv(rfbo_path) %>%
    # Filter out acceleration data
    filter(sensor.type == "gps") %>%
    transmute(
      id = DeployID,
      date = ymd_hms(Timestamp, tz = "UTC"),
      x = gps.location.long,
      y = gps.location.lat
    ) %>%
    # There are some duplicate timestamps from GPS bursts; keep the first record
    group_by(id, date) %>%
    slice(1) %>%
    ungroup()
}

# Label trips by distance-to-colony and duration thresholds
label_trips <- function(tracks, colony_dist_km, duration_hr) {
  # Kilauea Point National Wildlife Refuge
  kpnwr <- c(lon = -159.4, lat = 22.2)

  # Sub-function to label trips in one deployment
  label_deployment <- function(id, date, x, y) {
    # Measure distance to colony and fill in gaps with last known distance
    dist_to_col_km <- geodist(
      cbind(x, y),
      kpnwr,
      measure = "geodesic"
    ) / 1000
    dist_to_col_km_interp <- approx(
      x = seq_along(dist_to_col_km),
      y = dist_to_col_km,
      xout = seq_along(dist_to_col_km),
      method = "constant",
      f = 0
    )$y

    # Assign trip numbers based on distance threshold
    trip_start <- dist_to_col_km_interp >= colony_dist_km &
      lag(dist_to_col_km_interp, default = Inf) < colony_dist_km
    trip_num_dist <- cumsum(trip_start)
    trip_num_dist[dist_to_col_km_interp < colony_dist_km] <- NA

    # Remove trips shorter than duration threshold
    valid_trips <- tibble(trip_num_dist, date) %>%
      group_by(trip_num_dist) %>%
      summarize(dur_hr = as.numeric(max(date) - min(date), unit = "hours")) %>%
      filter(dur_hr >= duration_hr) %>%
      mutate(trip_label = sprintf("%s_%04d", id[1], row_number()))

    # Return result
    tibble(trip_num_dist) %>%
      left_join(valid_trips, by = "trip_num_dist") %>%
      pull(trip_label)
  }

  # Do it for all deployments
  tracks %>%
    group_by(id) %>%
    mutate(burst = label_deployment(id, date, x, y)) %>%
    ungroup() %>%
    drop_na(burst)
}

# Use adehabitatLT to re-discretize tracks
rediscretize <- function(tracks, time_step) {
  tracks %>%
    dl(proj4string = CRS("+proj=longlat +datum=WGS84")) %>%
    redisltraj(time_step, type = "time") %>%
    ld()
}

# Only keep trips without long gaps
quality_filter <- function(tracks, max_gaps) {
  find_longest_gap <- function(x) {
    x_rle <- rle(is.na(x))
    if (all(x_rle$values == FALSE)) {
      0
    } else {
      max(x_rle$lengths[x_rle$values])
    }
  }
  tracks %>%
    group_by(burst) %>%
    summarize(longest_gap = find_longest_gap(x)) %>%
    filter(longest_gap < max_gaps) %>%
    semi_join(tracks, ., by = "burst")
}
