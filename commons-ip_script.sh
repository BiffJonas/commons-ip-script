#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 ./path/to/source/dir ./path/to/output/dir"
    echo "There must be an \".xsd\" file the the source dir and every dir you want to SIP must have an xml file with the same name"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi
VALID_META_TYPES=("ead" "wrgs_person" "wrgs_arende" "wrgs_kurs")
SOURCE_DIR="$1"
OUTPUT_DIR="$2"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist."
    usage
fi
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Output directory does not exist."
    usage
fi

SOURCE_DIR=${SOURCE_DIR%/}
OUTPUT_DIR=${OUTPUT_DIR%/}
#
# Find schema file and set the metadata-file to the same name as the xsd but with xml file ending
metadata=""
metadata_scheme=""
metadata_file=""

for file in "$SOURCE_DIR"/*; do
    if [[ $file == *.xsd ]]; then
        metadata=$(basename "$file")
        metadata=${metadata%.*}
        metadata_scheme="$metadata.xsd"
        metadata_file="$metadata.xml"
    fi
done

if [[ -z $metadata ]]; then
    echo "No schema file found in $SOURCE_DIR"
    usage
fi

# Check if the schema file is one of the VALID_META_TYPES
valid_scheme=false
for type in "${VALID_META_TYPES[@]}"; do
    if [[ "$metadata_scheme" =~ ${type}_[1-9]|[1-9][0-9]\.xsd ]]; then
        metadata_type="$type"
        valid_scheme=true
    fi
done

if ! $valid_scheme; then
    echo "No valid schema format found"
    echo "Available schema formats: ${VALID_META_TYPES[@]}"
    usage
fi

echo "proceeding with $metadata_scheme"
metadata_scheme="$SOURCE_DIR/$metadata_scheme"

# metadata_type=$(grep -oP "targetNamespace=\"\K[^\"]*" $metadata_scheme)

if [[ -z $metadata ]]; then
    echo "No metadata type found in targetNamespace tag in $metadata_scheme"
    usage
fi

if [[ ! $metadata ]]; then
    echo "No metadata schema found in $SOURCE_DIR"
    usage
fi

for sub_dir in "$SOURCE_DIR"/*; do
    if [[ -f $sub_dir ]]; then
        continue
    fi

    rep_data=""
    current_metadata_file=""
    echo -e "\nProcessing directory: $sub_dir"

    if [[ ! -f $sub_dir/$metadata_file ]]; then
        echo "Directory $sub_dir has $metadata_file file"
    
    fi

    for file in "$sub_dir"/*; do
        if [[ "$file" == "$sub_dir/$metadata_file" ]]; then
            current_metadata_file="$file"
            continue
        else
            rep_data+="--representation-data $file "
        fi
    done

    if [[ -z $current_metadata_file ]]; then
        echo "No metadata-file in $sub_dir"
        continue
    fi

    # echo "java -jar ~/Downloads/commons-ip2-cli-2.6.2.jar create --submitter-name $USER --metadata-file $current_metadata_file --metadata-type $metadata_type --metadata-version=1 --metadata-schema $metadata_scheme $rep_data --representation-id rep1 -p $OUTPUT_DIR"
    java -jar ~/Downloads/commons-ip2-cli-2.6.2.jar create --submitter-name $USER --metadata-file $current_metadata_file --metadata-type $metadata_type --metadata-version=1 --metadata-schema $metadata_scheme $rep_data --representation-id rep1 -p $OUTPUT_DIR
done


