#!/bin/bash

git_branch="iacm-migration-$RANDOM"
csv_file="$1"

# Create Harness workspaces using CSV
echo "Creating workspace in Harness..."
tofu init
tofu apply -var workspace_csv="$csv_file"

# Loop through each workspace entry in CSV
IFS=$'\n'
for workspace in $(cat $csv_file)
do
# Create workspace at start, or in batch?
    tf_path=$(echo $workspace | cut -d',' -f1)   

    echo "Processing $tf_path"

    last_working_dir=$(pwd)
    cd $tf_path

    echo "Removing Backend configuration..."

    for tf in $(ls *.tf)
    do
        # Get 'terraform {backend {..}}'' block
        backend_block=$(cat $tf | hcledit block get terraform.backend)

        # Only modify files with a terraform backend block
        if [ ! -z "$backend_block" ]
        then
            # Change spaces in backend block into a regex whitespace match, to handle whitespace getting chomped from hcledit
            regex=$(perl -0777 -pe "s/\s+/\\\s*/igs" <(echo -n $backend_block))

            # Remove backend block match via regex (working around hcledit "hcledit block get terraform.backend" working, but not "hcledit block rm terraform.backend")
            perl -0777 -pe "s/$regex//igs" $tf
        fi
    done

    # Migrate state
    echo "Migrating state..."
    tofu init -migrate-state

    # commit and push chnages to git
    git checkout -b "$git_branch"
    git commit -a -m "Remove backend configuration"
    git push -u origin "$git_branch"

    cd $last_working_dir
done
