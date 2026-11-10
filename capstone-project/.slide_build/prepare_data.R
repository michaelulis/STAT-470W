library(tidyverse)
library(jsonlite)
features <- read_csv('eda_output/trial_features.csv', show_col_types=FALSE)
agreement <- read_csv('eda_output/signal_agreement.csv', show_col_types=FALSE)
durations <- features |>
  mutate(Bin = cut(End_ms, breaks=c(0,100,200,300,400,500), right=FALSE,
                   labels=c('0-99','100-199','200-299','300-399','400-499'))) |>
  count(Participant, Bin, .drop=FALSE) |> group_by(Participant) |>
  mutate(Fraction=n/sum(n)) |> ungroup()
baseline <- features |> group_by(Participant,Condition) |>
  summarise(Median_SD=median(Baseline_SD),
            Median_fraction_outside_020=median(Fraction_outside_020), .groups='drop')
file <- 'data/Participant A/Condition_A_Block_1/Trial12.LeftBackgroundSlowTarget.csv'
sample <- read_csv(file,show_col_types=FALSE)
pixel <- sample$`Pixel event`[1]
end <- c(na.omit(sample$`Got target`),na.omit(sample$`Missed target`))[1]-pixel
derivative <- function(x,t) {
  n <- length(x)
  c(NA_real_, (x[3:n]-x[1:(n-2)])/(t[3:n]-t[1:(n-2)]), NA_real_)
}
traces <- map_dfr(c(1L,11L,21L),function(width) {
  position <- if(width==1L) sample$Right_HandX else as.numeric(stats::filter(sample$Right_HandX,rep(1/width,width),sides=2))
  accel <- derivative(derivative(position,sample$Frame/1000),sample$Frame/1000)
  tibble(Width_ms=width,Time_ms=sample$Frame-pixel,Acceleration=accel) |>
    filter(Time_ms>=-200, Time_ms<=end)
})
noise_example <- traces |> filter(Time_ms<=-20) |> group_by(Width_ms) |>
  summarise(Baseline_SD=sd(Acceleration), .groups='drop')
data <- list(
  duration_bins=c('0-99','100-199','200-299','300-399','400-499'),
  durations=durations, baseline=baseline, traces=traces, sample_end=end,
  sample_file=file, example_noise=noise_example,
  duration_summary=features |> group_by(Participant) |>
    summarise(N=n(), Median=median(End_ms), Minimum=min(End_ms), Maximum=max(End_ms), .groups='drop'),
  agreement_max_rmse=max(agreement$RMSE),
  baseline_sd_all=median(features$Baseline_SD),
  baseline_fraction_all=median(features$Fraction_outside_020))
write_json(data,'.slide_build/data.json',auto_unbox=TRUE,pretty=TRUE,na='null',digits=15)
print(baseline)
print(noise_example)
