# Using Terraform to build an ARO cluster

Azure Red Hat OpenShift (ARO) is a fully-managed turnkey application platform.

Supports Public ARO clusters and Private ARO clusters.

## Setup

Using the code in the repo will require having the following tools installed:

- The Terraform CLI (>= 1.12)
- The Azure CLI (`az`)
- The OC CLI (for cluster access)

Optional tools (for enhanced testing):
- tflint (for Terraform linting)
- checkov (for security scanning)

## Create the ARO cluster and required infrastructure

### Public ARO cluster

1. Create a local variables file

   ```bash
   make tfvars
   ```

1. Modify the `terraform.tfvars` var file, you can use the `variables.tf` to see the full list of variables that can be set.

   >NOTE: You can define the subscription_id needed for the Auth using ```export TF_VAR_subscription_id="xxx"``` as well.

1. Deploy your cluster

   ```bash
   make create
   ```

   NOTE: By default the ingress_profile and the api_server_profile is both Public, but can be change using the [TF variables](https://github.com/rh-mobb/terraform-aro/blob/main/01-variables.tf).

   NOTE: The `aro_version` variable is optional. If not specified, the latest available ARO version for your region will be automatically detected using `az aro get-versions -l <location>`.

### Private ARO cluster

1. Modify the `terraform.tfvars` var file, you can use the `variables.tf` to see the full list of variables that can be set.

   ```bash
   make create-private
   ```

   >NOTE: restrict_egress_traffic=true will secure ARO cluster by routing [Egress traffic through an Azure Firewall](https://learn.microsoft.com/en-us/azure/openshift/howto-restrict-egress).

   >NOTE2: Private Clusters can be created [without Public IP using the UserDefineRouting](https://learn.microsoft.com/en-us/azure/openshift/howto-create-private-cluster-4x#create-a-private-cluster-without-a-public-ip-address) flag in the outboundtype=UserDefineRouting variable. By default LoadBalancer is used for the egress.

## Test Connectivity

### Quick Login (Recommended)

After deploying your cluster, you can log in using the `make login` target:

```bash
make login
```

This command will:
- Automatically retrieve cluster information from Terraform outputs
- Fetch kubeadmin credentials from Azure
- Log you into the OpenShift cluster using `oc login`

### Manual Login Steps

If you prefer to log in manually or need to access cluster information directly:

1. Get the ARO cluster's api server URL.

   ```bash
   ARO_URL=$(terraform output -raw api_url)
   echo $ARO_URL
   ```

1. Get the ARO cluster's Console URL

   ```bash
   CONSOLE_URL=$(terraform output -raw console_url)
   echo $CONSOLE_URL
   ```

1. Get the ARO cluster's credentials.

   ```bash
   CLUSTER_NAME=$(terraform output -raw cluster_name)
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   ARO_USERNAME=$(az aro list-credentials -n $CLUSTER_NAME -g $RESOURCE_GROUP -o json | jq -r '.kubeadminUsername')
   ARO_PASSWORD=$(az aro list-credentials -n $CLUSTER_NAME -g $RESOURCE_GROUP -o json | jq -r '.kubeadminPassword')
   echo $ARO_PASSWORD
   echo $ARO_USERNAME
   ```

### Public Test Connectivity

1. Log into the cluster using oc login command. ex.

    ```bash
    oc login $ARO_URL -u $ARO_USERNAME -p $ARO_PASSWORD
    ```

   Or simply use:

    ```bash
    make login
    ```

1. Check that you can access the Console by opening the console url in your browser.

### Private Test Connectivity

1. Save the jump host public IP address

    ```bash
   JUMP_IP=$(terraform output -raw public_ip)
   echo $JUMP_IP
   ```

   Or get it manually:

    ```bash
   CLUSTER_NAME=$(terraform output -raw cluster_name)
   RESOURCE_GROUP=$(terraform output -raw resource_group_name)
   JUMP_IP=$(az vm list-ip-addresses -g $RESOURCE_GROUP -n $CLUSTER_NAME-jumphost -o tsv \
   --query '[].virtualMachine.network.publicIpAddresses[0].ipAddress')
   echo $JUMP_IP
   ```

1. update /etc/hosts to point the openshift domains to localhost. Use the DNS of your openshift cluster as described in the previous step in place of $YOUR_OPENSHIFT_DNS below

   ```bash
   127.0.0.1 api.$YOUR_OPENSHIFT_DNS
   127.0.0.1 console-openshift-console.apps.$YOUR_OPENSHIFT_DNS
   127.0.0.1 oauth-openshift.apps.$YOUR_OPENSHIFT_DNS
   ```

1. SSH to that instance, tunneling traffic for the appropriate hostnames. Be sure to use your new/existing private key, the OpenShift DNS for $YOUR_OPENSHIFT_DNS and your Jumphost IP

   ```bash
   sudo ssh -L 6443:api.$YOUR_OPENSHIFT_DNS:6443 \
   -L 443:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:443 \
   -L 80:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:80 \
   aro@$JUMP_IP
   ```

1. Log in using oc login

   ```bash
   oc login $ARO_URL -u $ARO_USERNAME -p $ARO_PASSWORD
   ```

   Or use the automated login command (works from your local machine if you have SSH tunnel set up):

   ```bash
   make login
   ```

NOTE: Another option to connect to a Private ARO cluster jumphost is the usage of [sshuttle](https://sshuttle.readthedocs.io/en/stable/index.html). If we suppose that we deployed ARO vnet with the `10.0.0.0/20` CIDR we can connect to the cluster using (both API and Console):

```bash
sshuttle --dns -NHr aro@$JUMP_IP 10.0.0.0/20 --daemon
```

and opening a browser the `api.$YOUR_OPENSHIFT_DNS` and `console-openshift-console.apps.$YOUR_OPENSHIFT_DNS` will be reachable.

## Development and Testing

### Running Tests

Before committing changes, run the pre-commit checks:

```bash
make pr
```

This will run:
- Terraform validate
- Terraform fmt check
- tflint (if installed)
- checkov security scan (if installed)

For a full test suite including terraform plan (requires Azure CLI login):

```bash
make test
```

### GitHub Actions

This repository includes a GitHub Actions workflow that automatically runs pre-commit checks on:
- Pull requests to `main`
- Pushes to `main`

The workflow will:
- Run `make pr` to validate code
- Post a comment on PRs with check results
- Cache Terraform providers for faster runs

See `.github/workflows/pr.yml` for details.

### Available Makefile Targets

- `make help` - Show README
- `make tfvars` - Create terraform.tfvars from example
- `make init` - Initialize Terraform
- `make create` - Create public ARO cluster
- `make create-private` - Create private ARO cluster with egress restriction
- `make create-private-noegress` - Create private ARO cluster without egress restriction
- `make login` - Log into ARO cluster (requires cluster to be deployed)
- `make destroy` - Destroy cluster (interactive)
- `make destroy-force` - Destroy cluster (non-interactive)
- `make clean` - Remove terraform state and providers
- `make validate` - Run terraform validate
- `make fmt` - Check terraform formatting
- `make fmt-fix` - Fix terraform formatting
- `make check` - Run validate and fmt checks
- `make lint` - Run linting checks
- `make test` - Run full test suite (requires Azure CLI)
- `make pr` - Run pre-commit checks (no Azure CLI needed)

## Releasing a New Version

This repository follows [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH).

### Version Bumping Guidelines

- **MAJOR** (1.0.0): Breaking changes (renamed variables, changed types, removed features)
- **MINOR** (0.2.0): New features (new variables/outputs, backward-compatible additions)
- **PATCH** (0.1.1): Bug fixes (fixes, documentation updates)

### Release Checklist

When ready to release a new version:

1. **Ensure all tests pass:**
   ```bash
   make test
   ```

2. **Update CHANGELOG.md:**
   - Move all `[Unreleased]` content to a new version section (e.g., `## [0.2.0] - YYYY-MM-DD`)
   - Add link at bottom: `[0.2.0]: https://github.com/rh-mobb/terraform-aro/releases/tag/v0.2.0`
   - Update `[Unreleased]` link: `[Unreleased]: https://github.com/rh-mobb/terraform-aro/compare/v0.2.0...HEAD`

3. **Update PLAN.md version** (if applicable)

4. **Commit changes:**
   ```bash
   git add CHANGELOG.md PLAN.md
   git commit -m "chore: prepare release v0.2.0"
   ```

5. **Create annotated git tag:**
   ```bash
   git tag -a v0.2.0 -m "Release v0.2.0: Brief description of changes"
   ```

6. **Push commits and tag:**
   ```bash
   git push origin main
   git push origin v0.2.0
   ```

7. **Create GitHub Release** (optional but recommended):
   - Go to GitHub Releases page
   - Click "Draft a new release"
   - Select the tag (e.g., `v0.2.0`)
   - Copy CHANGELOG.md content as release notes
   - Publish release

**Note:** During pre-1.0.0 phase, breaking changes can be in MINOR versions. Move to 1.0.0 when the API is stable.

## Cleanup

1. Delete Cluster and Resources

    ```bash
    make destroy-force
    ```
