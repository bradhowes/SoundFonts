#!/bin/bash

CMD="xcrun simctl"
APP="com.braysoftware.SoundFonts"

# List of devices to populate with files from staging. Run `xcrun simctl list devices` and update
# entries below with the right UUID values.
DEVICES=( "3CFCCF00-20ED-4235-9738-62168A7E612D"  # iPhone 12 Pro Max
          "EBBF6C18-1B03-47CD-B14D-D9E9147650B4"  # iPhone 8 Plus
          "289BDD20-0B22-466D-809D-A13BAEBBD140"  # iPad Pro (12.9-inch) (2nd generation)
          "CA4F44FA-9393-4D80-8955-974FC0CEA47B" ) # iPad Pro (12.9-inch) (4th generation)

# Device to consider as the master, the one that will be used as the source for the rest
MASTER="6B7B61BD-A280-4E68-9E0C-455CDF81A853" # iPhone SE (2nd generation)
MASTER="EBBF6C18-1B03-47CD-B14D-D9E9147650B4" # iPhone 8 Plus

CONTAINER=""
function get_app_container # DEVICE
{
    set -- $(${CMD} get_app_container "${1}" "${APP}" groups)
    CONTAINER="${2}"
}

# Update the staging area with files from the MASTER container
function update_staging
{
    ${CMD} boot "${MASTER}"
    ${CMD} terminate "${MASTER}" "${APP}"
    get_app_container "${MASTER}"
    echo "-- master container ${CONTAINER}"
    cp "${CONTAINER}"/* staging/
}

# Update the devices with the files found in staging directory
function push_staging
{
    for DEVICE in "${DEVICES[@]}"; do
        ${CMD} boot "${DEVICE}"
        ${CMD} terminate "${DEVICE}" "${APP}"
        get_app_container "${DEVICE}"
        echo "-- container ${CONTAINER}"
        cp staging/* "${CONTAINER}"
        # ls "${CONTAINER}"
        # ${CMD} launch "${DEVICE}" "${APP}"
    done
}

case "${1}" in
    "update") update_staging ;;
    "push") push_staging ;;
    *) echo "** invalid command - supply 'update' or 'push'" ;;
esac
