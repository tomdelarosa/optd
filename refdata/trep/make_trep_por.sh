#!/bin/bash
#
# That script generates, from the ORI-maintained POR data file, the two data
# files suitable for OpenTrep, namely 'trep_place_details.csv' and
# 'trep_place_names.csv'. Those files are maintained in the /refdata/trep/admin
# sub-directory of the OpenTravelData project:
# http://github.com/opentraveldata/optd.
#
# One parameter is optional for this script:
# - the file-path of the ORI-maintained POR public data file.
#

##
# Temporary path
TMP_DIR="/tmp/por"

##
# Path of the executable: set it to empty when this is the current directory.
EXEC_PATH=`dirname $0`
# Trick to get the actual full-path
pushd ${EXEC_PATH} > /dev/null
EXEC_FULL_PATH=`popd`
popd > /dev/null
EXEC_FULL_PATH=`echo ${EXEC_FULL_PATH} | sed -e 's|~|'${HOME}'|'`
CURRENT_DIR=`pwd`
if [ ${CURRENT_DIR} -ef ${EXEC_PATH} ]
then
	EXEC_PATH="."
	TMP_DIR="."
fi
EXEC_PATH="${EXEC_PATH}/"
TMP_DIR="${TMP_DIR}/"

if [ ! -d ${TMP_DIR} -o ! -w ${TMP_DIR} ]
then
	\mkdir -p ${TMP_DIR}
fi

##
# Sanity check: that (executable) script should be located in the trep/ sub-directory
# of the OpenTravelData project Git clone
EXEC_DIR_NAME=`basename ${EXEC_FULL_PATH}`
if [ "${EXEC_DIR_NAME}" != "trep" ]
then
	echo
	echo "[$0:$LINENO] Inconsistency error: this script ($0) should be located in the refdata/trep/ sub-directory of the OpenTravelData project Git clone, but apparently is not. EXEC_FULL_PATH=\"${EXEC_FULL_PATH}\""
	echo
	exit -1
fi

##
# OpenTravelData directory
OPTD_DIR=`dirname ${EXEC_FULL_PATH}`
OPTD_DIR="${OPTD_DIR}/"

##
# ORI sub-directories
ORI_DIR=${OPTD_DIR}ORI/
TOOLS_DIR=${OPTD_DIR}tools/
TREP_DIR=${OPTD_DIR}trep/

##
# Log level
LOG_LEVEL=3

##
# Input files
ORI_RAW_FILENAME=ori_por_public.csv
ORI_PR_FILENAME=ref_airport_pageranked.csv
#
ORI_RAW_FILE=${ORI_DIR}${ORI_RAW_FILENAME}
ORI_PR_FILE=${ORI_DIR}${ORI_PR_FILENAME}

##
# Tools
PREPARE_ORI_EXEC_NAME=prepare_ori_public.sh
#
PREPARE_ORI_EXEC=${TOOLS_DIR}${PREPARE_ORI_EXEC_NAME}

##
# Generated files

# ORI list of POR file with primary key (generated by the
# prepare_ori_public.sh script)
ORI_WPK_FILENAME=wpk_${ORI_RAW_FILENAME}
ORI_SORTED_FILENAME=sorted_${ORI_WPK_FILENAME}
ORI_CUT_SORTED_FILENAME=cut_${ORI_SORTED_FILENAME}
#
ORI_WPK_FILE=${TOOLS_DIR}${ORI_WPK_FILENAME}
ORI_SORTED_FILE=${TOOLS_DIR}${ORI_SORTED_FILENAME}
ORI_CUT_SORTED_FILE=${TOOLS_DIR}${ORI_CUT_SORTED_FILENAME}

##
# Targets
TREP_DETAILS_FILENAME=trep_place_details.csv
TREP_NAMES_FILENAME=trep_place_names.csv
TREP_PR_FILENAME=trep_airport_pageranked.csv
#
TREP_DETAILS_FILE=${TMP_DIR}${TREP_DETAILS_FILENAME}
TREP_NAMES_FILE=${TMP_DIR}${TREP_NAMES_FILENAME}
TREP_PR_FILE=${TMP_DIR}${TREP_PR_FILENAME}

##
# Temporary
ORI_FILE_TMP=${TMP_DIR}${ORI_WPK_FILENAME}.wohdr
ORI_SORTED_FILE_TMP=${TMP_DIR}${ORI_WPK_FILENAME}.wohdr.sorted

##
# Usage
if [ "$1" = "-h" -o "$1" = "--help" ];
then
	echo
	echo "From the ORI-maintained POR data file, that script generates (into the '${TMP_DIR}' directory) the two data files suitable for OpenTrep,"
	echo "namely '${TREP_DETAILS_FILE}', '${TREP_NAMES_FILE}' and '${TREP_PR_FILENAME}'."
	echo
	echo "Usage: $0 [<refdata directory of the OpenTravelData project Git clone> [<Log level>]]"
	echo "  - Default refdata directory for the OpenTravelData project Git clone: '${OPTD_DIR}'"
	echo "    Hence, the following data file is required to exist:"
	echo "    + ORI-maintained list of POR, full public details: '${ORI_RAW_FILE}'."
	echo "  - Default log level: ${LOG_LEVEL}"
	echo "    + 0: No log; 1: Critical; 2: Error; 3; Notification; 4: Debug; 5: Verbose"
	echo "  - Generated files:"
	echo "    + '${TREP_DETAILS_FILE}'"
	echo "    + '${TREP_NAMES_FILE}'"
	echo "    + '${TREP_PR_FILE}'"
	echo
	exit
fi

##
# The OpenTravelData refdata/ sub-directory contains, among other things,
# the ORI-maintained list of POR file with geographical coordinates.
if [ "$1" != "" -a "$1" != "--clean" ]
then
	if [ ! -d $1 ]
	then
		echo
		echo "The first parameter ('$1') should point to the refdata/ sub-directory of the OpenTravelData project Git clone. It is not accessible here."
		echo
		exit -1
	fi
	OPTD_DIR_DIR=`dirname $1`
	OPTD_DIR_BASE=`basename $1`
	OPTD_DIR="${OPTD_DIR_DIR}/${OPTD_DIR_BASE}/"
	ORI_DIR=${OPTD_DIR}ORI/
	TOOLS_DIR=${OPTD_DIR}tools/
	#
	ORI_RAW_FILE=${ORI_DIR}${ORI_RAW_FILENAME}
	ORI_WPK_FILE=${TOOLS_DIR}${ORI_WPK_FILENAME}
	ORI_SORTED_FILE=${TOOLS_DIR}${ORI_SORTED_FILENAME}
	ORI_CUT_SORTED_FILE=${TOOLS_DIR}${ORI_CUT_SORTED_FILENAME}
	#
	PREPARE_ORI_EXEC=${TOOLS_DIR}${PREPARE_ORI_EXEC_NAME}
fi

if [ ! -f "${ORI_RAW_FILE}" ]
then
	echo "[$0:$LINENO] The '${ORI_RAW_FILE}' file does not exist."
	if [ "$1" = "" ]
	then
		displayOriDetails
	fi
	exit -1
fi

##
# Log level
if [ "$2" != "" ]
then
	LOG_LEVEL="$2"
fi

##
# Cleaning
if [ "$1" = "--clean" -o "$2" = "--clean" -o "$3" = "--clean" ];
then
	\rm -f ${TREP_DETAILS_FILE} ${TREP_NAMES_FILE} ${TREP_PR_FILE}
	\rm -f ${ORI_WPK_FILE} ${ORI_SORTED_FILE} ${ORI_CUT_SORTED_FILE} \
		${ORI_FILE_TMP} ${ORI_SORTED_FILE_TMP}
	#\rm -f ${ORI_RAW_FILENAME}

	echo "Changing to the ${TOOLS_DIR} directory"
	pushd ${TOOLS_DIR} > /dev/null
	bash ${PREPARE_ORI_EXEC_NAME} --clean || exit -1
	BACK_DIR=`popd`
	popd > /dev/null
	echo "Back to the ${BACK_DIR} directory"
	exit
fi

##
# Sanity check
if [ ! -d ${TOOLS_DIR} ]
then
	echo
	echo "[$0:$LINENO] The tools/ sub-directory ('${TOOLS_DIR}') does not exist or is not accessible."
	echo "Check that your Git clone of the OpenTravelData is complete."
	echo
	exit -1
fi
if [ ! -f ${PREPARE_ORI_EXEC} ]
then
	echo
	echo "[$0:$LINENO] The ORI-maintained file preparation script ('${TOOLS_DIR}prepare_ori_public.sh') does not exist or is not accessible."
	echo "Check that your Git clone of the OpenTravelData is complete."
	echo
	exit -1
fi

##
# Preparation
echo "Changing to the ${TOOLS_DIR} directory"
pushd ${TOOLS_DIR} > /dev/null
bash ${PREPARE_ORI_EXEC_NAME} ${OPTD_DIR} ${LOG_LEVEL} || exit -1
BACK_DIR=`popd`
popd > /dev/null
echo "Back to the ${BACK_DIR} directory"

##
#
if [ ! -f ${ORI_SORTED_FILE} ]
then
	echo
	echo "[$0:$LINENO] The '${ORI_SORTED_FILE}' file does not exist."
	echo
	${PREPARE_ORI_EXEC} --ori
	echo
	exit -1
fi


##
# First, remove the header (first line)
sed -e "s/^pk\(.\+\)//g" ${ORI_SORTED_FILE} > ${ORI_FILE_TMP}
sed -i -e "/^$/d" ${ORI_FILE_TMP}


##
# The ORI-maintained POR file is sorted according to the primary key (IATA code
# and location type), just to be sure.
sort -t'^' -k 1,1 ${ORI_FILE_TMP} > ${ORI_SORTED_FILE_TMP}
\rm -f ${ORI_FILE_TMP}

##
# Generate the file with the details related to the ORI places (POR)
UPDATER_SCRIPT_DETAILS=${EXEC_PATH}make_trep_por_details.awk
awk -F'^' -f ${UPDATER_SCRIPT_DETAILS} ${ORI_SORTED_FILE_TMP} > ${TREP_DETAILS_FILE}

##
# Generate the file with the names related to the ORI places (POR)
UPDATER_SCRIPT_NAMES=${EXEC_PATH}make_trep_por_alternate_names.awk
awk -F'^' -f ${UPDATER_SCRIPT_NAMES} ${ORI_SORTED_FILE_TMP} > ${TREP_NAMES_FILE}

##
# Generate the file with the PageRank-ed places (POR)
UPDATER_SCRIPT_PR=${EXEC_PATH}make_trep_por_pagerank.awk
awk -F'^' -f ${UPDATER_SCRIPT_PR} ${ORI_PR_FILE} > ${TREP_PR_FILE}

##
# Reporting
echo
echo "Reporting"
echo "---------"
echo "See the '${TREP_DETAILS_FILE}', '${TREP_NAMES_FILE}' and '${TREP_PR_FILE}' files:"
echo "wc -l ${TREP_DETAILS_FILE} ${TREP_NAMES_FILE} ${TREP_PR_FILE}"
echo "head -5 ${TREP_DETAILS_FILE} ${TREP_NAMES_FILE} ${TREP_PR_FILE}"
echo
echo "To clean the files, just do: $0 --clean"
echo

