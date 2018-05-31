#!/usr/bin/env Rscript


###
### This script is analysing the results from IPO workflow.
### Keeping in mind that the workflow is optimizing only a set of parameters,
### not all of them at once.
### The PCA at the end makes sense only if all the parameters have been optimized
###


# Get MTBLS studies folders
mtbls.dirs <- list.dirs("./output", recursive = FALSE)

# Read run_instrument_infos.tsv
read_RI_file <- function(study, assay, result.files) {
  RI.file <- try(read.table(grep("results/ipo/run_instrument_infos.tsv", result.files, value = TRUE), header = TRUE, sep = "\t", stringsAsFactors = FALSE), silent = TRUE)
  if (inherits(RI.file, "try-error")) {
    message("Study: ", basename(study), " | Assay: ", assay, "\nCaught an error while reading run_instrument_infos.tsv file. Skipping to next assay or study...")
    message("Original error message: ", geterrmessage())
    return(data.frame())
  }
  return(as.data.frame(RI.file))
}


# Compile results for an assay of a study
# Fills 3 dataframes with all results and returns "success" or ""
compile.results <- function(study, assay, result.files, study.assay.name) {
  # run and instrument informations.
  # netCDF studies have sometimes problems with this file because of mzR::runInfo() and mzR::instrumentInfo()
  RI.file <- read_RI_file(study, assay, result.files)
  comment(RI.file) <- study.assay.name
  # Peak picking parameters
  param.4.xcmsSet <- try(read.table(grep("results/ipo/IPO_parameters4xcmsSet.tsv", result.files, value = TRUE), sep = "\t", row.names = 1, stringsAsFactors = FALSE), silent = TRUE)
  if (inherits(param.4.xcmsSet, "try-error")) {
    message("Study: ", basename(study), " | Assay: ", assay, "\nCaught an error while reading IPO_parameters4xcmsSet.tsv file. Skipping to next assay or study...")
    message("Original error message: ", geterrmessage())
    return ("")
  }
  PP.parameters <- as.data.frame(t(param.4.xcmsSet))
  comment(PP.parameters) <- study.assay.name
  # PPS
  result.peakpicking.rdata.file <- grep("results/ipo/resultPeakpicking.RData", result.files, value = TRUE)
  load(result.peakpicking.rdata.file)
  PP.parameters[["PPS"]] <- resultPeakpicking$best_settings$result[["PPS"]]
  rm(result.peakpicking.rdata.file)
  # Retention time + grouping parameters
  RG.parameters <- as.data.frame(t(read.table(grep("results/ipo/IPO_parameters4retcorGroup.tsv", result.files, value = TRUE), sep = "\t", row.names = 1, stringsAsFactors = FALSE)))
  comment(RG.parameters) <- study.assay.name

  infos[[study.assay.name]] <<- RI.file
  all.PP.parameters[[study.assay.name]] <<- PP.parameters
  all.RG.parameters[[study.assay.name]] <<- RG.parameters
  return ("success")
}


infos <- list()
all.PP.parameters <- list()
all.RG.parameters <- list()

# Loop over every MTBLS study (folders) to get result files
for (study in mtbls.dirs) {
  cat("Processing study: ", study, "\n")
  # If the workflow for this study went fine
  if (length(dir(study)) != 0) {
    # Check if several assays
    assays <- list.dirs(study, recursive = FALSE)
    if (length(assays) > 1) {
      for (i in 1:length(assays)) {
        study.assay.name <- paste0(basename(study), "_", i)
        # All result files from the current study's assay
        result.files <- list.files(assays[i], recursive = TRUE, full.names = TRUE)
        if (length(result.files) != 0) {
          res <- compile.results(study, assays[i], result.files, study.assay.name)
          if(res == ""){
            break
          }
        }
      }
    } else { # Only one assay
      study.assay.name <- basename(study)
      # All result files from the current study
      result.files <- list.files(study, recursive = TRUE, full.names = TRUE)
      if (length(result.files) != 0) {
        compile.results(study, assays, result.files, study.assay.name)
      }
    }
  } else {
    cat("The folder of study ", study, " is empty\n")
  }
}



# Plot interesting things -------------------------------------------------

# Install and load libraries
############################

# Install required packages if not present
list.of.packages <- c("ggplot2", "dplyr", "FactoMineR", "factoextra", "explor")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages) != 0) {
  install.packages(new.packages)
}

# Load
library(ggplot2)
library(dplyr)
library(FactoMineR)
library(factoextra)
library(explor)


# Create directory for resulting plots
if(!dir.exists("./plots")){
  dir.create("./plots")
}

################################################################
# Peakpicking: Optimized peak width accross Metabolights studies
################################################################

# Prepare dataframe
df <- NULL
for (study in all.PP.parameters) {
  min <- c(comment(study), "min_peakwidth", as.numeric(levels(study$min_peakwidth)[study$min_peakwidth]))
  max <- c(comment(study), "max_peakwidth", as.numeric(levels(study$max_peakwidth)[study$max_peakwidth]))
  df <- rbind(df, min, max)
}
colnames(df) <- c("Studies", "Peak_Width", "Value")
rownames(df) <- NULL
df <- as.data.frame(df)


# Generate grouped bar plot of peak width accross Metabolights studies
ggplot(df, aes(x = Studies, y = Value, fill = factor(Peak_Width))) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_text(aes(label = Value), vjust = 1.6, color = "white", position = position_dodge(0.9), size = 3.5) +
  labs(title = "Optimized peak width parameter accross Metabolights studies", x = "StudyID_assayNumber", y = "Peak width (in seconds)") +
  scale_fill_discrete(name = "Peak Width", labels = c("Max", "Min")) + 
  theme(axis.text.x = element_text(face="bold", color="#993333", size=14,angle = 45, hjust = 1),
        axis.text.y = element_text(size=14, hjust = 1))


# Save plot in ./plots
ggsave("./plots/peak_width_accross_studies.pdf")


#########################################################
# Peakpicking: Optimized peak width accross manufacturers
#########################################################

# Prepare dataframe
df <- NULL
for (study in all.PP.parameters) {
  if(length(infos[[comment(study)]]) != 0){
    min <- c(comment(study), unique(infos[[comment(study)]]$manufacturer), "min_peakwidth", as.numeric(levels(study$min_peakwidth)[study$min_peakwidth]))
    max <- c(comment(study), unique(infos[[comment(study)]]$manufacturer), "max_peakwidth", as.numeric(levels(study$max_peakwidth)[study$max_peakwidth]))
    df <- rbind(df, min, max)
  }
}
colnames(df) <- c("Study","Manufacturer", "Peak_Width", "Value")
rownames(df) <- NULL
df <- as.data.frame(df)


# Generate grouped bar plot of peak width accross manufacturers
ggplot(df, aes(x = Manufacturer, y = Value, fill = factor(Study))) +
  geom_col(colour="black", size=.2, position=position_dodge()) +
  geom_text(aes(label = Value), vjust = 1.6, color = "black", position = position_dodge(0.9), size = 3.5) +
  labs(title = "Optimized peak width parameter accross manufacturers", x = "Manufacturers", y = "Peak width (in seconds)") +
  scale_fill_brewer(name = "Studies", labels = unique(df$Study), palette = "Set2") +
  theme(axis.text.x = element_text(face="bold", color="#993333", size=14), 
        axis.text.y = element_blank())
# Save plot in ./plots
ggsave("./plots/peak_width_accross_manufacturers.pdf")




##################################################
# Peakpicking: Optimized peak width accross models
##################################################

# Prepare dataframe
df <- NULL
for (study in all.PP.parameters) {
  if(length(infos[[comment(study)]]) != 0){
    min <- c(comment(study), unique(infos[[comment(study)]]$model), "min_peakwidth", as.numeric(levels(study$min_peakwidth)[study$min_peakwidth]))
    max <- c(comment(study), unique(infos[[comment(study)]]$model), "max_peakwidth", as.numeric(levels(study$max_peakwidth)[study$max_peakwidth]))
    df <- rbind(df, min, max)
  }
}
colnames(df) <- c("Study","Models", "Peak_Width", "Value")
rownames(df) <- NULL
df <- as.data.frame(df)
df$Value <- as.numeric(as.character(df$Value))

# Generate grouped bar plot of peak width accross models
ggplot(df, aes(x = interaction(Models,Study), y = Value, fill = factor(Study))) +
  geom_col(data = df[df$Peak_Width=="max_peakwidth",],colour="black", size=.2, position=position_dodge()) +
  geom_col(data = df[df$Peak_Width=="min_peakwidth",], colour="black", size=.2, position=position_dodge()) +
  facet_grid(~Models, scales = "free_x", space = "free_x") +
  geom_text(aes(label = Value), vjust = 1.6, color = "black", position = position_dodge(0.9), size = 3.5) +
  labs(title = "Optimized min/max peak width parameter accross LC/MS instrument models", x = "", y = "Min/Max Peak width (in seconds)") +
  scale_fill_brewer(name = "Studies_assay", labels = unique(df$Study), palette = "Set2") +
  theme(axis.text.x = element_blank(), axis.ticks.x=element_blank())

# Save plot in ./plots
ggsave("./plots/peak_width_accross_models.pdf")



#########################################################
# Retcor group: optimized bw accross Metabolights studies
#########################################################

# Prepare dataframe
df <- NULL
for (study in all.RG.parameters) {
  bw <- c(comment(study), "Bandwidth", as.numeric(levels(study$bw)[study$bw]))
  df <- rbind(df, bw)
}
colnames(df) <- c("Studies", "Bandwidth", "Value")
rownames(df) <- NULL
df <- as.data.frame(df)


# Generate bar plot of bandwidth accross Metabolights studies
ggplot(df, aes(x = Studies, y = Value)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = Value), vjust = 1.6, color = "white", position = position_dodge(0.9), size = 3.5) +
  labs(title = "Bandwidth parameter accross Metabolights studies", x = "StudyID_assayNumber", y = "Bandwidth\n Standard deviation of gaussian smoothing kernel\n to apply to peak density chromatogram") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Save plot in ./plots
ggsave("./plots/band_width_accross_studies.pdf")





###########################################
# Retcor group: optimized bw accross models
###########################################

# Prepare dataframe
df <- NULL
for (study in all.RG.parameters) {
  if(length(infos[[comment(study)]]) != 0){
    bw <- c(comment(study), unique(infos[[comment(study)]]$model), "Bandwidth", as.numeric(levels(study$bw)[study$bw]))
    df <- rbind(df, bw)
  }
}
colnames(df) <- c("Study","Models", "Bandwidth", "Value")
rownames(df) <- NULL
df <- as.data.frame(df)
df$Value <- as.numeric(as.character(df$Value))


# Generate bar plot of bandwidth accross Metabolights studies
ggplot(df, aes(x = interaction(Models,Study), y = Value, fill = factor(Study))) +
  geom_col(colour="black", size=.2, position=position_dodge()) +
  facet_grid(~Models, scales = "free_x", space = "free_x") +
  geom_text(aes(label = Value), vjust = 1.6, color = "black", position = position_dodge(0.9), size = 3.5) +
  labs(title = "Optimized bandwidth parameter accross instrument models", x = "", y = "Bandwidth\n Standard deviation of gaussian smoothing kernel\n to apply to peak density chromatogram") + 
  scale_fill_brewer(name = "Studies", labels = unique(df$Study), palette = "Set2") +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_text(face="bold", color="#993333", size=14),
        axis.ticks.x=element_blank())

# Save plot in ./plots
ggsave("./plots/band_width_accross_models.pdf")




##############################################################
# PCA:
#      - Preparing data: Combines all peak picking parameters
#        together with PPS as the last column.
#      - Execute this PCA only with all parameters optimized,
#        since currently the IPO workflow optimises only a set
#        of parameters, so the PCA would not take into account
#        all the parameters.
##############################################################

# Prepare the data frame for PCA
X <- do.call("rbind", all.PP.parameters)
X[, 1:9] <- mutate_all(X[, 1:9], function(x) as.numeric(as.character(x)))
X <- X[, -c(10:11)]

# Run PCA
dt.pca <- PCA(X[, -10], scale.unit = TRUE, graph = FALSE)

# Explore PCA with shiny app
explor(dt.pca)
# print(dt.pca)

# Generate the resulting graph of the variables
# You can also generate the code of the graph you want,
# directly from the explor shiny app
res <- explor::prepare_results(dt.pca)
explor::PCA_var_plot(res,
  xax = 1, yax = 2,
  var_sup = FALSE, var_lab_min_contrib = 0,
  col_var = NULL, labels_size = 10, scale_unit = TRUE,
  labels("CP", "CP"),
  transitions = TRUE, labels_positions = NULL,
  xlim = c(-1.1, 1.1), ylim = c(-1.1, 1.1)
)

# Get eigen values
eig.val <- get_eigenvalue(dt.pca)

# Scree plot: percentage of explained variance by plotting eigen values
fviz_eig(dt.pca, addlabels = TRUE, ylim = c(0, 100))

# Contributions of variables at PC1
fviz_contrib(dt.pca, choice = "var", axes = 1, top = 10)
# Contributions of variables at PC2
fviz_contrib(dt.pca, choice = "var", axes = 2, top = 10)
