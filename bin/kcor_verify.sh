#!/bin/sh

# run on a week, starting from 2 days before the current date
START_DATE=$(date +"%Y%m%d" -d "-9 days")
END_DATE=$(date +"%Y%m%d" -d "-2 days")

BIN_DIR=$(dirname $0)

LOG_FILENAME=/tmp/kcor-$RANDOM.log

$BIN_DIR/kcor_verify_dates.sh "$START_DATE-$END_DATE" &> $LOG_FILENAME
N_FAILED_DAYS=$?

if (( N_FAILED_DAYS > 0 )); then
  SUBJECT="KCor verify for $START_DATE-$END_DATE ($N_FAILED_DAYS failed days)"
else
  SUBJECT="KCor verify for $START_DATE-$END_DATE (success)"
fi

mail -s "$SUBJECT" $(cat ~/.kcor_notifiers) -r $(whoami)@ucar.edu < $LOG_FILENAME

rm -f $LOG_FILENAME
