# IaCM Migration Utility

## Prerequisites

### Dependencies
* terraform
* openTofu
* git
* [hcledit](https://github.com/minamijoyo/hcledit)
* perl
* VSCode or Terminal to execute commands

### Setup
* Create `.env` file with your Harness account ID and api key, using `.env.example` as an example
* Copies of working directories for each workspace to be migrated should be put under the `./workspaces` directory
* Fill out the `input.csv` file with the correct values for each workspace

## Usage

* Set TF_HTTP_PASSWORD environment variable to supply your Personal Access Token to Terraform
`export $TF_HTTP_PASSWORD=<Harness API key>`
* Run the migration utility, 
`./run.sh input.csv`
