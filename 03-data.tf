# Data Sources
#
# External data sources used to fetch dynamic values

# Get the latest available ARO version for the specified location
# This is only executed when aro_version variable is not provided (null or empty)
# Using count to conditionally create this data source
data "external" "aro_latest_version" {
  count = var.aro_version == null || var.aro_version == "" ? 1 : 0

  program = ["bash", "-c", <<-EOT
    # Get the latest version using JMESPath query to select last array element
    latest=$(az aro get-versions -l "${var.location}" --query '[-1]' --output tsv 2>/dev/null)

    # Use default if latest is empty (fallback if command fails)
    if [ -z "$latest" ]; then
      latest="4.16.30"
    fi

    # Output as JSON for external data source
    echo "{\"version\": \"$latest\"}"
  EOT
  ]
}
