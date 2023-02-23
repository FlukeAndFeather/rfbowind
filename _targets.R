# Load packages required to define the pipeline:
library(here)
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c("adehabitatLT",
               "geodist",
               "lubridate",
               "moveHMM",
               "tidyverse"),
  format = "rds"
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# Parameters for data cleaning
coldist <- 20
durhr <- 2
maxgaps <- 4

# Replace the target list below with your own:
list(
  # Read and clean tracks
  tar_target(
    rfbo_path,
    here("analysis", "data", "raw_data", "RFBO_eObs_clean.csv"),
    format = "file"
  ),
  tar_target(rfbo_tracks_raw, read_tracks(rfbo_path)),
  tar_target(
    rfbo_tracks_clean,
    rfbo_tracks_raw %>%
      label_trips(colony_dist_km = coldist, duration_hr = durhr) %>%
      rediscretize(time_step = 120) %>%
      quality_filter(max_gaps = maxgaps)
  ),
  # Fit HMM and decode states
  tar_target(rfbo_hmm, fit_hmm(rfbo_tracks_clean)),
  tar_target(
    rfbo_decoded,
    mutate(rfbo_tracks_clean, state = viterbi(rfbo_hmm))
  ),
  # Process acceleration data
  tar_target(rfbo_acc_raw, read_acc(rfbo_path)),
  tar_target(rfbo_acc, join_acc_tracks(rfbo_acc_raw, rfbo_decoded)),
  tar_target(rfbo_acc_El, acc_energy(rfbo_acc)),
  # Workflow reports
  tar_quarto(reports,
             here("analysis", "workflow"))
)
