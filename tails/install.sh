#!/bin/bash
#
# Tails - The Amnesic Incognito Live System
#
# This script will grab the tails iso image, attempt to verify
# its authenticity, and write the image to an available USB
# flash drive.

run_tails() {
    # this will require gpg to verify the authenticity of tails download
    if ! type_exists 'gpg2'; then
        if type_exists 'brew'; then
            e_header "Installing GnuPG2..."
            brew install gpg2
        else
            printf "\n"
            e_error "Error: GnuPG and Homebrew not found."
            printf "Aborting...\n"
            exit
        fi
    fi

    # we'll also need wget to grab the tails ISO
    if ! type_exists 'wget'; then
        if type_exists 'brew'; then
            e_header "Installing wget..."
            brew install wget
        else
            printf "\n"
            e_error "Error: wget and Homebrew not found."
            printf "Aborting...\n"
            exit
        fi
    fi


    # we'll just do this all in a tails dir for now
    TAILS_DIR=${HOME}/tails
    if [[ ! -e ${TAILS_DIR} ]]; then
        mkdir ${TAILS_DIR}
    fi
    cd ${TAILS_DIR}


    # grab the tails iso and other resources if necessary
    TAILS_VERSION=0.22
    ISO_URL_BASE=http://dl.amnesia.boum.org/tails/stable/tails-i386-${TAILS_VERSION}/tails-i386-${TAILS_VERSION}.iso
    SIG_URL_BASE=https://tails.boum.org/torrents/files/tails-i386-${TAILS_VERSION}.iso.sig
    KEY_URL_BASE=https://tails.boum.org/tails-signing.key

    if [[ ! -e tails-i386-${TAILS_VERSION}.iso ]]; then
        e_header "Downloading Tails ${TAILS_VERSION}..."
        wget $ISO_URL_BASE
    fi

    if [[ ! -e tails-i386-${TAILS_VERSION}.iso.sig ]]; then
        e_header "Downloading Tails ${TAILS_VERSION} Signature..."
        curl -LO $SIG_URL_BASE
    fi

    if [[ ! -e tails-signing.key ]]; then
        e_header "Downloading Tails Signing Key..."
        curl -LO $KEY_URL_BASE
    fi

    e_header "Importing Tails Signing Key..."
    cat tails-signing.key | gpg2 --keyid-format long --import

    e_header "Verfiying Tails ${TAILS_VERSION} ISO..."
    gpg2 --keyid-format long --verify tails-i386-${TAILS_VERSION}.iso.sig tails-i386-${TAILS_VERSION}.iso


    seek_confirmation "Would you like to continue with this ISO?"

    if is_confirmed; then
        # download the isohybrid utility... looks like rEFInd won't recognize this
        # as a bootable device otherwise
        # http://www.syslinux.org/wiki/index.php/Doc/isolinux
        # more here... looks like it's that some machines have UEFI based firmware,
        # and some have BIOS based firmware.  This makes tails work with BIOS
        # http://forums.opensuse.org/english/get-technical-help-here/install-boot-login/484412-do-not-run-isohybrid-12-2-12-3-skip-section-so-do-what-instead.html#post2535986
        if [[ ! -e syslinux_4.02+dfsg.orig.tar.gz ]]; then
            e_header "Downloading isohybrid utility to format ISO..."
            curl -LO http://ftp.debian.org/debian/pool/main/s/syslinux/syslinux_4.02+dfsg.orig.tar.gz

            e_header "Formatting ISO..."
            tar xzf syslinux_4.02+dfsg.orig.tar.gz
            UNTARRED_NAME=$(tar tzf syslinux_4.02+dfsg.orig.tar.gz | sed -e 's,/.*,,' | uniq)
            perl ${UNTARRED_NAME}/utils/isohybrid.pl tails-i386-${TAILS_VERSION}.iso
        fi

        response='r'
        while [[ $response == 'r' ]]; do
            e_header "Listing Drives:"
            diskutil list
            printf "\n"
            printf "Please identify your USB drive from the list above.\n"
            printf "If your USB drive is not connected, insert it now and refresh this list.\n"
            read -p "(r)efresh/(c)ancel/(#) of drive:  " -n 1 response
            printf "\n\n"

            if [[ $response != 'r' && $response != 'c' ]]; then
                # really can't believe there's no easier way to check exit status?
                # i must be missing something
                diskutil list /dev/disk${response} > /dev/null
                if [[ $? -ne 0 ]]; then
                    e_warning "The specified drive /dev/disk${response} does not exist.  Please try again."
                    response='r'
                fi
            fi
        done

        if [[ $response == 'c' ]]; then
            e_warning "Aborting, your USB drive will not be formatted at this time."
        else
            # WARN USER ABOUT DANGERS
            DRIVE="/dev/disk${response}"
            e_warning "You have chosen drive ${DRIVE}.  DO NOT proceed unless you're\nabsolutely sure this is the right drive!"
            diskutil list $DRIVE
            printf "\n"

            seek_confirmation "The next step will overrite all data on ${DRIVE}..."

            if is_confirmed; then
                e_header "Unmounting drive..."
                diskutil unmountDisk ${DRIVE}

                # todo: to verify the unmount happened successfully
                e_header "Copying Tails ${TAILS_VERSION} image to drive ${DRIVE}..."
                sudo dd if=tails-i386-${TAILS_VERSION}.iso of=${DRIVE} bs=1m

                e_header "Ejecting drive..."
                diskutil eject ${DRIVE}

                [[ $? ]] && e_success "Done"
            else
                e_warning "Aborting, your USB drive will not be formatted at this time."
            fi
        fi
    else
        printf "Skipped USB Drive formatting..."
    fi
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/../utils

run_tails
