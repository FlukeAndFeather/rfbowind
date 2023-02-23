# Reading the acceleration is its own step because it takes so long
read_acc <- function(rfbo_path) {
  read_csv(rfbo_path) %>%
    # Filter out GPS data
    filter(sensor.type == "acceleration") %>%
    transmute(
      id = DeployID,
      date = ymd_hms(Timestamp, tz = "UTC"),
      accelerations.raw
    )
}

# Temporally join acc and tracks
join_acc_tracks <- function(acc, tracks) {
  # Split acc and tracks by deployment id
  acc_split <- split(acc, acc$id)
  tracks_split <- split(tracks, tracks$id)
  stopifnot(all(names(tracks_split) %in% names(acc_split)))

  # Join acc and tracks within each deployment
  map_dfr(names(tracks_split), function(id) {
    # Expand raw acceleration
    acc_fs <- 20
    acc_id <- acc_split[[id]] %>%
      separate_longer_delim(accelerations.raw, " ") %>%
      mutate(axis = rep(c("x", "y", "z"), n() / 3),
             # Dummy variable so we can pivot properly
             sampleid = rep(seq(n() / 3), each = 3)) %>%
      pivot_wider(names_from = axis,
                  values_from = accelerations.raw) %>%
      # TODO: Add a '%' before Y
      mutate(acc_burst = str_glue("{id}_{format(date, \"Y%m%d%H%M%S\")}"),
             date = date + (seq(n()) - 1) / acc_fs) %>%
      select(-sampleid)
    tracks_id <- tracks_split[[id]]
    # Bursts are equally spaced temporally, so use interpolation for faster join
    tracks_id %>%
      group_by(burst) %>%
      group_modify(function(group, key) {
        dt <- group$dt[1]
        acc_burst <- acc_id %>%
          filter(between(date,
                         min(group$date) - dt / 2 - 1,
                         max(group$date) + dt / 2 + 1)) %>%
          mutate(burst_row = approx(group$date,
                                    seq_along(group$date),
                                    xout = date,
                                    method = "constant",
                                    rule = 2)$y)
        acc_track <- group %>%
          slice(acc_burst$burst_row) %>%
          select(gps_date = date, state)
        acc_burst %>%
          cbind(acc_track) %>%
          mutate(date_diff = as.numeric(date - gps_date, unit = "secs")) %>%
          filter(between(date_diff, 0, dt)) %>%
          select(-date_diff, -burst_row)
      })
  })
}

acc_energy <- function(acc) {
  El_fun <- function(x, k) {
    RcppRoll::roll_sum(x^2, n = k, fill = NA)
  }
  acc %>%
    group_by(acc_burst) %>%
    # Linear detrending along each axis within bursts
    mutate(across(x:z, list(low = ~ predict(lm(.x ~ seq_along(.x))))),
           across(x:z, list(high = ~ resid(lm(.x ~ seq_along(.x))))),
           # 5 acceleration samples ~= w = 0.27 s
           across(x_high:z_high,
                  list(El = partial(El_fun, k = 5)),
                  # TODO: fix this
                  .names = "substr({.col}, 1, 1)_{.fn}"))
}
