# Debug confidence data extraction
library(dplyr)

cat("=== DEBUGGING CONFIDENCE DATA EXTRACTION ===\n")

# Read raw survey data
raw_data <- read.delim("sep2_completed_utf8.tsv", 
                       sep = "\t", stringsAsFactors = FALSE)

cat("Raw data loaded:", nrow(raw_data), "participants\n")
cat("Raw data columns:", ncol(raw_data), "\n")

# Check for confidence columns
conf_cols <- grep("Confidence", names(raw_data), value = TRUE)
cat("Found", length(conf_cols), "confidence columns:\n")
print(head(conf_cols, 10))

# Check for tendency columns  
tend_cols <- grep("Tendency", names(raw_data), value = TRUE)
cat("Found", length(tend_cols), "tendency columns:\n")
print(head(tend_cols, 10))

# Test extraction for just RAW condition
cat("\n=== TESTING RAW CONDITION EXTRACTION ===\n")

# Function to extract confidence data for one condition (fixed version)
extract_confidence_data_debug <- function(data, condition_name) {
  confidence_cols <- paste0(1:15, "_", condition_name, " Confidence_4")
  tendency_cols <- paste0(1:15, "_", condition_name, " Tendency_1")
  
  cat("Looking for columns like:", confidence_cols[1], "\n")
  cat("Looking for columns like:", tendency_cols[1], "\n")
  
  extracted_rows <- list()
  
  for(i in 1:15) {
    conf_col <- confidence_cols[i]
    tend_col <- tendency_cols[i]
    
    if(conf_col %in% names(data) && tend_col %in% names(data)) {
      
      # Get non-NA rows for this interface
      conf_values <- data[[conf_col]]
      tend_values <- data[[tend_col]]
      
      valid_rows <- !is.na(conf_values) & !is.na(tend_values)
      
      if(sum(valid_rows) > 0) {
        interface_data <- data.frame(
          PROLIFIC_PID = data$PROLIFIC_PID[valid_rows],
          interface = paste0("ui", sprintf("%03d", i)),
          interface_num = i,
          condition = condition_name,
          confidence = as.numeric(conf_values[valid_rows]),
          tendency = as.numeric(tend_values[valid_rows]),
          stringsAsFactors = FALSE
        )
        
        extracted_rows[[length(extracted_rows) + 1]] <- interface_data
        cat("Interface", i, ":", sum(valid_rows), "valid entries\n")
      }
    } else {
      cat("Interface", i, ": columns not found\n")
    }
  }
  
  if(length(extracted_rows) > 0) {
    result <- do.call(rbind, extracted_rows)
    return(result)
  } else {
    return(data.frame())
  }
}

# Test extraction
raw_confidence <- extract_confidence_data_debug(raw_data, "RAW")

cat("Extracted", nrow(raw_confidence), "RAW confidence entries\n")
if(nrow(raw_confidence) > 0) {
  cat("Structure:\n")
  str(raw_confidence)
  cat("First few entries:\n")
  print(head(raw_confidence))
}
