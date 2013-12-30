#!/bin/bash
#
# rEFInd - http://www.rodsbooks.com/refind
#
# This script will attempt to install the rEFInd boot manager
# to your Mac to allow booting from a non-mac USB flash drive,
# among other things

run_refind() {
    if ! type_exists "wget"; then
        if type_exists "brew"; then
            brew install wget
        else
            printf "\n"
            e_error "Error: wget and Homebrew not found."
            printf "Aborting...\n"
            exit
        fi
    fi

    # we'll just do this all in a refind dir for now
    REFIND_DIR=${HOME}/refind
    if [[ ! -e ${REFIND_DIR} ]]; then
        mkdir ${REFIND_DIR}
    fi
    cd ${REFIND_DIR}

    REFIND_VERSION=0.7.6
    LOCAL_NAME=refind-bin-${REFIND_VERSION}.zip
    URL_BASE=http://downloads.sourceforge.net/project/refind/${REFIND_VERSION}/refind-bin-${REFIND_VERSION}.zip

    e_header "Downloading rEFInd ${REFIND_VERSION}..."
    wget -O ${LOCAL_NAME} ${URL_BASE}


    e_header "Unpacking rEFInd ${REFIND_VERSION}..."
    unzip -q ${LOCAL_NAME}

    # discover the name of the unzipped directory
    UNZIPPED_NAME=$(zipinfo -1 $LOCAL_NAME | sed -e 's,/.*,,' | uniq)

    # check FileVault status - using an encrypted HD means we're
    # required to use the --esp flag to force install to ESP
    REFIND_OPTS=''
    if [[ $(fdesetup status) == 'FileVault is On.' ]]; then
        e_header "FileVault is active, configuring rEFInd to install to ESP"
        REFIND_OPTS="${REFIND_OPTS} --esp"

        # we also need to uncomment dont_scan_volumes and
        # remove "Recovery HD" if it exists
        sed -Ee "s/#(dont_scan_volumes)(.*)/\1 /" ${UNZIPPED_NAME}/refind/refind.conf-sample > ${UNZIPPED_NAME}/refind/refind.conf-sample.bkp
        mv ${UNZIPPED_NAME}/refind/refind.conf-sample.bkp ${UNZIPPED_NAME}/refind/refind.conf-sample
    fi

    # run the install script
    e_header "Running rEFInd install script..."
    ./${UNZIPPED_NAME}/install.sh ${REFIND_OPTS}
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/../utils

run_refind
