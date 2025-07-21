#!/bin/bash

csv_file="$1"
git_branch="iacm-migration-$RANDOM"

# Set TF password for backend to match HARNESS_PLATFORM_API_KEY already set by env file
export TF_HTTP_PASSWORD="$HARNESS_PLATFORM_API_KEY"

# Set env variables needed for tofu workspace creation and state migration
export $(cat .env | xargs)

# Create Harness workspaces using CSV
echo "Creating workspace in Harness..."
tofu init
tofu apply -var workspace_csv="$csv_file"

# Loop through each workspace entry in CSV to initalize workspace
first_loop=true
IFS=$'\n'
for workspace in $(cat $csv_file)
do
    if [ "$first_loop" == true ]; then
        # Skip csv header
        first_loop=false
    else
        tf_path=$(echo $workspace | cut -d',' -f1)
        workspace_id=$(echo $workspace | cut -d',' -f3)
        account_id="$HARNESS_ACCOUNT_ID"
        org_id=$(echo $workspace | cut -d',' -f4)
        project_id=$(echo $workspace | cut -d',' -f5)

        echo "Processing $tf_path"

        last_working_dir=$(pwd)
        cd $tf_path

        tofu init

        echo "Removing Backend configuration..."

        for tf in $(ls *.tf)
        do
            # Get 'terraform {backend {..}}'' block
            backend_block=$(cat $tf | hcledit block get terraform.backend)

            # Get cloud block if backend is empty
            if [ -z "$backend_block" ]
            then
                backend_block=$(cat $tf | hcledit block get terraform.cloud)
            fi

            # Only modify files with a terraform backend/cloud block
            if [ ! -z "$backend_block" ]
            then
                # Change spaces in backend block into a regex whitespace match, to handle whitespace getting chomped from hcledit
                regex_noslashes=$(perl -0777 -pe "s#/#\\\/#igs" <(echo -n $backend_block))
                regex=$(perl -0777 -pe "s/\s+/\\\E\\\s*\\\Q/igs" <(echo $regex_noslashes))

                # Remove backend block match via regex (working around hcledit "hcledit block get terraform.backend" working, but not "hcledit block rm terraform.backend")
                perl -0777 -i -pe "s/\Q$regex\E//igs" $tf
            fi
        done

        # Create new backend configuration
        cat >harness-backend.tf <<EOF
terraform {
  backend "http" {
    address = "https://app.harness.io/gateway/iacm/api/orgs/$org_id/projects/$project_id/workspaces/$workspace_id/terraform-backend?accountIdentifier=$account_id"
    username = "harness"
    lock_address = "https://app.harness.io/gateway/iacm/api/orgs/$org_id/projects/$project_id/workspaces/$workspace_id/terraform-backend/lock?accountIdentifier=$account_id"
    lock_method = "POST"
    unlock_address = "https://app.harness.io/gateway/iacm/api/orgs/$org_id/projects/$project_id/workspaces/$workspace_id/terraform-backend/lock?accountIdentifier=$account_id"
    unlock_method = "DELETE"
    }
}
EOF

        # Migrate state
        echo "Migrating state..."
        tofu init -migrate-state

        # commit and push chnages to git
        git checkout -b "$git_branch"
        git add harness-backend.tf
        git commit -a -m "Remove backend configuration"
        git push -u origin "$git_branch"

        cd $last_working_dir
    fi
done
