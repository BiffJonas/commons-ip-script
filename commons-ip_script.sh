#!/usr/bin/env bash

if [ -z $1 ]; then
    echo "No folder to create a SIP from..."
    exit 1
fi

if [ ! -d $1 ];then
    echo "\"$1\" is not a folder"
    exit 1
fi

# DIR="$(cd "$1" && pwd)"
DIR="${1%/}"

read -p "Use standard metadata.xml metadata_file? [Y/n]: " answer
answer="${answer,,}"

case "$answer" in
    y|yes)
        metadata_file="metadata.xml"
        echo "Proceding with $metadata_file as metadata file"
        ;;
    n|no)

        read -p "Provide the name of the metadata standard you use: " metadata_file
        if [ ! -e "$DIR/$metadata_file" ]; then
            echo "./$DIR/$metadata_file Does not exist!"
            exit 1
        fi
        if [[ ! $metadata_file == *.xml ]]; then
            echo "invalid metadata format!!"
            exit 1
        fi
        echo "Using $metadata_file as metadata file"
        ;;
    *)
        echo "Invalid input. Please enter \"yes\" or \"no\""
        exit 1
        ;;
esac

# Make sure a metadata-type is selected
read -p "Type what metadata-type you want: (DC, EAD, WRGSPerson) " metatype
if [ -z "$metatype" ]; then
    echo "A metadata-type is required"
    exit 1
fi

for xsd in "$DIR"/*; do
    if [[ "$xsd" == *.xsd ]]; then
        read -p "Would you like to use $xsd as your schema? [Y,n]: " schema_answer
        schema_answer="${schema_answer,,}"
        case "$schema_answer" in
            y|yes)
                schema="$xsd"
                echo "Proceding with $schema"
                ;;
            n|no)

                read -p "Provide the path to the schema file you would like to use: " schema

                if [[ ! $schema == *.xsd ]]; then
                    echo "invalid schema format!!"
                    exit 1
                fi
                if [ ! -e "$DIR/$schema" ]; then
                    echo "./$DIR/$schema Does not exist!"
                    exit 1
                fi
                schema="$xsd"

                echo "Using $schema as schema"
                ;;
            *)
                echo "Invalid input. Please enter \"yes\" or \"no\""
                exit 1
                ;;
        esac
    fi
done

#Ask if user wants to use custom rep type, otherwise use Original
# read -p "Do you want to choose a custom rep type? [y/N]" rep_type_answer
# rep_type_answer="${rep_type_answer,,}"
# case "$rep_type_answer" in
#     y|yes)
#         read -p "Representation type: (Original, Mixed) " rep_type
#         ;;
#     n|no)

#         rep_type="Original"
#         echo "Proceeding with \"$rep_type\" representation type"
#         ;;
#     *)
#         echo "Invalid input. Please enter \"yes\" or \"no\""
#         exit 1
#         ;;
# esac
rep_type="Original"

read -p "Enter representation name: " rep_name

for sub_dir in "$DIR"/*; do
    if [ -f "$sub_dir" ]; then
        echo -e "\n$sub_dir is a file"

    elif [ -d "$sub_dir" ]; then

        echo -e "\nProcessing directory: $sub_dir"

        current_metadata=""
        #Check if metadata file exists
        for file in "$sub_dir"/*; do
            if [[ "$file" == *_"$metadata_file" ]]; then
                current_metadata="$file"
                break
            fi
        done

        #Create representation data
        rep_data=""
        for file in "$sub_dir"/*; do
            if [ -z "$current_metadata" ] ; then
                echo "directory: $sub_dir, Doesn't have a metadata file"
                break
            elif [ "$file" == "$current_metadata" ]; then
                continue
            else
                rep_data+="--representation-data $file "
            fi
        done

        java -jar ~/Downloads/commons-ip2-cli-2.6.1.jar create --metadata-file $current_metadata --metadata-version=1 --metadata-type $metatype --metadata-schema $schema $rep_data --representation-type "$rep_type" --representation-id $rep_name -p ./SIPOutput

        current_metadata=""

    else
        echo "Unkown type: $sub_dir"
    fi
done


