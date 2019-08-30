#!/bin/bash
set -e

function help_text {
    cat <<EOF
    Usage: $0 [ -c|--clear-logs ] [ -u|--upload-report ] [ -r|--report-bucket REPORT_BUCKET ] [-h]

        --clear-logs                    (optional) Clear the log folder in the S3 bucket after creating the report.
        --upload-report                 (optional) Upload HTML report to S3 bucket.
        --report-bucket REPORT_BUCKET   (required) name of the S3 bucket to download logs from and upload the reports to.
EOF
    exit 1
}

CLEAR_LOGS=false
UPLOAD_REPORT=false

while [ $# -gt 0 ]; do
    arg=$1
    case $arg in
        -h|--help)
            help_text
        ;;
        -r|--report-bucket)
            REPORT_BUCKET="$2"
            shift; shift
        ;;
        -c|--clear-logs)
            CLEAR_LOGS=true
            shift; shift;
        ;;
        -u|--upload-report)
            UPLOAD_REPORT=true
            shift; shift;
        ;;
        *)
            echo "ERROR: Unrecognised option: ${arg}"
            help_text
            exit 1
        ;;
    esac
done

if [[ -z $REPORT_BUCKET ]]
then
    echo "Report bucket required."
    help_text
    exit 1
fi

# Determine script dir
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}/..

FOLDER="report"

rm -f -r target/gatling/*
## Download all logs for all test gatling clients
aws s3 cp s3://${REPORT_BUCKET}/logs/ target/gatling/${FOLDER} --recursive --no-progress

## Consolidate reports from these clients
mvn -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn gatling:test -DgenerateReport=true

## Workaround for Gatling plugin Jenkins, mv html report to simulation folder
mv target/gatling/* target/gatling/${FOLDER} 2> /dev/null || exit 0
