# AWS Security Notifier

![AWS Architecture](https://img.shields.io/badge/AWS-Security-orange?style=for-the-badge&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-Infrastructure%20as%20Code-purple?style=for-the-badge&logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=for-the-badge&logo=python&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

A production-grade, serverless security monitoring solution built on AWS using **Terraform** and **Python**. This project automatically captures critical security events (such as unauthorized API calls, root account activity, or IAM changes) across multiple AWS regions and routes formatted alerts directly to a **Discord** channel in real-time.

---

## Architecture & Data Flow

1. **AWS CloudTrail** records all account API activity globally (`is_multi_region_trail = true`).
2. **Amazon EventBridge** (formerly CloudWatch Events) listens for specific high-privilege or security-sensitive API calls.
3. **AWS Lambda** (Python 3.11) processes the event payload, translates it into a readable format, and injects custom metadata.
4. **Discord Webhook** securely receives the rich-text alert for immediate team visibility.

---

## Key Features

* **Global Visibility:** Monitors multi-region CloudTrail logs to catch security events regardless of where they occur in the AWS account.
* **Infrastructure as Code (IaC):** Fully provisioned via Terraform for reproducibility, clean state management, and easy teardown.
* **Real-time Discord Alerts:** Custom Lambda logic formats raw JSON logs into clean, human-readable security notifications.
* **Security Best Practices:** Strict adherence to least-privilege IAM roles, separation of sensitive variables using `.gitignore`, and secure environment variable injection for webhooks.

---

## Tech Stack

* **Cloud Provider:** Amazon Web Services (AWS)
* **Infrastructure as Code:** Terraform
* **Serverless Compute:** AWS Lambda (Python 3.11)
* **Monitoring & Auditing:** AWS CloudTrail, Amazon EventBridge
* **Notification Integration:** Discord Webhooks

---

## Project Structure

    aws-security-notifier/
    ├── lambda_function.py   # Lambda function core logic (Python)
    ├── main.tf              # Terraform configuration (Lambda, EventBridge, IAM)
    ├── variables.tf         # Terraform input variables
    ├── .gitignore           # Excludes sensitive files and build artifacts
    └── README.md            # Project documentation

---

## Setup & Deployment Guide

### Prerequisites
* [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate administrative/deployment permissions.
* [Terraform](https://www.terraform.io/) installed locally (v1.0+).
* A **Discord Server** with a Webhook URL generated for your target channel.

### 1. Clone the Repository
    git clone https://github.com/Jnanek1/aws-security-notifier.git
    cd aws-security-notifier

### 2. Configure Variables
Create a `terraform.tfvars` file in the root directory and provide your Discord Webhook URL:

    DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

*(Note: `terraform.tfvars` is ignored by `.gitignore` to prevent secret leakage).*

### 3. Deploy with Terraform
Initialize the Terraform working directory and apply the configuration:
    
    terraform init
    terraform apply
    
Confirm the prompt with `yes` to provision the resources on AWS.

---

## Testing the Integration

To verify that the alerting pipeline works correctly, you can trigger a monitored action in your AWS account (e.g., creating an access key, modifying an IAM role, or enabling an MFA device via AWS CLI/Console). 

A formatted security notification will instantly appear in your configured Discord channel!

---

## Cleanup (Teardown)

To avoid incurring any unexpected AWS charges, you can instantly destroy all created infrastructure using Terraform:
    
    terraform destroy




## License

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.