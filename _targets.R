# Load packages required to define the pipeline:
library(here)
library(targets)
# library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("adehabitatLT",
               "geodist",
               "lubridate",
               "tidyverse"),
  format = "rds"
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# Replace the target list below with your own:
list(
  # Read and clean tracks
  tar_target(
    name = rfbo_path,
    command = here("analysis", "data", "raw_data", "RFBO_eObs_clean.csv"),
    format = "file"
  ),
  tar_target(
    name = rfbo_tracks_raw,
    command = read_tracks(rfbo_path)
  ),
  tar_target(
    name = rfbo_tracks,
    command = rfbo_tracks_raw %>%
      label_trips(colony_dist_km = 50, duration_hr = 2) %>%
      rediscretize(time_step = 120) %>%
      quality_filter(max_gaps = 1)
  )
)
