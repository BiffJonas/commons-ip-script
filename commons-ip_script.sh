#!/usr/bin/env bash

usage() {
    echo "Usage: $0 ./path/to/source/dir [-m (EAD, WRGSPerson, WRGSArende, WRGSKurs)] [-o ./path/to/output/dir]"
    exit 1
}

source_dir=$1
shift

available_metadata_types=("ead" "wrgsperson" "wrgsarende" "wrgskurs")
# Process options
while getopts ":m:o:h" option; do
    case $option in
        m)
            metadata_type="${OPTARG,,}"
            echo $metadata_type
            # Check if the provided metadata type is valid
            if [[ ! " ${available_metadata_types[@]} " =~ " $metadata_type " ]]; then
                echo "Invalid metadata type: $metadata_type"
                usage
            fi
            ;;
        o)
            output_dir="$OPTARG"
            ;;
        h)
            echo help
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Check if source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Source directory does not exist."
    usage
fi
if [ -z "$output_dir" ]; then
    echo "Output directory does not exist."
    usage
fi
if [ -z "$metadata_type" ]; then
    echo "No metadata_type"
    usage
fi

metadata_exists=false
schema_exists=false
schema=""
metadata=""

echo $source_dir
for file in "$source_dir"*; do
    if [[ -d $file ]]; then
        continue
    fi
    if [[ $file == *.xml ]]; then
        metadata_exists=true
        metadata=$file
        echo "found metadata file in source dir: $metadata"
    fi
    if [[ $file == *.xsd ]]; then
        schema_exists=true
        schema=$file
        echo "found schema file in source dir: $schema"
    fi
done

if [[ ! $metadata_exists ]]; then
    echo "No metadata found in $source_dir"
    usage
fi
if [[ ! $schema_exists ]]; then
    echo "No schema found in $source_dir"
    usage
fi

for sub_dir in "$source_dir"*; do
    if [[ -f $sub_dir ]]; then
        continue
    fi

    rep_data=""
    echo -e "\nProcessing directory: $sub_dir"

    for file in "$sub_dir"/*; do
        if [[ "$file" == *metadata.xml ]]; then
            continue
        else
            rep_data+="--representation-data $file "
        fi
    done

    java -jar ~/Downloads/commons-ip2-cli-2.6.1.jar create --metadata-file $metadata --metadata-version=1 --metadata-type $metadata_type --metadata-schema $schema $rep_data --representation-id rep1 -p $output_dir
done


