# CC_EmaanHanif_17-LabProject_FrontendBackend

Pharmacy App: Automated Multi-Tier Deployment
This project automates the provisioning of AWS infrastructure and the configuration of a high-availability web architecture using Terraform and Ansible Roles.

🏗️ Architecture Overview
1 Frontend Server: Nginx load balancer distributing traffic to backends.

3 Backend Servers: Apache (httpd) nodes serving distinct web content.

High Availability: 2 Primary backends + 1 Backup backend.

Network: Custom VPC, public subnet, and security groups restricted to the administrator's IP.

🛠️ Project Tasks & Implementation
1. Terraform: Networking & Architecture
Dynamic Networking: Configured a VPC with a CIDR block from variables and a public subnet with an Internet Gateway.

Security Groups: Restricted SSH access (Port 22) to the administrator's specific public IP using locals and icanhazip.com.

Global Access: Opened HTTP (Port 80) globally to allow end-users to access the frontend.

2. Terraform: EC2 Instances
Frontend Node: Provisioned a single instance tagged as ${var.env_prefix}-frontend.

Backend Cluster: Used count = 3 to deploy a cluster of backend instances with unique tags.

Reporting: Configured outputs.tf to display all public and private IPs for verification.

3. Ansible: Global Config & Inventory
Ansible Environment: Configured ansible.cfg to disable host key checking and set the Python 3 interpreter.

Dynamic Inventory: Automated the creation of the ansible/inventory/hosts file using a Terraform local_file resource to map AWS public IPs to Ansible groups.

4. Ansible Role: Backend (Apache)
Software Stack: Installed and enabled the httpd service on all three nodes.

Dynamic Content: Deployed a unique index page for each server using a Jinja2 template that displays the server's private IP.

Pharmacy Branding: Applied custom CSS with pink headers and white backgrounds.

5. Ansible Role: Frontend (Nginx)
Load Balancing: Configured Nginx as a reverse proxy using the upstream directive.

HA Strategy: Implemented the 2 Primary + 1 Backup requirement, ensuring the backup node only activates if primary nodes fail.

Private Connectivity: Utilized backend private IPs for internal communication to improve security and performance.

6. Ansible Main Playbook
Role Orchestration: Created playbooks/site.yaml to execute the backend and frontend roles sequentially.

Dynamic Fact Gathering: Used hostvars to pull backend private IPs from the inventory directly into the frontend configuration.

7. Full Automation (Terraform-Ansible Integration)
Zero-Manual Steps: Implemented a null_resource with a local-exec provisioner.

Dependency Chain: The automation ensures Ansible only runs after EC2 instances are fully ready and the inventory file is written.

Final Result: Running terraform apply -auto-approve results in a fully functional, configured web environment.

🚀 How to Run
Initialize: Install necessary providers.

###########################
terraform init -upgrade
###########################
Deploy: Provision AWS resources and trigger Ansible.
###########################
terraform apply -auto-approve
###########################
Verify: Access the site at the frontend_public_ip output by Terraform.

