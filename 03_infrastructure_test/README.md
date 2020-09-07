# Infrastructure Test

This is my attempt at IaaS. I've not used Terraform before, nor Azure, so this was a fun challenge.

Because this is my first time, I'm sure there are many issues / recommendations that could be made, given more research / time. I'd appreciate any tips.

## Architecture

In this example terraform config, the following infrastructure is generated:

- Resource Group (Azure UK South Zone)
-- Virtual Network (10.0.0.0/16)
--- Virtual Private Subnet (10.0.1.0/24)
---- Virtual Machine 1 & NIC (10.0.1.10 / Public IP)
---- Virtual Machine 2 & NIC (10.0.1.11 / Public IP)

Virtual Machine 1 runs Ubuntu 18.04 with Nginx installed (with config from the provided `nginx-config` file).
It proxies Virtual Machine 2's application on port 5000 to port 80.
It does this via the private network.

Virtual Machine 2 runs Ubuntu 18.04 with Python3.
It runs the Coding Test (Artistics) application on port 5000.

### Future Improvements

With more time I would:

- Security groups / rules should be applied to only allow SSH connections and port 80 on VM1 to the public.
- Use SSH keys for login rather than username / password, for greater security for public accessable SSH.
- Employ some form of updating mechanism for OS patches etc.

## Deployment

The standard terraform deployment method is appropriate here, follow https://learn.hashicorp.com/tutorials/terraform/azure-build to setup your Azure account.

Then run `terraform init` and `terraform apply` to deploy it.

The script will install two VMs inside a private network. Output to `public_ips.txt` in this directory will include the IP's of the deployed hosts.
