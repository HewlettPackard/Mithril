#!/bin/bash

BUILD_TAG="04-01-2022-release-1.12-master-a04a4e6"
RESULT_LIST=()

cd terraform/integration-tests

HAS_MISSING_ARTIFACTS=false

for FOLDER in *;
    do
        BUCKET_EXISTS=false
        aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt" --no-cli-pager
        
        if [ $? -eq 0 ];
            then
                BUCKET_EXISTS=true
        fi

        if $BUCKET_EXISTS;
            then
                echo "Artifact object for usecase ${FOLDER} exists"
            else
                echo "Artifact ${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt object for usecase ${FOLDER} does not exist"
                HAS_MISSING_ARTIFACTS=true
        fi
    done

if $HAS_MISSING_ARTIFACTS;
    then
        echo "One or more artifacts do not exist"
        exit 1
    else
        echo "All artifacts found"
fi

HAS_FAILED_TEST=false
for FOLDER in *;
    do
        aws s3 cp "s3://mithril-artifacts/${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt" .
        RESULT=$(tail -n 1 "${BUILD_TAG}-${FOLDER}-result.txt" | grep -oE '^..')
        if [ "$RESULT" == "ok" ];
        then
            echo "Test for usecase ${FOLDER} successful"
        else
            echo "Test for usecase ${FOLDER} failed"
            cat "${BUILD_TAG}-${FOLDER}-result.txt"
            HAS_FAILED_TEST=true
        fi
    done

if $HAS_FAILED_TEST;
    then
        echo "One or more tests have failed"
        exit 1
fi