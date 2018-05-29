# phnmnl_IPO_workflow
Optimize XCMS analytical parameters by running IPO workflow (Peak picking + Retention time correction and grouping optimization) on Metabolights studies within the PhenoMeNal EU project.

## Description
Runs the IPO tool that includes as a 2 steps workflow the peak picking step first and then retention time correction and peak grouping optimization steps together, using wft4galaxy api. The workflow can process one (scripts/run_ipo_workflow.R) or several (scripts/run_ipo_on_several_studies.sh) Metabolights studies (http://www.ebi.ac.uk/metabolights/) using wft4galaxy (http://wft4galaxy.readthedocs.io) as an API accessing a Galaxy instance with an installed PhenoMeNal e-infrastructure.
This script processes all assays separately. It picks 5% but at least 10 data files to save processing time.
For the grouping step, the sample metadata file is necessary in order to take into account the experimental design factors. They are integrated into the best xcmsSet R object resulting from the peak picking step.  

\*\***Important**\*\*: The workflow consists in optimizing a subset of parameters at once only, to reduce computation time. You need to download the workflow optimizing the parameters of your choice from Galaxy (into a .ga file). The workflow present in template/ipo_workflow_peakwidth_bw.ga

## Requirements
+ Docker  
  - Make sure that wft4galaxy-docker is available on your machine.  
    Visit http://wft4galaxy.readthedocs.io/installation.html#id2 for installation instructions.  
    
  - Install isa2w4m container from PhenoMeNal (Convert ISA-tab into 3 files: sample metadata, variable metadata, sample x         variable matrix)  
    `$ docker pull container-registry.phenomenal-h2020.eu/phnmnl/isa2w4m`  

  - (**optionnal**) You can install the Metabolights Downloader container from PhenoMeNal (Pierrick Roger - CEA)  
    `$ docker pull container-registry.phenomenal-h2020.eu/phnmnl/mtbls-dwnld`  
    to download a Metabolights study:  
    `$ docker run -v /home/user/workdir/studies/:/studies container-registry.phenomenal-h2020.eu/phnmnl/mtbls-dwnld -a -o /studies MTBLS213`  
    **This step is done automatically if you run the workflow on several studies. See the section at the end**

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
    |      |_ ipo_workflow_peakwidth_bw.ga  
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
**ga_file_template** - Galaxy workflow file (.ga) for the IPO workflow  
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
      ga_file_template="template/ipo_workflow_peakwidth_bw.ga"
      output_path="output"
      log_file="MTBLS213_logs.csv"
      galaxy_url="http://192.168.99.100:30700"
      galaxy_key="ce30966564d6a42b22f951ca023081ed"
```

## Run the workflow on several Metabolights studies  

Same requirements as described previously.  
This script runs the script described above (run_ipo_workflow.R) over all the Metabolights studies mentioned in a given folder ("studies" for example). The difference lies in the fact that the studies are downloaded automatically, only the Metabolights ID in a simple text file are required.

### Usage  
```
Usage: run_ipo_on_several_studies.sh [options]

Repo: https://github.com/gabrielctn/phnmnl_IPO_workflow
Runs the IPO workflow held in PhenoMeNal over all Metabolights studies mentionned in the text file given in argument with wft4galaxy.
The workflow consists in 2 steps:
1. Peakpicking
2. Grouping and retention time correction

Options:
   -h, --help                        Print this help message.
   -r, --script      PATH            Path to 'run_ipo_workflow.R' script.
   -s, --studies     PATH            Path to the text file containing all the Metabolights studies. 1 line = 1 MTBLSXXX.
   -t, --template    PATH            Path to the galaxy workflow (.ga) template.
   -o, --output      PATH            Path to the output folder, where results will be created.
   -u, --galaxyurl   URL             The URL for the Galaxy server. For example: http://192.168.99.100:30700/
   -k, --galaxykey   KEY             The galaxy api key of the actual galaxy server. Can be found in the settings of the admin galaxy interface. For example: 822c174c483b7a3675c313c1a4466f12
   -d, --debug       true/false      Print debug infos.
   -l, --logger      true/false      Print log infos.

```

## Output  

Since the purpose of this script is to run the workflow on different studies, outputs will not follow a specific template. That is why the API does not compare the resulting files with the "expected" ones.
```
----------------------------------------------------------------------
Ran 1 test in 1600.722s

OK
2018-05-12 19:30:31,667 [wft4galaxy.app.runner] [DEBUG]  wft4galaxy.run_tests exiting with code: 0
```

The results will appear in the registered histories on Galaxy (browser) and on the "results" folder locally, in the folder "output".  
Example with MTBLS217:  
```
# assay NEG
$ ls output/MTBLS117/a_mtbls117_DIMS_NEG_mass_spectrometry/results/ipo/
best_xcmsSet.RData  ipo4xcmsSet.log.txt             IPO_parameters4xcmsSet.tsv  run_instrument_infos.tsv
ipo4retcor.log.txt  IPO_parameters4retcorGroup.tsv  resultPeakpicking.RData
# assay POS
$ ls output/MTBLS117/a_mtbls117_DIMS_POS_mass_spectrometry/results/ipo/
best_xcmsSet.RData  ipo4xcmsSet.log.txt             IPO_parameters4xcmsSet.tsv  run_instrument_infos.tsv
ipo4retcor.log.txt  IPO_parameters4retcorGroup.tsv  resultPeakpicking.RData

```


