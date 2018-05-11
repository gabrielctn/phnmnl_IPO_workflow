# phnmnl_IPO_workflow
Optimize XCMS analytical parameters by running IPO workflow (Peak picking + Retention time correction and grouping optimization) on Metabolights studies within the PhenoMeNal EU project.

## Description
Runs the IPO tool that includes as a 2 steps workflow the peak picking step first and then retention time correction and peak grouping optimization steps together, using wft4galaxy api. The workflow can process one (scripts/run_ipo_workflow.R) or several (scripts/run_ipo_on_several_studies.sh) Metabolights studies (http://www.ebi.ac.uk/metabolights/) using wft4galaxy (http://wft4galaxy.readthedocs.io) as an API accessing a Galaxy instance with an installed PhenoMeNal e-infrastructure.
This script processes all assays separately and picks files within assays according to factors found in the investigation file of the given study, in order to represent all combinations of factors that exist.

## Requirements
Docker  
Make sure that wft4galaxy-docker is available on your machine.  
Visit http://wft4galaxy.readthedocs.io/installation.html#id2 for installation instructions.  
The R package Risa needs to be installed.  
Visit https://bioconductor.org/packages/release/bioc/html/Risa.html for installation instructions.  

Prepare the working environment.  
The working directory should look like:  
```
work_dir
    |_ output (to build)  
    |_ studies  
    |      |_ MTBLS213  
    |_ template  
    |      |_ baseline_ipo.ga  
    |      |_ ipo_workflow.ga  
    |_ python  
    |      |_ simple_comp.py  
    |_ scripts   
	     |_ run_ipo_workflow.R  
         |_ run_ipo_on_several_studies.sh
```

**Arguments**  
study_path - Local path containing MTBLS studies  
study_name - Name of the study to be processed (e.g. MTBLS433)  
ga_file_template - Galaxy workflow file (.ga) for the statistical workflow  
output_path - Local path used to store the result files   
log_file - Path to csv file used for log messages  
galaxy_url - URL to Galaxy server on which to run the workflow  
galaxy_key - API key to access the Galaxy server  
debug - Get debug output from wft4galaxy (true, false) default: false  
logger - Enable logger for wft4galaxy (true, false) default: false  


## Usage
Run the script without any argument to display help message.
./run_ipo_workflow.r

## Example
```
./run_ipo_workflow.r
      study_path="studies"
      study_name="MTBLS404"
      ga_file_template="template/ipo_workflow.ga"
      output_path="output"
      log_file="MTBLS404_logs.csv"
      galaxy_url="http://192.168.99.100:30700"
      galaxy_key="ce30966564d6a42b22f951ca023081ed"
```




