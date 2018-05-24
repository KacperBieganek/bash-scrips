#!/bin/bash -eu

function print_help () {
    echo "This script allows to search over movies database"
    echo -e "-d DIRECTORY\n\tDirectory with files describing movies"
    echo -e "-a ACTOR\n\tSearch movies that this ACTOR played in"
    echo -e "-t QUERY\n\tSearch movies with given QUERY in title"
    echo -e "-f FILENAME\n\tSaves results to file (default: results.txt)"
    echo -e "-y YEAR\n\tSearch movies that were made after YEAR"
    echo -e "-x\n\tPrints results in XML format"
    echo -e "-h\n\tPrints this help message"
}

function print_error () {
    echo -e "\e[31m\033[1m${*}\033[0m" >&2
}

function get_movies_list () {
    local -r MOVIES_DIR=${1}
    local -r MOVIES_LIST=$(cd "${MOVIES_DIR}" && realpath ./*)
    echo "${MOVIES_LIST}"
}

function query_title () {
    # Returns list of movies from ${1} with ${2} in title slot
    local -r MOVIES_LIST=${1}
    local -r QUERY=${2}

    local RESULTS_LIST=()
    for MOVIE_FILE in ${MOVIES_LIST}; do
        if grep "| Title" "${MOVIE_FILE}" | grep -q "${QUERY}"; then
            RESULTS_LIST+=( ${MOVIE_FILE} )
        fi
    done
    echo "${RESULTS_LIST[@]:-}"
}

function query_actor () {
    # Returns list of movies from ${1} with ${2} in actor slot
    local -r MOVIES_LIST=${1}
    local -r QUERY=${2}

    local RESULTS_LIST=()
    for MOVIE_FILE in ${MOVIES_LIST}; do
        if grep "| Actors" "${MOVIE_FILE}" | grep -q "${QUERY}"; then
            RESULTS_LIST+=( ${MOVIE_FILE} )
        fi
    done
    echo "${RESULTS_LIST[@]:-}"
}

function query_year(){
    # Returns list of movies from ${1} newer than ${2}
    local -r MOVIES_LIST=${1}
    local -r QUERY=${2}

    local RESULTS_LIST=()
    for MOVIE_FILE in ${MOVIES_LIST}; do
        YEAR_OF_PRODUCTION=$(grep "| Year" "${MOVIE_FILE}" | cut -d ' ' -f3)  
        if [[ "${YEAR_OF_PRODUCTION}" -gt "${QUERY}" ]]; then
            RESULTS_LIST+=( ${MOVIE_FILE} )
        fi
    done
    echo "${RESULTS_LIST[@]:-}"
    
}

function query_plot(){
    # Returns list of movies from ${1}  with plot containing ${2}
    local -r MOVIES_LIST=${1}
    local -r QUERY=${2}

    local RESULTS_LIST=()
    for MOVIE_FILE in ${MOVIES_LIST}; do
        if ! ${IGNORE_CASEING:-false}; then
            if grep "| Plot" "${MOVIE_FILE}" | grep -i -q -P "${QUERY}"; then
                RESULTS_LIST+=( ${MOVIE_FILE} )
            fi
        else
            if grep "| Plot" "${MOVIE_FILE}" | grep -q -P "${QUERY}"; then
                RESULTS_LIST+=( ${MOVIE_FILE} )
            fi
        fi
    done
    echo "${RESULTS_LIST[@]:-}"
}

function print_movies () {
    local -r MOVIES_LIST=${1}
    local -r OUTPUT_FORMAT=${2}

    for MOVIE_FILE in ${MOVIES_LIST}; do
        if [[ "${OUTPUT_FORMAT}" == "xml" ]]; then
            print_xml_format "${MOVIE_FILE}"
        else
            cat "${MOVIE_FILE}"
        fi
    done
}

function print_xml_format () {
    local -r FILENAME=${1}

    local TEMP=$(cat "${FILENAME}")

    #REMOVE PIPES
    TEMP=$(echo "${TEMP}" | sed -r 's/\|\ //')
    #REMOVE 
    TEMP=$(echo "${TEMP}" | sed -r 's/\://')

    # TODO: change 'Author:' into <Author>
    TEMP=$(echo "${TEMP}" | sed -r 's/([A-Za-z]+)/\<\1>/')
    # TODO: change others too

    # append tag after each line
    TEMP=$(echo "${TEMP}" | sed -r 's/([A-Za-z]+).*/\0<\/\1>/')
   
    #replace first line of equals signs
    TEMP=$(echo "${TEMP}" | sed '0,/===*/s//<movie>/')

    # replace the last line with </movie>
    TEMP=$(echo "${TEMP}" | sed '$s/===*/<\/movie>/')

    echo "${TEMP}"
}

while getopts ":hd:t:a:f:xy:iR:" OPT; do
  case ${OPT} in
    h)
        print_help
        exit 0
        ;;
    d)
        PARAMETER_GIVEN=true
        MOVIES_DIR=${OPTARG}
        ;;
    t)
        SEARCHING_TITLE=true
        QUERY_TITLE=${OPTARG}
        ;;
    f)
        FILE_4_SAVING_RESULTS=${OPTARG}
        ;;
    a)
        SEARCHING_ACTOR=true
        QUERY_ACTOR=${OPTARG}
        ;;
    x)
        OUTPUT_FORMAT="xml"
        ;;
    y)
	SEARCHING_YEAR=true
	QUERY_YEAR=${OPTARG}
	;;
    i)
    IGNORE_CASING=true
    ;;
    R)
    SEARCHING_PLOT=true
    QUERY_PLOT=${OPTARG}
    ;;
    \?)
        print_error "ERROR: Invalid option: -${OPTARG}"
        exit 1
        ;;
  esac
done


if ! ${PARAMETER_GIVEN:-false}; then
    echo "YOU NEED TO PROVIDE DIRECTORY WITH -d OPTION"
    exit 1
else
    if [[ ! -d ${MOVIES_DIR} ]]; then
        echo "YOU NEED TO PROVIDE DIRECTORY WITH -d OPTION"
        exit 1
    fi
fi

MOVIES_LIST=$(get_movies_list "${MOVIES_DIR}")

if ${SEARCHING_TITLE:-false}; then
    MOVIES_LIST=$(query_title "${MOVIES_LIST}" "${QUERY_TITLE}")
fi

if ${SEARCHING_ACTOR:-false}; then
    MOVIES_LIST=$(query_actor "${MOVIES_LIST}" "${QUERY_ACTOR}")
fi

if ${SEARCHING_YEAR:-false}; then
    MOVIES_LIST=$(query_year "${MOVIES_LIST}" "${QUERY_YEAR}")
fi

if ${SEARCHING_PLOT:-false}; then
    MOVIES_LIST=$(query_plot "${MOVIES_LIST}" "${QUERY_PLOT}")
fi

if [[ "${#MOVIES_LIST}" -lt 1 ]]; then
    echo "Found 0 movies :-("
    exit 0
fi

if [[ "${FILE_4_SAVING_RESULTS:-}" == "" ]]; then
    print_movies "${MOVIES_LIST}" "${OUTPUT_FORMAT:-raw}"
else
    if [[ ${FILE_4_SAVING_RESULTS: -4} != ".txt" ]]; then
        FILE_4_SAVING_RESULTS=${FILE_4_SAVING_RESULTS}.txt
    fi
    print_movies "${MOVIES_LIST}" "${OUTPUT_FORMAT:-raw}" | tee "${FILE_4_SAVING_RESULTS}"
fi
