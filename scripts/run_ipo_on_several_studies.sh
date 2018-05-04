#!/usr/bin/env bash

# Constants
################################################################################

PATH_TO_SCRIPT=
PATH_TO_STUDIES=
PATH_TO_GA_TEMPLATE=
PATH_TO_OUTPUT=
GALAXY_URL=
GALAXY_API_KEY=
DEBUG=
LOGGER=
LOG_FILE="_log.csv"
PROG_NAME=$(basename $0)

# Print help
################################################################################

function print_help {
	echo "Usage: $PROG_NAME [options]"
	echo
    echo "Repo: https://github.com/gabrielctn/phnmnl_IPO_workflow"
	echo "Runs the IPO workflow held in PhenoMeNal over all Metabolights studies contained in the folder given in argument with wft4galaxy."
	echo "The workflow consists in 2 steps:"
	echo "1. Peakpicking"
	echo "2. Grouping and retention time correction"
	echo
	echo "Options:"
	echo "   -h, --help                        Print this help message."
    echo "   -r, --script      PATH            Path to 'run_ipo_workflow.R' script."
	echo "   -s, --studies     PATH            Path to the folder containing all the Metabolights studies (MTBLSXXX)."
	echo "   -t, --template    PATH            Path to the galaxy workflow (.ga) template."
	echo "   -o, --output      PATH            Path to the output folder, where results will be created."
	echo "   -u, --galaxyurl   URL             The URL for the Galaxy server. For example: http://192.168.99.100:30700/"
	echo "   -k, --galaxykey   KEY             The galaxy api key of the actual galaxy server. Can be found in the settings of the admin galaxy interface. For example: 822c174c483b7a3675c313c1a4466f12"
	echo "   -d, --debug       true/false      Print debug infos."
	echo "   -l, --logger      true/false      Print log infos."
}


# Read command line arguments
################################################################################

function read_args {

    if [[ $# -eq 0 ]] ; then
        print_help
        exit 0
    fi

	# Read options
	while true ; do
		shift_count=1
		case $1 in
			-h|--help)              print_help ; exit 0 ;;
            -r|--script)            PATH_TO_SCRIPT="$2" ; shift_count=2 ;;
			-s|--studies)           PATH_TO_STUDIES="$2" ; shift_count=2 ;;
			-t|--template)          PATH_TO_GA_TEMPLATE="$2" ; shift_count=2 ;;
			-o|--output)            PATH_TO_OUTPUT="$2" ; shift_count=2 ;;
			-u|--galaxyurl)     	GALAXY_URL="$2" ; shift_count=2 ;;
			-k|--galaxykey)         GALAXY_API_KEY="$2" ; shift_count=2 ;;
			-d|--debug)             DEBUG="$2" ; shift_count=2 ;;
			-l|--logger)            LOGGER="$2" ; shift_count=2 ;;
			-) echo "Illegal option $1." ; exit 1 ;;
			--) echo "Illegal option $1." ; exit 1 ;;
			--*) echo "Illegal option $1." ; exit 1 ;;
			-?) echo "Unknown option $1." ; exit 1 ;;
			-[^-]*) split_opt=$(echo $1 | sed 's/^-//' | sed 's/\([a-zA-Z]\)/ -\1/g') ; set -- $1$split_opt "${@:2}" ;;
			*) break
		esac
		shift $shift_count
	done
	shift $((OPTIND - 1))
}


# Main
################################################################################

read_args "$@"

# Run the workflow on all studies found
for study in $PATH_TO_STUDIES/*; do
	scripts/run_ipo_workflow.R study_path=$PATH_TO_STUDIES study_name=$(basename $study) ga_file_template=$PATH_TO_GA_TEMPLATE output_path=$PATH_TO_OUTPUT log_file="$study$LOG_FILE" galaxy_url=$GALAXY_URL galaxy_key=$GALAXY_API_KEY debug=$DEBUG logger=$LOGGER
done
