# phnmnl_IPO_workflow
Optimize XCMS analytical parameters by running IPO workflow (Peak picking + Retention time correction and grouping optimization) on Metabolights studies within the PhenoMeNal EU project.

## Description
Runs the IPO tool that includes as a 2 steps workflow the peak picking step first and then retention time correction and peak grouping optimization steps together, using wft4galaxy api. The workflow can process one (scripts/run_ipo_workflow.R) or several (scripts/run_ipo_on_several_studies.sh) Metabolights studies (http://www.ebi.ac.uk/metabolights/) using wft4galaxy (http://wft4galaxy.readthedocs.io) as an API accessing a Galaxy instance with an installed PhenoMeNal e-infrastructure.
This script processes all assays separately and picks mz files within assays according to their respective factors found in the investigation file of the given study, in order to represent all combinations of factors that exist. Otherwise it randomly picks 5% but at least 10 files to save processing time.

## Requirements
+ Docker  
  - Make sure that wft4galaxy-docker is available on your machine.  
    Visit http://wft4galaxy.readthedocs.io/installation.html#id2 for installation instructions.  
    
  - Install isa2w4m container from PhenoMeNal (Convert ISA-tab into 3 files: sample metadata, variable metadata, sample x         variable matrix)  
    `$ docker pull container-registry.phenomenal-h2020.eu/phnmnl/isa2w4m`  

  - (optionnal) You can install the Metabolights Downloader container from PhenoMeNal (Pierrick Roger - CEA)  
    `$ docker pull container-registry.phenomenal-h2020.eu/phnmnl/mtbls-dwnld`  
    to download a Metabolights study:  
    `$ docker run -v /home/user/workdir/studies/:/studies container-registry.phenomenal-h2020.eu/phnmnl/mtbls-dwnld -a -o /studies MTBLS213`  

+ The R packages Risa and R.utils need to be installed.  
  - ```R
    install.packages("R.utils")
    # Risa
    source("https://bioconductor.org/biocLite.R")
    biocLite("Risa")
    ```

Prepare the working environment.  
```bash
git clone https://github.com/gabrielctn/phnmnl_IPO_workflow.git
cd phnmnl_IPO_workflow
mkdir output
chmod a+x ./scripts/run_IPO_workflow.r 
```  
The working directory should look like:  
```
work_dir
    |_ output (to build)  
    |_ studies  
    |      |_ MTBLS213  
    |      |_ ...  
    |_ template  
    |      |_ baseline_ipo.ga  
    |      |_ ipo_workflow.ga  
    |_ python  
    |      |_ simple_comp.py  
    |_ scripts   
           |_ run_ipo_workflow.R  
           |_ run_ipo_on_several_studies.sh
```


## Usage
Run the script without any argument to display help message.  
`./run_ipo_workflow.r`  
**Arguments**  
**study_path** - Local path containing the MTBLS study  
**study_name** - Name of the study to be processed (e.g. MTBLS433)  
**ga_file_template** - Galaxy workflow file (.ga) for the statistical workflow  
**output_path** - Local path used to store the result files   
**log_file** - Path to csv file used for log messages  
**galaxy_url** - URL to Galaxy server on which to run the workflow  
**galaxy_key** - API key to access the Galaxy server  
**debug** - Get debug output from wft4galaxy (true, false) default: false  
**logger** - Enable logger for wft4galaxy (true, false) default: false  


## Example  
```bash
./run_ipo_workflow.r
      study_path="studies"
      study_name="MTBLS213"
      ga_file_template="template/ipo_workflow.ga"
      output_path="output"
      log_file="MTBLS213_logs.csv"
      galaxy_url="http://192.168.99.100:30700"
      galaxy_key="ce30966564d6a42b22f951ca023081ed"
```

## Run the workflow on several Metabolights studies  
Same requirements as described previously.  
This script simply runs the script described above (run_ipo_workflow.R) over several Metabolights studies contained in a given folder ("studies" for example).

### Usage  
```
Usage: run_ipo_on_several_studies.sh [options]

Repo: https://github.com/gabrielctn/phnmnl_IPO_workflow
Runs the IPO workflow held in PhenoMeNal over all Metabolights studies contained in the folder given in argument with wft4galaxy.
The workflow consists in 2 steps:
1. Peakpicking
2. Grouping and retention time correction

Options:
   -h, --help                        Print this help message.
   -r, --script      PATH            Path to 'run_ipo_workflow.R' script.
   -s, --studies     PATH            Path to the folder containing all the Metabolights studies (MTBLSXXX).
   -t, --template    PATH            Path to the galaxy workflow (.ga) template.
   -o, --output      PATH            Path to the output folder, where results will be created.
   -u, --galaxyurl   URL             The URL for the Galaxy server. For example: http://192.168.99.100:30700/
   -k, --galaxykey   KEY             The galaxy api key of the actual galaxy server. Can be found in the settings of the admin galaxy interface. For example: 822c174c483b7a3675c313c1a4466f12
   -d, --debug       true/false      Print debug infos.
   -l, --logger      true/false      Print log infos.

```


