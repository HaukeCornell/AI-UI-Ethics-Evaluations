# Debug version to understand the data structure
library(readr)
library(dplyr)

# Load data
data_raw <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)
data_clean <- data_raw[-c(1:2), ]

# Check the UEQ vs UEEQ assignment
participants_ueq_1 <- !is.na(as.numeric(data_clean$`1_UEQ Tendency_1`))
participants_ueeq_1 <- !is.na(as.numeric(data_clean$`1_UEEQ Tendency_1`))

data_clean$condition <- NA
data_clean$condition[participants_ueq_1 & !participants_ueeq_1] <- "UEQ"
data_clean$condition[participants_ueeq_1 & !participants_ueq_1] <- "UEEQ"

cat("Condition assignment:\n")
table(data_clean$condition, useNA = "always")

# Look at a sample participant from each condition
ueq_sample <- data_clean[data_clean$condition == "UEQ" & !is.na(data_clean$condition), ][1, ]
ueeq_sample <- data_clean[data_clean$condition == "UEEQ" & !is.na(data_clean$condition), ][1, ]

cat("\nUEQ participant sample - interfaces with data:\n")
for (i in 1:15) {
  tendency_col <- paste0(i, "_UEQ Tendency_1")
  if (tendency_col %in% names(ueq_sample)) {
    val <- as.numeric(ueq_sample[[tendency_col]])
    if (!is.na(val)) {
      cat("Interface", i, ":", val, "\n")
    }
  }
}

cat("\nUEEQ participant sample - interfaces with data:\n")
for (i in 1:15) {
  tendency_col <- paste0(i, "_UEEQ Tendency_1")
  if (tendency_col %in% names(ueeq_sample)) {
    val <- as.numeric(ueeq_sample[[tendency_col]])
    if (!is.na(val)) {
      cat("Interface", i, ":", val, "\n")
    }
  }
}

# Check how many interfaces each participant actually completed
ueq_participants <- data_clean[data_clean$condition == "UEQ" & !is.na(data_clean$condition), ]
ueeq_participants <- data_clean[data_clean$condition == "UEEQ" & !is.na(data_clean$condition), ]

cat("\nInterface completion patterns for UEQ participants:\n")
for (i in 1:min(5, nrow(ueq_participants))) {
  participant <- ueq_participants[i, ]
  interfaces_completed <- c()
  for (j in 1:15) {
    tendency_col <- paste0(j, "_UEQ Tendency_1")
    if (tendency_col %in% names(participant)) {
      val <- as.numeric(participant[[tendency_col]])
      if (!is.na(val)) {
        interfaces_completed <- c(interfaces_completed, j)
      }
    }
  }
  cat("Participant", i, "completed interfaces:", paste(interfaces_completed, collapse = ", "), "\n")
}

cat("\nInterface completion patterns for UEEQ participants:\n")
for (i in 1:min(5, nrow(ueeq_participants))) {
  participant <- ueeq_participants[i, ]
  interfaces_completed <- c()
  for (j in 1:15) {
    tendency_col <- paste0(j, "_UEEQ Tendency_1")
    if (tendency_col %in% names(participant)) {
      val <- as.numeric(participant[[tendency_col]])
      if (!is.na(val)) {
        interfaces_completed <- c(interfaces_completed, j)
      }
    }
  }
  cat("Participant", i, "completed interfaces:", paste(interfaces_completed, collapse = ", "), "\n")
}
