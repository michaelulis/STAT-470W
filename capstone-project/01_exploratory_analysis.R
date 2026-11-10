
# =============================================================================
# STAT 470W CAPSTONE PROJECT
# Exploratory Data Analysis: Lateral Acceleration
# =============================================================================
#
# Purpose:
# Explore lateral hand acceleration during reaching movements
# to understand response patterns before estimating onset times.
#
# Data:
# Participant A and Participant B
#
# =============================================================================


# -----------------------------------------------------------------------------
# 01. Load Required Packages
# -----------------------------------------------------------------------------

library(tidyverse)
library(readxl)


# -----------------------------------------------------------------------------
# 02. Project Directories
# -----------------------------------------------------------------------------

# Get the current RStudio project directory.
project_dir <- getwd()

# Define folders for raw data and exported figures.
data_dir <- file.path(project_dir, "capstone-project", "data")
figures_dir <- file.path(project_dir, "capstone-project", "figures")

# Create folders if they do not already exist.
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)


# -----------------------------------------------------------------------------
# 03. Identify Participant Data Files
# -----------------------------------------------------------------------------

# Find all CSV trial files inside the data folder and its subfolders.
trial_files <- list.files(
  path = data_dir,
  pattern = "\\.csv$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

# Display the number of trial files found.
cat("Number of trial files found:", length(trial_files), "\n")

# Display the first few file paths.
head(trial_files)


# -----------------------------------------------------------------------------
# 04. Inspect a Sample Trial
# -----------------------------------------------------------------------------

# Select the first trial file.
sample_file <- trial_files[1]

# Import the trial data.
sample_trial <- readr::read_csv(
  file = sample_file,
  show_col_types = FALSE
)

# Display the file being examined.
cat("\nSample trial file:\n")
print(sample_file)

# Display the number of rows and columns.
cat("\nTrial dimensions:\n")
print(dim(sample_trial))

# Display all column names.
cat("\nColumn names:\n")
print(names(sample_trial))

# Display the first six rows.
cat("\nFirst six observations:\n")
print(head(sample_trial))


# -----------------------------------------------------------------------------
# 05. Examine Event Timing
# -----------------------------------------------------------------------------

# Display the unique values recorded in the Pixel event column.
unique(sample_trial$`Pixel event`)

# Count the number of nonmissing Pixel event entries.
sum(!is.na(sample_trial$`Pixel event`))

# Display rows containing a Pixel event entry.
pixel_events <- sample_trial %>%
  filter(!is.na(`Pixel event`))

print(pixel_events %>%
        select(Frame, `Pixel event`))

# Examine the acceleration values.
summary(sample_trial$Right_HandAccX)


# -----------------------------------------------------------------------------
# 06. Plot Lateral Acceleration for One Trial
# -----------------------------------------------------------------------------

# Extract the frame when the Pixel event occurred.
pixel_frame <- sample_trial$`Pixel event`[1]

# Calculate time relative to the Pixel event (milliseconds).
sample_trial <- sample_trial %>%
  mutate(
    Time_ms = Frame - pixel_frame
  )

# Keep observations from 200 ms before to 500 ms after the event.
plot_data <- sample_trial %>%
  filter(
    Time_ms >= -200,
    Time_ms <= 500
  )

# Create the acceleration plot.
ggplot(plot_data, aes(x = Time_ms, y = Right_HandAccX)) +
  geom_line(color = "#2563EB", linewidth = 0.7) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "#DC2626"
  ) +
  labs(
    title = "Lateral Hand Acceleration During a Reaching Trial",
    subtitle = "Time aligned to the Pixel event",
    x = "Time Relative to Pixel Event (ms)",
    y = "Lateral Acceleration (m/s²)"
  ) +
  theme_minimal(base_size = 13)


# -----------------------------------------------------------------------------
# 07. Compare Position, Velocity, and Acceleration
# -----------------------------------------------------------------------------

# Reshape the three lateral movement measurements for plotting.
movement_data <- sample_trial %>%
  filter(Time_ms >= -200, Time_ms <= 500) %>%
  select(
    Time_ms,
    Right_HandX,
    Right_HandVelX,
    Right_HandAccX
  ) %>%
  pivot_longer(
    cols = c(Right_HandX, Right_HandVelX, Right_HandAccX),
    names_to = "Measurement",
    values_to = "Value"
  )

# Plot each measurement in a separate panel.
ggplot(movement_data, aes(x = Time_ms, y = Value)) +
  geom_line(color = "#2563EB", linewidth = 0.5) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "#DC2626"
  ) +
  facet_wrap(
    ~ Measurement,
    ncol = 1,
    scales = "free_y"
  ) +
  labs(
    title = "Lateral Hand Movement Across a Single Trial",
    subtitle = "Position, velocity, and acceleration aligned to the Pixel event",
    x = "Time Relative to Pixel Event (ms)",
    y = "Recorded Value"
  ) +
  theme_minimal(base_size = 12)


# -----------------------------------------------------------------------------
# 08. Examine Trial File Organization
# -----------------------------------------------------------------------------

# Display the first 20 trial file paths.
cat("\nFirst 20 trial files:\n")
print(head(trial_files, 20))

# Display the number of files in each immediate parent folder.
trial_folders <- dirname(trial_files)

cat("\nTrial counts by folder:\n")
print(sort(table(trial_folders), decreasing = TRUE))


# -----------------------------------------------------------------------------
# 09. Create Trial Metadata Table
# -----------------------------------------------------------------------------

# Create one row for each trial file.
trial_info <- tibble(
  File = trial_files
) %>%
  mutate(
    # Identify the participant from the file path.
    Participant = case_when(
      str_detect(File, "Participant A") ~ "A",
      str_detect(File, "Participant B") ~ "B"
    ),
    
    # Extract the condition and block folder name.
    Block_Folder = basename(dirname(File)),
    
    # Extract the experimental condition.
    Condition = str_extract(
      Block_Folder,
      "(?<=Condition_)[AB]"
    ),
    
    # Extract the block number.
    Block = as.integer(
      str_extract(Block_Folder, "(?<=Block_)\\d+")
    ),
    
    # Extract the trial number.
    Trial = as.integer(
      str_extract(basename(File), "(?<=Trial)\\d+")
    ),
    
    # Extract the background label.
    Background = str_extract(
      basename(File),
      "LeftBackground|RightBackground|StaticBackground"
    ),
    
    # Extract the target speed.
    Target_Speed = str_extract(
      basename(File),
      "FastTarget|SlowTarget"
    )
  )

# Display the first ten rows.
print(head(trial_info, 10))

# Count trials by participant and condition.
trial_counts <- trial_info %>%
  count(Participant, Condition, Block)

print(trial_counts)

# Count trials by background and target speed.
trial_types <- trial_info %>%
  count(Background, Target_Speed)

print(trial_types)



# -----------------------------------------------------------------------------
# 10. Import and Align Multiple Trials
# -----------------------------------------------------------------------------

# Select one group of comparable trials.
selected_trials <- trial_info %>%
  filter(
    Participant == "A",
    Condition == "A",
    Block == 1,
    Background == "StaticBackground",
    Target_Speed == "SlowTarget"
  )

# Display the number of selected trials.
cat("Number of selected trials:", nrow(selected_trials), "\n")

# Define a function to import and align one trial.
read_aligned_trial <- function(file_path) {
  
  # Import the CSV file.
  trial <- readr::read_csv(
    file_path,
    show_col_types = FALSE
  )
  
  # Extract the Pixel event frame.
  pixel_values <- trial$`Pixel event`
  pixel_values <- pixel_values[!is.na(pixel_values)]
  
  # Skip trials without exactly one Pixel event.
  if (length(pixel_values) != 1) {
    return(NULL)
  }
  
  pixel_frame <- pixel_values[1]
  
  # Align time and retain the lateral acceleration measurement.
  trial %>%
    mutate(
      Time_ms = Frame - pixel_frame
    ) %>%
    filter(
      Time_ms >= -200,
      Time_ms <= 500
    ) %>%
    select(
      Time_ms,
      Right_HandAccX
    )
}

# Import and align all selected trials.
aligned_trials <- purrr::map2_dfr(
  selected_trials$File,
  selected_trials$Trial,
  function(file_path, trial_number) {
    
    trial_data <- read_aligned_trial(file_path)
    
    if (is.null(trial_data)) {
      return(NULL)
    }
    
    trial_data %>%
      mutate(Trial = trial_number)
  }
)

# Inspect the combined data.
cat("Number of aligned trials:",
    n_distinct(aligned_trials$Trial), "\n")

print(head(aligned_trials))


# -----------------------------------------------------------------------------
# 11. Calculate and Plot Average Lateral Acceleration
# -----------------------------------------------------------------------------

# Calculate the mean acceleration at each millisecond.
average_acceleration <- aligned_trials %>%
  group_by(Time_ms) %>%
  summarise(
    Mean_AccX = mean(Right_HandAccX, na.rm = TRUE),
    .groups = "drop"
  )

# Create a graph showing individual trials and their average.
average_acceleration_plot <- ggplot() +
  
  # Individual trials: thin, transparent gray lines.
  geom_line(
    data = aligned_trials,
    aes(
      x = Time_ms,
      y = Right_HandAccX,
      group = Trial
    ),
    color = "gray65",
    alpha = 0.25,
    linewidth = 0.3
  ) +
  
  # Average acceleration: thicker blue line.
  geom_line(
    data = average_acceleration,
    aes(
      x = Time_ms,
      y = Mean_AccX
    ),
    color = "#2563EB",
    linewidth = 1
  ) +
  
  # Pixel event at time zero.
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "#DC2626",
    linewidth = 0.7
  ) +
  
  labs(
    title = "Individual and Average Lateral Acceleration",
    subtitle = "Participant A | Condition A | Block 1 | Static Background | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Recorded Lateral Acceleration"
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Display the graph.
print(average_acceleration_plot)

# Save the graph for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "average_acceleration_participant_A.png"
  ),
  plot = average_acceleration_plot,
  width = 11,
  height = 6,
  dpi = 300
)


# -----------------------------------------------------------------------------
# 12. Plot Mean Acceleration and Between-Trial Variability
# -----------------------------------------------------------------------------

# Calculate mean acceleration and standard deviation at each millisecond.
acceleration_summary <- aligned_trials %>%
  group_by(Time_ms) %>%
  summarise(
    Mean_AccX = mean(Right_HandAccX, na.rm = TRUE),
    SD_AccX = sd(Right_HandAccX, na.rm = TRUE),
    N = sum(!is.na(Right_HandAccX)),
    .groups = "drop"
  )

# Create a cleaner summary plot.
acceleration_summary_plot <- ggplot(
  acceleration_summary,
  aes(x = Time_ms, y = Mean_AccX)
) +
  geom_ribbon(
    aes(
      ymin = Mean_AccX - SD_AccX,
      ymax = Mean_AccX + SD_AccX
    ),
    fill = "#93C5FD",
    alpha = 0.35
  ) +
  geom_line(
    color = "#2563EB",
    linewidth = 0.9
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "#DC2626"
  ) +
  geom_hline(
    yintercept = 0,
    color = "gray50",
    linewidth = 0.4
  ) +
  labs(
    title = "Mean Lateral Acceleration and Trial Variability",
    subtitle = "Participant A | Condition A | Block 1 | Static Background | Slow Target (n = 20)",
    x = "Time Relative to Pixel Event (ms)",
    y = "Recorded Lateral Acceleration",
    caption = "Shaded band represents mean ± 1 standard deviation across trials."
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Display the graph.
print(acceleration_summary_plot)

# Export for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "mean_acceleration_variability.png"
  ),
  plot = acceleration_summary_plot,
  width = 11,
  height = 6,
  dpi = 300
)


# -----------------------------------------------------------------------------
# 13. Compare Trial Counts Across Background Categories
# -----------------------------------------------------------------------------

# Select Participant A, Condition A, Block 1, Slow Target.
background_comparison <- trial_info %>%
  filter(
    Participant == "A",
    Condition == "A",
    Block == 1,
    Target_Speed == "SlowTarget"
  )

# Count the trials in each background category.
background_counts <- background_comparison %>%
  count(Background)

# Display the results.
print(background_counts)


# -----------------------------------------------------------------------------
# 14. Compare Mean Acceleration Across Background Categories
# -----------------------------------------------------------------------------

# Import and align all 50 selected trials.
background_trials <- purrr::map2_dfr(
  background_comparison$File,
  seq_len(nrow(background_comparison)),
  function(file_path, trial_id) {
    
    # Use the alignment function created in Section 10.
    trial_data <- read_aligned_trial(file_path)
    
    # Skip trials without a valid Pixel event.
    if (is.null(trial_data)) {
      return(NULL)
    }
    
    # Attach a unique identifier to each trial.
    trial_data %>%
      mutate(Trial_ID = trial_id)
  }
)

# Attach background labels using each trial's unique identifier.
background_trials <- background_trials %>%
  left_join(
    background_comparison %>%
      mutate(Trial_ID = row_number()) %>%
      select(Trial_ID, Background),
    by = "Trial_ID"
  )

# Calculate mean acceleration separately for each background.
background_summary <- background_trials %>%
  group_by(Background, Time_ms) %>%
  summarise(
    Mean_AccX = mean(Right_HandAccX, na.rm = TRUE),
    SD_AccX = sd(Right_HandAccX, na.rm = TRUE),
    N = sum(!is.na(Right_HandAccX)),
    .groups = "drop"
  )

# Create the three-panel comparison.

# -----------------------------------------------------------------------------
# 14B. Cleaner Comparison of Mean Acceleration
# -----------------------------------------------------------------------------

background_plot <- ggplot(
  background_summary,
  aes(
    x = Time_ms,
    y = Mean_AccX,
    color = Background
  )
) +
  geom_line(linewidth = 0.8) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "gray40"
  ) +
  geom_hline(
    yintercept = 0,
    color = "gray65"
  ) +
  scale_color_manual(
    values = c(
      "LeftBackground" = "#2563EB",
      "RightBackground" = "#DC2626",
      "StaticBackground" = "#16A34A"
    ),
    labels = c(
      "LeftBackground" = "Left",
      "RightBackground" = "Right",
      "StaticBackground" = "Static"
    )
  ) +
  labs(
    title = "Mean Lateral Acceleration by Background",
    subtitle = "Participant A | Condition A | Block 1 | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Mean Recorded Lateral Acceleration",
    color = "Background"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

print(background_plot)

ggsave(
  filename = file.path(
    figures_dir,
    "background_acceleration_comparison.png"
  ),
  plot = background_plot,
  width = 11,
  height = 6,
  dpi = 300
)


# -----------------------------------------------------------------------------
# 15. Verify the Supplied Acceleration Measurements
# -----------------------------------------------------------------------------

# Calculate acceleration from the recorded lateral velocity.
acceleration_check <- sample_trial %>%
  arrange(Frame) %>%
  mutate(
    Calculated_AccX = (
      lead(Right_HandVelX) - lag(Right_HandVelX)
    ) / 0.002
  )

# Compare the recorded and calculated acceleration.
acceleration_comparison <- acceleration_check %>%
  filter(
    Time_ms >= -200,
    Time_ms <= 500
  ) %>%
  select(
    Time_ms,
    Right_HandAccX,
    Calculated_AccX
  ) %>%
  pivot_longer(
    cols = c(Right_HandAccX, Calculated_AccX),
    names_to = "Acceleration_Type",
    values_to = "Acceleration"
  )

# Plot both acceleration measurements.
ggplot(
  acceleration_comparison,
  aes(
    x = Time_ms,
    y = Acceleration,
    color = Acceleration_Type
  )
) +
  geom_line(linewidth = 0.5, alpha = 0.8) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "gray40"
  ) +
  scale_color_manual(
    values = c(
      "Right_HandAccX" = "#2563EB",
      "Calculated_AccX" = "#DC2626"
    ),
    labels = c(
      "Right_HandAccX" = "Recorded Acceleration",
      "Calculated_AccX" = "Calculated Acceleration"
    )
  ) +
  labs(
    title = "Recorded vs. Calculated Lateral Acceleration",
    subtitle = "Participant A | Single Trial",
    x = "Time Relative to Pixel Event (ms)",
    y = "Lateral Acceleration (m/s²)",
    color = "Measurement"
  ) +
  theme_minimal(base_size = 13)

# Calculate the correlation between the two measurements.
cor(
  acceleration_check$Right_HandAccX,
  acceleration_check$Calculated_AccX,
  use = "complete.obs"
)


# -----------------------------------------------------------------------------
# 16. Compare Mean Lateral Velocity Across Backgrounds
# -----------------------------------------------------------------------------

# Define a function to import and align lateral velocity.
read_aligned_velocity <- function(file_path) {
  
  trial <- readr::read_csv(
    file_path,
    show_col_types = FALSE
  )
  
  pixel_values <- trial$`Pixel event`
  pixel_values <- pixel_values[!is.na(pixel_values)]
  
  if (length(pixel_values) != 1) {
    return(NULL)
  }
  
  pixel_frame <- pixel_values[1]
  
  trial %>%
    mutate(
      Time_ms = Frame - pixel_frame
    ) %>%
    filter(
      Time_ms >= -200,
      Time_ms <= 500
    ) %>%
    select(
      Time_ms,
      Right_HandVelX
    )
}

# Import and align velocity for the selected trials.
velocity_trials <- purrr::map2_dfr(
  background_comparison$File,
  seq_len(nrow(background_comparison)),
  function(file_path, trial_id) {
    
    trial_data <- read_aligned_velocity(file_path)
    
    if (is.null(trial_data)) {
      return(NULL)
    }
    
    trial_data %>%
      mutate(Trial_ID = trial_id)
  }
)

# Attach the background labels.
velocity_trials <- velocity_trials %>%
  left_join(
    background_comparison %>%
      mutate(Trial_ID = row_number()) %>%
      select(Trial_ID, Background),
    by = "Trial_ID"
  )

# Calculate average lateral velocity for each background.
velocity_summary <- velocity_trials %>%
  group_by(Background, Time_ms) %>%
  summarise(
    Mean_VelX = mean(Right_HandVelX, na.rm = TRUE),
    .groups = "drop"
  )

# Create the comparison graph.
velocity_plot <- ggplot(
  velocity_summary,
  aes(
    x = Time_ms,
    y = Mean_VelX,
    color = Background
  )
) +
  geom_line(linewidth = 1) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "gray40"
  ) +
  geom_hline(
    yintercept = 0,
    color = "gray65"
  ) +
  scale_color_manual(
    values = c(
      "LeftBackground" = "#2563EB",
      "RightBackground" = "#DC2626",
      "StaticBackground" = "#16A34A"
    ),
    labels = c(
      "LeftBackground" = "Left",
      "RightBackground" = "Right",
      "StaticBackground" = "Static"
    )
  ) +
  labs(
    title = "Mean Lateral Velocity by Background",
    subtitle = "Participant A | Condition A | Block 1 | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Mean Lateral Velocity (m/s)",
    color = "Background"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

print(velocity_plot)

# Export for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "background_velocity_comparison.png"
  ),
  plot = velocity_plot,
  width = 11,
  height = 6,
  dpi = 300
)

# -----------------------------------------------------------------------------
# 17. Inspect Trial Event Information
# -----------------------------------------------------------------------------

# Identify the event columns.
event_columns <- c(
  "Command to move FF",
  "Got target",
  "Hand in start",
  "Hand left start (good)",
  "Hand out start (bad)",
  "Missed target",
  "Pixel event",
  "Show hand feedback",
  "Target starts moving"
)

# Display the first 10 rows of event information.
print(
  sample_trial %>%
    select(Frame, all_of(event_columns)) %>%
    head(10),
  width = Inf
)

# Display unique nonmissing values for each event column.
for (column in event_columns) {
  
  cat("\n", column, ":\n")
  
  print(
    unique(
      na.omit(sample_trial[[column]])
    )
  )
}


# -----------------------------------------------------------------------------
# 18. Summarize Trial Outcomes
# -----------------------------------------------------------------------------

# Read the event information from each trial.
trial_outcomes <- trial_info %>%
  mutate(
    Outcome = purrr::map_chr(File, function(file_path) {
      
      trial <- readr::read_csv(
        file_path,
        show_col_types = FALSE
      )
      
      # Check whether a target acquisition or miss was recorded.
      got_target <- any(!is.na(trial$`Got target`))
      missed_target <- any(!is.na(trial$`Missed target`))
      
      # Classify the trial outcome.
      if (got_target && !missed_target) {
        return("Hit")
      } else if (missed_target && !got_target) {
        return("Miss")
      } else if (got_target && missed_target) {
        return("Both recorded")
      } else {
        return("No outcome recorded")
      }
    })
  )

# Count trials by outcome.
outcome_counts <- trial_outcomes %>%
  count(Outcome) %>%
  mutate(
    Percentage = round(100 * n / sum(n), 1)
  )

print(outcome_counts)

# Compare outcomes across participants.
participant_outcomes <- trial_outcomes %>%
  count(Participant, Outcome)

print(participant_outcomes)


# -----------------------------------------------------------------------------
# 19. Compare Hit Rates by Participant and Condition
# -----------------------------------------------------------------------------

# Calculate hit rates for each participant and condition.
condition_outcomes <- trial_outcomes %>%
  group_by(Participant, Condition) %>%
  summarise(
    Total_Trials = n(),
    Hits = sum(Outcome == "Hit"),
    Misses = sum(Outcome == "Miss"),
    Hit_Rate = round(100 * Hits / Total_Trials, 1),
    .groups = "drop"
  )

# Display the results.
print(condition_outcomes)


# -----------------------------------------------------------------------------
# 20. Compare Hit Rates by Target Speed
# -----------------------------------------------------------------------------

# Calculate hit rates for fast and slow targets.
speed_outcomes <- trial_outcomes %>%
  group_by(Target_Speed) %>%
  summarise(
    Total_Trials = n(),
    Hits = sum(Outcome == "Hit"),
    Misses = sum(Outcome == "Miss"),
    Hit_Rate = round(100 * Hits / Total_Trials, 1),
    .groups = "drop"
  )

# Display overall results.
print(speed_outcomes)


# Compare target speed within each participant.
participant_speed_outcomes <- trial_outcomes %>%
  group_by(Participant, Target_Speed) %>%
  summarise(
    Total_Trials = n(),
    Hits = sum(Outcome == "Hit"),
    Misses = sum(Outcome == "Miss"),
    Hit_Rate = round(100 * Hits / Total_Trials, 1),
    .groups = "drop"
  )

# Display participant-specific results.
print(participant_speed_outcomes)


# -----------------------------------------------------------------------------
# 21. Average Lateral Velocity Across All Three Blocks
# -----------------------------------------------------------------------------

# Select Participant A, Condition A, and slow-target trials.
velocity_selection <- trial_info %>%
  filter(
    Participant == "A",
    Condition == "A",
    Target_Speed == "SlowTarget"
  )

# Read and align velocity data from every selected trial.
all_velocity_trials <- purrr::map2_dfr(
  velocity_selection$File,
  seq_len(nrow(velocity_selection)),
  function(file_path, trial_id) {
    
    trial_data <- read_aligned_velocity(file_path)
    
    if (is.null(trial_data)) {
      return(NULL)
    }
    
    trial_data %>%
      mutate(Trial_ID = trial_id)
  }
)

# Attach background information to each trial.
all_velocity_trials <- all_velocity_trials %>%
  left_join(
    velocity_selection %>%
      mutate(Trial_ID = row_number()) %>%
      select(Trial_ID, Background),
    by = "Trial_ID"
  )

# Calculate average velocity at each millisecond.
all_velocity_summary <- all_velocity_trials %>%
  group_by(Background, Time_ms) %>%
  summarise(
    Mean_VelX = mean(Right_HandVelX, na.rm = TRUE),
    .groups = "drop"
  )

# Create the time-series graph.
velocity_plot <- ggplot(
  all_velocity_summary,
  aes(
    x = Time_ms,
    y = Mean_VelX,
    color = Background
  )
) +
  geom_line(linewidth = 1) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "black"
  ) +
  scale_color_manual(
    values = c(
      "LeftBackground" = "#0072B2",
      "RightBackground" = "#D55E00",
      "StaticBackground" = "#009E73"
    ),
    labels = c(
      "LeftBackground" = "Left",
      "RightBackground" = "Right",
      "StaticBackground" = "Static"
    )
  ) +
  labs(
    title = "Average Lateral Hand Velocity Over Time",
    subtitle = "Participant A | Condition A | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Mean Lateral Velocity (m/s)",
    color = "Background"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

# Display the graph.
print(velocity_plot)

# Save a high-resolution image for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "average_lateral_velocity.png"
  ),
  plot = velocity_plot,
  width = 9,
  height = 5,
  dpi = 300
)


# -----------------------------------------------------------------------------
# 22. Individual and Average Lateral Acceleration
# -----------------------------------------------------------------------------

# Select one consistent group of trials.
acceleration_selection <- trial_info %>%
  filter(
    Participant == "A",
    Condition == "A",
    Background == "StaticBackground",
    Target_Speed == "SlowTarget"
  )

# Read and align acceleration for all selected trials.
all_acceleration_trials <- purrr::map2_dfr(
  acceleration_selection$File,
  seq_len(nrow(acceleration_selection)),
  function(file_path, trial_id) {
    
    trial_data <- read_aligned_trial(file_path)
    
    if (is.null(trial_data)) {
      return(NULL)
    }
    
    trial_data %>%
      mutate(Trial_ID = trial_id)
  }
)

# Calculate the average acceleration at each millisecond.
all_acceleration_summary <- all_acceleration_trials %>%
  group_by(Time_ms) %>%
  summarise(
    Mean_AccX = mean(Right_HandAccX, na.rm = TRUE),
    .groups = "drop"
  )

# Plot individual trials and their average.
acceleration_plot <- ggplot() +
  geom_line(
    data = all_acceleration_trials,
    aes(
      x = Time_ms,
      y = Right_HandAccX,
      group = Trial_ID
    ),
    color = "gray75",
    alpha = 0.25,
    linewidth = 0.3
  ) +
  geom_line(
    data = all_acceleration_summary,
    aes(
      x = Time_ms,
      y = Mean_AccX
    ),
    color = "#0072B2",
    linewidth = 1.2
  ) +
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "black"
  ) +
  labs(
    title = "Lateral Hand Acceleration Across Trials",
    subtitle = "Participant A | Condition A | Static Background | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Lateral Acceleration (m/s²)",
    caption = "Gray: Individual Trials | Blue: Mean Acceleration"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Display the graph.
print(acceleration_plot)

# Save the figure for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "individual_and_average_acceleration.png"
  ),
  plot = acceleration_plot,
  width = 9,
  height = 5,
  dpi = 300
)



# -----------------------------------------------------------------------------
# 23. Mean Acceleration and Trial-to-Trial Variability
# -----------------------------------------------------------------------------

# Calculate the mean and standard deviation at each millisecond.
acceleration_variability <- all_acceleration_trials %>%
  group_by(Time_ms) %>%
  summarise(
    Mean_AccX = mean(Right_HandAccX, na.rm = TRUE),
    SD_AccX = sd(Right_HandAccX, na.rm = TRUE),
    .groups = "drop"
  )

# Create the visualization.
acceleration_final_plot <- ggplot(
  acceleration_variability,
  aes(x = Time_ms)
) +
  
  # Shaded region representing mean +/- 1 standard deviation.
  geom_ribbon(
    aes(
      ymin = Mean_AccX - SD_AccX,
      ymax = Mean_AccX + SD_AccX
    ),
    fill = "#0072B2",
    alpha = 0.18
  ) +
  
  # Mean acceleration.
  geom_line(
    aes(y = Mean_AccX),
    color = "#0072B2",
    linewidth = 1
  ) +
  
  # Pixel event reference.
  geom_vline(
    xintercept = 0,
    linetype = "dashed",
    color = "black"
  ) +
  
  # Zero acceleration reference.
  geom_hline(
    yintercept = 0,
    color = "gray50",
    linewidth = 0.4
  ) +
  
  labs(
    title = "Mean Lateral Acceleration and Variability",
    subtitle = "Participant A | Condition A | Static Background | Slow Target",
    x = "Time Relative to Pixel Event (ms)",
    y = "Lateral Acceleration (m/s²)",
    caption = "Blue line: Mean acceleration | Shaded region: +/- 1 standard deviation"
  ) +
  
  theme_minimal(base_size = 13) +
  
  theme(
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

# Display the graph.
print(acceleration_final_plot)

# Save for Google Slides.
ggsave(
  filename = file.path(
    figures_dir,
    "acceleration_final.png"
  ),
  plot = acceleration_final_plot,
  width = 9,
  height = 5,
  dpi = 300
)
