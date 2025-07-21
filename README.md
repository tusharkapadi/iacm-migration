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

* Run the migration utility, 
`./run.sh input.csv`
