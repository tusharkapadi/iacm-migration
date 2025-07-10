locals {
  workspaces = [for workspace in csvdecode(file("${path.module}/${var.workspace_csv}")) : {
    tf_variables = jsondecode(file("${path.module}/${workspace.tf_variables_json}"))
    env_variables = jsondecode(file("${path.module}/${workspace.env_variables_json}"))
    tf_variable_files = workspace.tf_variable_files == "" ? null : jsondecode(file("${path.module}/${workspace.tf_variable_files_json}")) #FIXNOW
    workspace_path                    = workspace.workspace_path # Not used to create workspaces, but use as index in the workspaces_map, and required to be in file for migration
    # TODO replace workspace_path with different key to remove requirement on this field, since it's not used when only creating a new workspace
    workspace_name                    = workspace.workspace_name
    workspace_id              = workspace.workspace_id
    org_id                  = workspace.org_id
    project_id              = workspace.project_id
    provisioner_type        = lower(workspace.provisioner_type)
    provisioner_version     = workspace.provisioner_version
    repository              = workspace.repository
    repository_branch       = workspace.repository_branch
    repository_path         = workspace.repository_path
    cost_estimation_enabled = workspace.cost_estimation_enabled == "false" ? false : true # default to true
    provider_connector_id      = workspace.provider_connector_id
    github_connector_id    = workspace.github_connector_id
  }]

  workspaces_map = tomap({ for ws in local.workspaces : ws.workspace_path => ws })

}

resource "harness_platform_workspace" "workspace" {
  for_each = local.workspaces_map
  name                    = each.value.workspace_name
  identifier              = each.value.workspace_id
  org_id                  = each.value.org_id
  project_id              = each.value.project_id
  provisioner_type        = each.value.provisioner_type
  provisioner_version     = each.value.provisioner_version
  repository              = each.value.repository
  repository_branch       = each.value.repository_branch
  repository_path         = each.value.repository_path
  cost_estimation_enabled = each.value.cost_estimation_enabled # default to true
  provider_connector      = each.value.provider_connector_id
  repository_connector    = each.value.github_connector_id

  dynamic "terraform_variable" {
    for_each = each.value.tf_variables
    content {
      key = terraform_variable.value["key"]
      value = terraform_variable.value["value"]
      value_type = terraform_variable.value["value_type"]
    }
  }

  dynamic "environment_variable" {
    for_each = each.value.env_variables
    content {
      key = environment_variable.value["key"]
      value = environment_variable.value["value"]
      value_type = environment_variable.value["value_type"]
    }
  }

  dynamic "terraform_variable_file" {
    for_each = each.value.tf_variable_files
    content {
      repository           = terraform_variable_file.value["repository"]
      repository_branch    = terraform_variable_file.value["repository_branch"]
      repository_path      = terraform_variable_file.value["repository_path"]
      repository_connector = terraform_variable_file.value["repository_connector"]
    }
  }

#   variable_sets = [harness_platform_infra_variable_set.test.id]

#   default_pipelines = {
#     "destroy" = "destroy_pipeline_id"
#     "drift"   = "drift_pipeline_id"
#     "plan"    = "plan_pipeline_id"
#     "apply"   = "apply_pipeline_id"
#   }
}