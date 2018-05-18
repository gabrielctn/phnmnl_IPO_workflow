#!/usr/bin/env Rscript
options(stringAsfactors = FALSE, useFancyQuotes = FALSE)

# Taking the command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  help.msg <- paste("", "Usage: ./run_ipo_workflow.R study_path=... study_name=... ga_file_template=... output_path=... log_file=... galaxy_url=... galaxy_key=... debug=...",
    "",
    "",
    "Arguments:",
    "",
    "\tstudy_path - local path containing MTBLS studies",
    "",
    "\tstudy_name - name of the study to be processed (e.g. MTBLS404)",
    "",
    "\tga_file_template - Galaxy workflow file for the statistical workflow",
    "",
    "\toutput_path - Local path used to store the result files",
    "",
    "\tlog_file - Path to csv file used for log messages",
    "",
    "\tgalaxy_url - URL to Galaxy server on which to run the workflow",
    "",
    "\tgalaxy_key - API key to access the Galaxy server",
    "",
    "\tdebug - Get debug output from wft4galaxy (true, false) default: false",
    "",
    "\tlogger - Enable logger for wft4galaxy (true, false) default: false",
    "",
    "Description:",
    "",
    paste("\tRuns the IPO worfklow including peak picking step first and then retention time correction and peak grouping steps together, using wft4galaxy.",
      "\tMake sure that wft4galaxy-docker is available on your machine. Visit http://wft4galaxy.readthedocs.io/installation.html#id2 for installation instructions.", "\tThe R package Risa needs to be installed. Visit https://bioconductor.org/packages/release/bioc/html/Risa.html for installation instructions.",
      sep = "\n"
    ),
    "",
    "",
    "Example: ",
    "",
    paste("\t./run_ipo_workflow.r",
      "\t\tstudy_path=\"studies\"",
      "\t\tstudy_name=\"MTBLS404\"",
      "\t\tga_file_template=\"template/ipo_workflow.ga\"",
      "\t\toutput_path=\"output\"",
      "\t\tlog_file=\"MTBLS404_logs.csv\"",
      "\t\tgalaxy_url=\"http://192.168.99.100:30700\"",
      "\t\tgalaxy_key=\"ce30966564d6a42b22f951ca023081ed\"",
      sep = " \\\n"
    ),
    "",
    sep = "\n"
  )
  message(help.msg)
  quit(save = "no", status = 1, runLast = TRUE)
}

study.path <- NA
study.name <- NA
path.to.ga.template <- NA
output <- NA
log.file <- NA
galaxy.url <- NA
galaxy.key <- NA
debug <- ""
logger <- ""

for (arg in args)
{
  argCase <- strsplit(x = arg, split = "=")[[1]][1]
  value <- strsplit(x = arg, split = "=")[[1]][2]
  if (argCase == "study_path") {
    study.path <- as.character(value)
  }
  if (argCase == "study_name") {
    study.name <- as.character(value)
  }
  if (argCase == "ga_file_template") {
    path.to.ga.template <- as.character(value)
  }
  if (argCase == "output_path") {
    output <- as.character(value)
  }
  if (argCase == "log_file") {
    log.file <- as.character(value)
  }
  if (argCase == "galaxy_url") {
    galaxy.url <- as.character(value)
  }
  if (argCase == "galaxy_key") {
    galaxy.key <- as.character(value)
  }
  if (argCase == "debug") {
    cur.val <- as.character(value)
    if (cur.val != "true" && cur.val != "false") stop("debug needs to be 'true' or 'false'!\n")
    if (as.character(value) == "true") debug <- "--debug"
    if (as.character(value) == "false") debug <- ""
  }
  if (argCase == "logger") {
    cur.val <- as.character(value)
    if (cur.val != "true" && cur.val != "false") stop("logger needs to be 'true' or 'false'!\n")
    if (as.character(value) == "true") logger <- "--enable-logger"
    if (as.character(value) == "false") logger <- ""
  }
}

if (is.na(study.path)) stop("study_path needs to be specified!\n")
if (is.na(study.name)) stop("study_name needs to be specified!\n")
if (is.na(path.to.ga.template)) stop("ga_file_template needs to be specified!\n")
if (is.na(output)) stop("output_path needs to be specified!\n")
if (is.na(log.file)) stop("log_file needs to be specified!\n")
if (is.na(galaxy.url)) stop("galaxy_url needs to be specified!\n")
if (is.na(galaxy.key)) stop("galaxy_key needs to be specified!\n")

if (!dir.exists(study.path)) stop(paste("Directory path for study_path (", study.path, ")", "not found.", sep = " "))
if (!dir.exists(paste(study.path, study.name, sep = "/"))) stop(paste("Study", study.name, "in", study.path, "not found. Check value of study_name.", sep = " "))
if (!dir.exists(output)) stop(paste("Directory path for output_path (", output, ")", "not found.", sep = " "))
if (!file.exists(path.to.ga.template)) stop(paste("File path for ga_file_template (", path.to.ga.template, ")", "not found.", sep = " "))
if (Sys.which("docker") == "") stop("Docker seems not to be installed.")
if (system("wft4galaxy-docker --help", ignore.stdout = T, ignore.stderr = T) != 0) stop("The docker image for wft4galaxy-docker is not installed. Visit http://wft4galaxy.readthedocs.io/installation.html#id2 for instructions.")

library(Risa)
library(R.utils)

delete.dirs <- F

# do not modify this unless you know what you are doing
wft4galaxy.template.yaml <- paste("enable_logger: False
output_folder: \"results\"
# workflow tests
workflows:
    ipo:
        file: \"ipo_workflow.ga\"
        inputs:
            \"input_ipo\": \"MZDATA\"
            \"sampleMetadata\": \"sample-output.tsv\"
        expected:
            resultPeakpicking.RData: 
                file: \"expected/resultPeakpicking.RData\"
                comparator: \"simple_comp.always_true_cmp\"
            best_xcmsSet.RData: 
                file: \"expected/best_xcmsSet.RData\"
                comparator: \"simple_comp.always_true_cmp\"
            IPO_parameters4xcmsSet.tsv: 
                file: \"expected/IPO_parameters4xcmsSet.tsv\"
                comparator: \"simple_comp.always_true_cmp\"
            run_instrument_infos.tsv: 
                file: \"expected/run_instrument_infos.tsv\"
                comparator: \"simple_comp.always_true_cmp\"
            ipo4xcmsSet.log.txt: 
                file: \"expected/ipo4xcmsSet.log.txt\"
                comparator: \"simple_comp.always_true_cmp\"
            ipo4retcor.log.txt: 
                file: \"expected/ipo4retcor.log.txt\"
                comparator: \"simple_comp.always_true_cmp\"
            IPO_parameters4retcorGroup.tsv: 
                file: \"expected/IPO_parameters4retcorGroup.tsv\"
                comparator: \"simple_comp.always_true_cmp\"", sep = "")



# retrieve modified factor name
get.factor.name <- function(sample.file, variable.name) {
  data <- read.table(sample.file, header = T)
  regex.column.name <- paste(gsub("$", ".*", gsub("\\s+", ".*", variable.name)), "$", sep = "")
  found.indexes <- grep(regex.column.name, colnames(data))
  return(colnames(data)[found.indexes])
}

# checks whether assay file is MS type
check.assay.file <- function(assay.file) {
  data <- read.csv(assay.file, sep = "\t")
  return(any(colnames(data) == "MS.Assay.Name"))
}

# Function to build the study's assay folder(s) containing
# QCs or pools if any (+blanks), or other mzfiles otherwise (5% but at least 10 mzfiles).
prepare.mz.files <- function(data, assay, assay.folder, study.path, study.name, study.output.folder, real.factors) {
  path.to.files <- paste(study.path, study.name, sep = "/")
  # get the mz files associated to the current assay
  files <- paste(path.to.files, data["assay.files"][[assay]][["Raw Spectral Data File"]], sep = "/")
  files.to.keep <- NULL

  # Link mz files to their factors in a matrix
  # If there is a problem with factors, keep all files
  if (length(which(real.factors == "-1")) == 0) {
    factors.matrix <- sapply(data["factors"][[1]], function(x) cbind(as.matrix(x)))
    # Check that a factor was attributed to each file, otherwise skip this step
    if (length(as.matrix(data["assay.files"][[assay]][["Raw Spectral Data File"]])) == length(factors.matrix[, 1])) {
      factors.mzfile.matrix <- cbind(factors.matrix[1:length(files), ], as.matrix(data["assay.files"][[assay]][["Raw Spectral Data File"]]))
      # Keep at least 1 mzfile for each combination of factors (if several) or per factor (if no combination)
      files.to.keep <- factors.mzfile.matrix[, ncol(factors.mzfile.matrix[!duplicated(factors.mzfile.matrix[, 1:length(real.factors)]), ])]
      files.to.keep <- paste(path.to.files, files.to.keep, sep = "/")
    } else {
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"", "\",", "\"",
        paste("Warning : Each mz file must have a factor attributed. mz files will be picked regardless of factors : ", sep = ""), "\",", "\"", "", "\"",
        sep = ""
      ),
      file = log.file, append = TRUE
      )
      files.to.keep <- files
    }
  } else {
    write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"", "\",", "\"",
      paste("Error : Did not find factor column in s_file: ", sep = ""), "\",", "\"", "", "\"",
      sep = ""
    ),
    file = log.file, append = TRUE
    )
    files.to.keep <- files
  }
  # Some studies have zipped mz files
  if (unique(grepl("^.*(\\.gz|\\.tar|\\.zip)[[:space:]]*$", files.to.keep))) {
    if (unique(tools::file_ext(files.to.keep)) == "gz") {
      sapply(files.to.keep, function(x) gunzip(filename = x))
    } else if (unique(tools::file_ext(files.to.keep)) == "tar") {
      sapply(files.to.keep, untar(exdir = path.to.files))
    } else if (unique(tools::file_ext(files.to.keep)) == "zip") {
      sapply(files.to.keep, unzip(exdir = path.to.files))
    }
    files.to.keep <- gsub(".gz", "", files.to.keep)
  }
  # Check if there are blank files
  # TODO Change the method retrieving blank samples, with a more "official way" then "grep"
  #      - To improve in the future, when new specifications of ISA-Tab make it easier to detect blanks
  blank.files <- grep("blan(k|c)", files.to.keep, ignore.case = TRUE, value = TRUE)
  # Keep only QCs and/or pool files if possible since they are more representative of the experimental study
  representative.files <- grep("(QC)|(pool)", files.to.keep, ignore.case = TRUE, value = TRUE)
  if (length(representative.files) != 0) { # If pools or QC, keep only them
    file.copy(representative.files, assay.folder)
    if (length(blank.files) != 0) { # Keep also blanks if there are
      file.copy(blank.files, assay.folder)
    }
  } else {
    # To reduce processing time, keep 5% but at least 10 raw data files of the assay
    if (length(files.to.keep) < 10) {
      file.copy(files.to.keep, assay.folder)
    } else if (ceiling((5 * length(files.to.keep)) / 100) < 10) {
      file.copy(sample(files.to.keep, 10), assay.folder)
    } else {
      file.copy(sample(files.to.keep, ceiling((5 * length(files.to.keep)) / 100)), assay.folder)
    }
  }
  main.dir <- getwd()
  setwd(assay.folder)
  assay.zip.name <- gsub("\\.txt$", ".zip", gsub(" ", "_", assay))
  # Create zip file from the assay folder
  if (!file.exists(assay.zip.name)) {
    files <- intersect(basename(files.to.keep), basename(dir(full.names = TRUE)))
    zip(zipfile = assay.zip.name, files = files)
  }
  setwd(main.dir)
  return(paste(assay.folder, assay.zip.name, sep = "/"))
}



# generate wft4galaxy files
prepare.wft4galaxy.files <- function(path.to.zipfile, study.output.folder, assay.folder, wft4galaxy.template.yaml, path.to.ga.template) {
  # create neccessary folders
  # folder for storing expected results
  dir.create(paste(assay.folder, "expected", sep = "/"))
  # folder for storing results
  dir.create(paste(assay.folder, "results", sep = "/"))
  # prepare and write yaml file
  wft4galaxy.template.yaml.tmp <- gsub("MZDATA", basename(path.to.zipfile), wft4galaxy.template.yaml)
  # write yaml file
  write(wft4galaxy.template.yaml.tmp, file = paste(assay.folder, "workflow.yaml", sep = "/"))
  # create expected results
  # ipo4xcmsSet results
  file.create(paste(assay.folder, "expected/resultPeakpicking.RData", sep = "/"))
  file.create(paste(assay.folder, "expected/best_xcmsSet.RData", sep = "/"))
  file.create(paste(assay.folder, "expected/IPO_parameters4xcmsSet.tsv", sep = "/"))
  file.create(paste(assay.folder, "expected/run_instrument_infos.tsv", sep = "/"))
  file.create(paste(assay.folder, "expected/ipo4xcmsSet.log.txt", sep = "/"))
  # ipo4retgroup results
  file.create(paste(assay.folder, "expected/IPO_parameters4retcorGroup.tsv", sep = "/"))
  file.create(paste(assay.folder, "expected/ipo4retcor.log.txt", sep = "/"))
  # copy
  file.copy(path.to.ga.template, assay.folder)
}

run.wft4galaxy <- function(assay.folder, galaxy.key, galaxy.url) {
  # FOR TESTING ON MINIKUBE: Because on kubernetes the path "home" is mounted as "hosthome" in the VM
  current.folder <- getwd()
  # current.folder <- gsub("home", "hosthome", getwd())
  setwd(assay.folder)
  # FOR TESTING ON MINIKUBE: Because on kubernetes the path "home" is mounted as "hosthome" in the VM
  working.folder <- getwd()
  # working.folder <- gsub("home", "hosthome", getwd())
  command <- paste(
    "docker run --rm -v ", current.folder, "/python/:/python -v ", working.folder, ":/data_input/ -v ", working.folder, ":/data_output/ ",
    "-e PYTHONPATH=/python -e GALAXY_URL=", galaxy.url, " -e GALAXY_API_KEY=", galaxy.key,
    " crs4/wft4galaxy:latest runtest ", debug, " --server ", galaxy.url, " --api-key ", galaxy.key, " -f /data_input/workflow.yaml ",
    logger, " -o /data_output/results --disable-cleanup --output-format text",
    sep = ""
  )
  system(command)
  # setwd(gsub("hosthome", "home", current.folder))
  setwd(current.folder)
}

# check whether wft4galaxy run was successful
# otherwise return the error message
validate.wft4galaxy.run <- function(study.output.folder, assay.folder, galaxy.url) {
  # get results folder
  result.folder.name <- paste(study.output.folder, "results", sep = "/")
  # search for log file
  log.file.index <- grep("\\.log$", dir(result.folder.name))
  if (length(log.file.index) != 0) {
    # check for error message
    lines <- readLines(paste(result.folder.name, dir(result.folder.name)[log.file.index], sep = "/"))
    error.indexes <- grep("Runtime error:", lines)
    if (length(error.indexes) != 0) {
      # get first run id
      run.id <- gsub("\\s.*", "", gsub(".*Runtime error:\\s*", "", lines[error.indexes[1]]))
      download.result <- paste(study.output.folder, "results", run.id, sep = "/")
      url <- paste(galaxy.url, "/dataset/errors?id=", run.id, sep = "")
      download.file(url, download.result, quiet = TRUE)
      if (file.exists(download.result)) {
        lines <- readLines(download.result)
        # search for error messages
        error.started <- FALSE
        error.message <- ""
        for (i in 1:length(lines)) {
          # check if error starts or ends
          if (grepl("^====", lines[i])) {
            if (!error.started) {
              error.started <- TRUE
            } else {
              error.started <- FALSE
              return(paste("Error 9: Galaxy workflow error.", error.message))
            }
          } else if (error.started & lines[i] != "") {
            current.message <- paste(unlist(strsplit(lines[i], c(" ")))[-1], collapse = " ")
            current.message <- gsub("^\\s*", " ", current.message)
            if (error.message == "") {
              error.message <- current.message
            } else {
              error.message <- paste(error.message, current.message, sep = ";")
            }
          }
        }
      } else {
        return(paste("Error 10: Could not download error file from", url))
      }
    }
  }
  result.files <- dir(paste(assay.folder, "results", "ipo", sep = "/"))
  if (length(result.files) != 7) {
    return(paste("Error 11: Unknown error. Expected 7 output files in", paste(assay.folder, "results", "ipo", sep = "/"), ". Found ", length(result.files)))
  }
  return("")
}
# main function does the job
main <- function(study.name, log.file, study.path, wft4galaxy.template.yaml, path.to.ga.template, galaxy.key, galaxy.url, output, delete.dirs = TRUE) {
  path <- paste(study.path, study.name, sep = "/")

  # read study
  data <- tryCatch({
    readISAtab(path)
  }, warning = function(w) {

  }, error = function(e) {
    write(paste("\"", study.name, "\",", "\"\",", "\"\",", "\"", paste("Error 1: Could not read ISAtab folder properly.", sep = ""), "\",", "\"", "", "\"", sep = ""), file = log.file, append = TRUE)
    return()
  }, finally = {

  })
  if (is.null(data)) {
    write(paste("\"", study.name, "\",", "\"\",", "\"\",", "\"", paste("Error 1: Could not read ISAtab folder properly.", sep = ""), "\",", "\"", "", "\"", sep = ""), file = log.file, append = TRUE)
    return()
  }

  # get properties from investigation file
  study.factor.name.index <- grep("Study Factor Name", as.character(attributes(data)[["investigation.file"]][, 1]))
  study.file.name.index <- grep("Study File Name", as.character(attributes(data)[["investigation.file"]][, 1]))
  assay.file.name.index <- grep("Study Assay File Name", as.character(attributes(data)[["investigation.file"]][, 1]))

  # get study files
  s_files <- list()
  a <- sapply(attributes(data)[["investigation.file"]][study.file.name.index, -1], function(x) {
    current.s_file <- as.character(x)
    if (!is.na(current.s_file) & current.s_file != "") {
      s_files[[length(s_files) + 1]] <<- current.s_file
    }
  })
  s_files <- unlist(s_files)
  if (length(s_files) > 1) {
    write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"", "\",", "\"", paste("Error 2: More than one s_file found", sep = ""), "\",", "\"", "", "\"", sep = ""), file = log.file, append = TRUE)
    return()
  }

  # collect factors
  factors <- list()
  a <- sapply(attributes(data)[["investigation.file"]][study.factor.name.index, -1], function(x) {
    current.factor <- as.character(x)
    if (!is.na(current.factor) & current.factor != "") {
      factors[[length(factors) + 1]] <<- current.factor
    }
  })
  factors <- unlist(factors)
  if (is.null(factors)) {
    write(paste("\"", study.name, "\",", "\"\",", "\"\",", "\"", paste("Error 2: No factors found in investigation file.", sep = ""), "\",", "\"", "", "\"", sep = ""), file = log.file, append = TRUE)
    # return()
  }

  # get assays
  assays <- list()
  a <- sapply(attributes(data)[["investigation.file"]][assay.file.name.index, -1], function(x) {
    current.assay <- as.character(x)
    if (!is.na(current.assay) & current.assay != "") {
      assays[[length(assays) + 1]] <<- current.assay
    }
  })
  assays <- unlist(assays)

  # get real factor names
  s_file_data <- read.csv(paste(path, s_files[1], sep = "/"), sep = "\t", check.names = F)
  real.factors.index <- sapply(factors, function(x) grep(paste("\\[", x, "\\]", sep = ""), colnames(s_file_data)))
  real.factors <- list()
  a <- sapply(real.factors.index, function(x) {
    # if not found in the s file
    if (length(x) == 0) {
      real.factors[[length(real.factors) + 1]] <<- -1
    } else {
      real.factors[[length(real.factors) + 1]] <<- colnames(s_file_data)[x]
    }
  })
  real.factors <- unlist(real.factors)

  # get study folder for the current MTBLS study
  study.output.folder <- paste(output, study.name, sep = "/")
  # remove if the current study folder already exists
  if (dir.exists(study.output.folder)) {
    unlink(study.output.folder, recursive = TRUE)
  }
  # create study folder for the current MTBLS study
  dir.create(study.output.folder)

  for (assay in assays) {
    is.valid.ms <- check.assay.file(paste(path, assay, sep = "/"))
    if (!is.valid.ms) {
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"\",", "\"",
        paste("Error 4: ", assay, " is no MS study.", sep = ""), "\",", "\"", "", "\"",
        sep = ""
      ),
      file = log.file, append = TRUE
      )
      next
    }
    # Skip if the assay has raw files
    if (any(grepl("^.*\\.raw[[:space:]]*$", data["assay.files"][[assay]][["Raw Spectral Data File"]], ignore.case = TRUE) == TRUE)) {
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"\",", "\"",
        paste("Error 4: skipping ", assay, " assay, raw files are not treated", sep = ""), "\",", "\"", "", "\"",
        sep = ""
      ),
      file = log.file, append = TRUE
      )
      next
    }
    if(any(grepl("FALSE", file.exists(paste(path, data["assay.files"][[assay]][["Raw Spectral Data File"]], sep = "/"))) == TRUE)){
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"\",", "\"",
        paste("Error 4: skipping ", assay, " assay, no ms files found for this assay", sep = ""), "\",", "\"", "", "\"",
        sep = ""
      ),
      file = log.file, append = TRUE
      )
      next
    }
    assay.folder <- gsub(" ", "_", paste(study.output.folder, gsub("\\.txt$", "", assay), sep = "/"))
    dir.create(assay.folder)
    ### Create W4M files. We use only the sample file but all are kept
    # define output files
    sample.file <- paste(assay.folder, "sample-output.tsv", sep = "/")
    variable.file <- paste(assay.folder, "variable-output.tsv", sep = "/")
    matrix.file <- paste(assay.folder, "matrix-output.tsv", sep = "/")
    path.to.isa <- paste(study.path, study.name, sep = "/")
    # run script to generate input files
    command <-
      paste(
        "docker run -v ", getwd(), "/:/isa_files/ container-registry.phenomenal-h2020.eu/phnmnl/isa2w4m",
        " -i /isa_files/", path.to.isa,
        " -s /isa_files/", sample.file,
        " -v /isa_files/", variable.file,
        " -m /isa_files/", matrix.file,
        " -f '", assay, "'",
        sep = ""
      )
    # run the command
    system(command)
    # check if successful
    # variable success contains empty string if
    if (!file.exists(sample.file) || !file.exists(variable.file) || !file.exists(matrix.file)) {
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"", "\",", "\"Error 5: Problem when creating input files with isatab2w4m script\",", "\"", command, "\"", sep = ""),
            file = log.file, append = TRUE
      )
      unlink(assay.folder, recursive = TRUE)
      next
    }
    # prepare wft4galaxy
    path.to.zipfile <- prepare.mz.files(data, assay, assay.folder, study.path, study.name, study.output.folder, real.factors)
    prepare.wft4galaxy.files(path.to.zipfile, study.output.folder, assay.folder, wft4galaxy.template.yaml, path.to.ga.template)
    ######## Run the workflow ########
    ##################################
    run.wft4galaxy(assay.folder, galaxy.key, galaxy.url)
    success <- validate.wft4galaxy.run(study.output.folder, assay.folder, galaxy.url)
    if (success != "") {
      write(paste("\"", study.name, "\",", "\"", assay, "\",", "\"", assay.folder, "\",", "\"", success, "\",", "\"", command, "\"", sep = ""), file = log.file, append = TRUE)
      # better to not delete the current folder as the wft4galaxy files might be interesting for further analysis
      # unlink(factor.folder, recursive = T)
    }
    # remove assay folder if empty
    if (length(dir(assay.folder)) == 0) {
      if (delete.dirs) {
        unlink(assay.folder, recursive = TRUE)
      }
    } else { # Delete heavy zip file. The names of files used for processing are written in output files anyway
      unlink(path.to.zipfile, force = TRUE)
    }
  }
  # remove study folder if empty
  if (length(dir(study.output.folder)) == 0) {
    if (delete.dirs) {
      unlink(study.output.folder, recursive = TRUE)
    }
  }
}


# run the command
main(study.name, log.file, study.path, wft4galaxy.template.yaml, path.to.ga.template, galaxy.key, galaxy.url, output, FALSE)
