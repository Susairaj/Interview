The Ultimate DevOps & AWS Mastery Guide
From Zero to Production — Every Concept, Every Command
TABLE OF CONTENTS
text

PART 1:  DevOps Fundamentals
PART 2:  Linux & Networking Essentials
PART 3:  Version Control (Git)
PART 4:  CI/CD Pipelines
PART 5:  AWS Core Concepts & IAM
PART 6:  EC2 — Elastic Compute Cloud (All Purchase Options)
PART 7:  VPC — Virtual Private Cloud (Networking Deep Dive)
PART 8:  NAT Gateway & NAT Instance
PART 9:  Security Groups & NACLs
PART 10: Elastic Load Balancing (ALB, NLB, CLB)
PART 11: Auto Scaling
PART 12: S3 — Simple Storage Service
PART 13: Route 53 — DNS
PART 14: IAM — Identity & Access Management (Deep Dive)
PART 15: RDS & DynamoDB (Databases)
PART 16: Lambda — Serverless Computing
PART 17: Docker & Containerization
PART 18: ECR — Elastic Container Registry
PART 19: ECS — Elastic Container Service
PART 20: EKS — Elastic Kubernetes Service
PART 21: AWS Fargate
PART 22: WAF — Web Application Firewall
PART 23: CloudFront — CDN
PART 24: CloudWatch — Monitoring
PART 25: CloudFormation & Terraform (IaC)
PART 26: SNS & SQS — Messaging
PART 27: CodePipeline, CodeBuild, CodeDeploy
PART 28: Port Forwarding & Bastion Hosts
PART 29: Secrets Manager & Parameter Store
PART 30: Real-World Architecture — Putting It All Together
PART 1: DevOps FUNDAMENTALS
1.1 What is DevOps?
text

Traditional Model:
┌─────────────┐         wall of confusion        ┌─────────────┐
│ Development  │ ──────────── ✖ ─────────────────▶│  Operations  │
│  (writes     │    "Here's the code,             │  (deploys &  │
│   code)      │     good luck!"                  │   maintains) │
└─────────────┘                                   └─────────────┘

DevOps Model:
┌───────────────────────────────────────────────────────────────┐
│              Dev + Ops = ONE UNIFIED TEAM                     │
│                                                               │
│  Plan → Code → Build → Test → Release → Deploy → Monitor     │
│   ▲                                                     │     │
│   └─────────────── Feedback Loop ◀──────────────────────┘     │
└───────────────────────────────────────────────────────────────┘
DevOps is a culture + set of practices that brings Development and Operations together so software can be delivered faster, more reliably, and with continuous feedback.

1.2 The DevOps Lifecycle (Infinity Loop)
text

        ┌──── PLAN ◀──── MONITOR ────┐
        │                             │
        ▼                             │
      CODE                        OPERATE
        │                             ▲
        ▼                             │
      BUILD                       DEPLOY
        │                             ▲
        ▼                             │
      TEST ────▶ RELEASE ─────────────┘
Phase	Tools	Purpose
Plan	Jira, Trello	Define tasks & sprints
Code	Git, GitHub, VS Code	Write application code
Build	Maven, npm, Docker	Compile & package
Test	JUnit, Selenium, SonarQube	Automated testing
Release	Jenkins, GitHub Actions, CodePipeline	Approve for deployment
Deploy	Ansible, Terraform, ECS, K8s	Push to production
Operate	AWS, Kubernetes, Docker	Run & manage infra
Monitor	CloudWatch, Prometheus, Grafana	Observe & alert
1.3 Key DevOps Principles
text

1. AUTOMATION        → Automate everything repeatable
2. CI/CD             → Continuously integrate and deploy code
3. IaC               → Infrastructure as Code (Terraform, CloudFormation)
4. MONITORING        → Observe everything, alert on anomalies
5. COLLABORATION     → Break silos between Dev and Ops
6. MICROSERVICES     → Small, independent, deployable services
7. SECURITY (DevSecOps) → Shift security left into the pipeline
PART 2: LINUX & NETWORKING ESSENTIALS
2.1 Essential Linux Commands
Bash

# ──────────────── FILE SYSTEM NAVIGATION ────────────────
pwd                          # Print current directory
ls -la                       # List all files with details
cd /var/log                  # Change directory
mkdir -p /app/config         # Create nested directories
rm -rf /tmp/old-files        # Remove directory recursively (CAREFUL!)
find / -name "*.log" -size +100M   # Find large log files

# ──────────────── FILE OPERATIONS ────────────────
cat /etc/os-release          # View file content
tail -f /var/log/syslog      # Follow log file in real-time
grep -r "error" /var/log/    # Search for "error" in all log files
sed -i 's/old/new/g' file.txt  # Find and replace in file
awk '{print $1}' access.log  # Print first column

# ──────────────── USER & PERMISSIONS ────────────────
whoami                       # Current user
sudo useradd devops          # Create user
sudo passwd devops           # Set password
chmod 755 script.sh          # rwxr-xr-x
chown user:group file.txt    # Change ownership

# Permission breakdown:
# rwx rwx rwx  = 777
# ─┬─ ─┬─ ─┬─
#  │   │   └── Others
#  │   └────── Group
#  └────────── Owner
# r=4, w=2, x=1

# ──────────────── PROCESS MANAGEMENT ────────────────
ps aux                       # List all processes
top                          # Real-time process monitor
htop                         # Better process monitor
kill -9 <PID>                # Force kill process
systemctl status nginx       # Check service status
systemctl restart nginx      # Restart service
journalctl -u nginx -f       # Follow service logs

# ──────────────── DISK & MEMORY ────────────────
df -h                        # Disk usage (human readable)
du -sh /var/*                # Directory sizes
free -h                      # Memory usage
2.2 Networking Essentials
Bash

# ──────────────── NETWORK COMMANDS ────────────────
ifconfig                     # Show network interfaces (legacy)
ip addr show                 # Show network interfaces (modern)
ip route show                # Show routing table
ping google.com              # Test connectivity
traceroute google.com        # Trace network path
nslookup example.com         # DNS lookup
dig example.com              # Detailed DNS lookup
netstat -tulpn               # Show listening ports
ss -tulpn                    # Modern replacement for netstat
curl -v https://example.com  # HTTP request with verbose output
wget https://example.com/file.zip  # Download file

# ──────────────── FIREWALL (iptables/firewalld) ────────────────
sudo iptables -L             # List firewall rules
sudo ufw allow 22            # Allow SSH (Ubuntu)
sudo ufw allow 80            # Allow HTTP
sudo ufw enable              # Enable firewall
2.3 Key Networking Concepts
text

┌─────────────────────────────────────────────────────────┐
│                    OSI MODEL                            │
├─────────┬──────────────────┬───────────────────────────┤
│ Layer 7 │ Application      │ HTTP, HTTPS, DNS, SSH     │
│ Layer 6 │ Presentation     │ SSL/TLS, Encryption       │
│ Layer 5 │ Session          │ Authentication, Sessions  │
│ Layer 4 │ Transport        │ TCP, UDP (Ports)          │
│ Layer 3 │ Network          │ IP Addresses, Routing     │
│ Layer 2 │ Data Link        │ MAC Addresses, Switches   │
│ Layer 1 │ Physical         │ Cables, Wi-Fi             │
└─────────┴──────────────────┴───────────────────────────┘

COMMON PORTS:
┌────────┬──────────────────┐
│ Port   │ Service          │
├────────┼──────────────────┤
│ 22     │ SSH              │
│ 80     │ HTTP             │
│ 443    │ HTTPS            │
│ 3306   │ MySQL            │
│ 5432   │ PostgreSQL       │
│ 6379   │ Redis            │
│ 27017  │ MongoDB          │
│ 8080   │ Alt HTTP/Tomcat  │
│ 3000   │ Node.js/Grafana  │
│ 9090   │ Prometheus       │
└────────┴──────────────────┘

IP ADDRESSING:
┌──────────────────────────────────────────────────────────┐
│ IPv4: 192.168.1.100                                      │
│ Subnet Mask: 255.255.255.0 (/24 = 256 IPs)             │
│ CIDR: 10.0.0.0/16 = 65,536 IPs                         │
│ CIDR: 10.0.1.0/24 = 256 IPs                            │
│ CIDR: 10.0.1.0/28 = 16 IPs                             │
│                                                          │
│ Private IP Ranges:                                       │
│   10.0.0.0    – 10.255.255.255   (10.0.0.0/8)          │
│   172.16.0.0  – 172.31.255.255   (172.16.0.0/12)       │
│   192.168.0.0 – 192.168.255.255  (192.168.0.0/16)      │
└──────────────────────────────────────────────────────────┘
PART 3: VERSION CONTROL (GIT)
3.1 Git Fundamentals
text

What is Git?
─────────────
Git is a DISTRIBUTED version control system that tracks
changes in your code, enables collaboration, and maintains
a complete history of every modification.

┌──────────┐    git add    ┌──────────┐   git commit   ┌──────────┐   git push   ┌──────────┐
│ Working  │ ────────────▶ │ Staging  │ ─────────────▶ │  Local   │ ──────────▶ │  Remote  │
│Directory │               │  Area    │                │   Repo   │             │   Repo   │
└──────────┘               └──────────┘                └──────────┘             │ (GitHub) │
                                                            ▲                   └──────────┘
                                                            │                        │
                                                            └── git pull ◀───────────┘
3.2 Git Commands — Complete Reference
Bash

# ──────────────── SETUP ────────────────
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --list                    # View config

# ──────────────── REPOSITORY ────────────────
git init                             # Initialize new repo
git clone https://github.com/user/repo.git  # Clone existing repo

# ──────────────── DAILY WORKFLOW ────────────────
git status                           # Check current status
git add .                            # Stage all changes
git add file.txt                     # Stage specific file
git commit -m "feat: add login API"  # Commit with message
git push origin main                 # Push to remote
git pull origin main                 # Pull latest changes

# ──────────────── BRANCHING ────────────────
git branch                           # List branches
git branch feature/login             # Create branch
git checkout feature/login           # Switch branch
git checkout -b feature/signup       # Create + switch
git merge feature/login              # Merge branch into current
git branch -d feature/login          # Delete branch

# ──────────────── BRANCHING STRATEGY (GitFlow) ────────────────
#
# main ─────●─────────────────────●─────────────── (production)
#            \                   /
# develop ───●───●───●───●─────●────────────────── (integration)
#                 \       /
# feature ────────●───●──────────────────────────── (your work)

# ──────────────── HISTORY & DIFF ────────────────
git log --oneline --graph            # Visual commit history
git diff                             # Show unstaged changes
git diff --staged                    # Show staged changes
git blame file.txt                   # Who changed each line

# ──────────────── UNDO CHANGES ────────────────
git stash                            # Temporarily save changes
git stash pop                        # Restore stashed changes
git reset HEAD~1                     # Undo last commit (keep changes)
git reset --hard HEAD~1              # Undo last commit (discard changes)
git revert <commit-hash>             # Create new commit that undoes changes

# ──────────────── TAGS (for releases) ────────────────
git tag v1.0.0                       # Create lightweight tag
git tag -a v1.0.0 -m "Release 1.0"  # Create annotated tag
git push origin v1.0.0               # Push tag to remote
PART 4: CI/CD PIPELINES
4.1 What is CI/CD?
text

CI = Continuous Integration
──────────────────────────
Every developer pushes code frequently (multiple times/day).
Each push triggers an AUTOMATED build and test process.
Problems are caught EARLY.

CD = Continuous Delivery / Continuous Deployment
────────────────────────────────────────────────
Delivery:   Code is automatically prepared for release (manual approval to prod)
Deployment: Code is automatically deployed to production (no manual step)

┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐   ┌──────────┐
│  Code  │──▶│ Build  │──▶│  Test  │──▶│  Scan  │──▶│Approve │──▶│  Deploy  │
│  Push  │   │(compile│   │(unit,  │   │(SAST,  │   │(manual │   │(to prod) │
│        │   │ docker)│   │ integ) │   │ DAST)  │   │or auto)│   │          │
└────────┘   └────────┘   └────────┘   └────────┘   └────────┘   └──────────┘
   CI ◀─────────────────────────────────────▶  CD ◀────────────────────────▶
4.2 Jenkins Pipeline Example
groovy

// Jenkinsfile (Declarative Pipeline)
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'myapp'
        AWS_REGION = 'us-east-1'
        ECR_REPO = '123456789.dkr.ecr.us-east-1.amazonaws.com/myapp'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', 
                    url: 'https://github.com/myorg/myapp.git'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh 'sonar-scanner'
                }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REPO}
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}:${BUILD_NUMBER}
                    docker push ${ECR_REPO}:${BUILD_NUMBER}
                """
            }
        }
        
        stage('Deploy to ECS') {
            steps {
                sh """
                    aws ecs update-service \
                        --cluster production \
                        --service myapp-service \
                        --force-new-deployment \
                        --region ${AWS_REGION}
                """
            }
        }
    }
    
    post {
        success {
            slackSend channel: '#deployments',
                      message: "✅ Deploy SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            slackSend channel: '#deployments',
                      message: "❌ Deploy FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
    }
}
4.3 GitHub Actions Example
YAML

# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: myapp
  ECS_CLUSTER: production
  ECS_SERVICE: myapp-service

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Run linter
        run: npm run lint

  deploy:
    needs: build-and-test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force-new-deployment
PART 5: AWS CORE CONCEPTS & IAM
5.1 AWS Global Infrastructure
text

┌──────────────────────────────────────────────────────────────────┐
│                    AWS GLOBAL INFRASTRUCTURE                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  REGION (e.g., us-east-1)                                       │
│  ├── A geographic area with multiple data centers               │
│  ├── You CHOOSE which region to deploy in                       │
│  └── 30+ regions worldwide                                      │
│                                                                  │
│  AVAILABILITY ZONE (AZ) (e.g., us-east-1a, us-east-1b)        │
│  ├── One or more discrete data centers within a region          │
│  ├── Physically separated (different buildings, power, network) │
│  ├── Connected via low-latency links                            │
│  └── Each region has 2-6 AZs                                   │
│                                                                  │
│  EDGE LOCATIONS                                                  │
│  ├── 400+ locations globally                                    │
│  └── Used by CloudFront (CDN) for caching content               │
│                                                                  │
│  ┌──────────── Region: us-east-1 ─────────────┐                │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐    │                │
│  │  │  AZ-1a  │  │  AZ-1b  │  │  AZ-1c  │    │                │
│  │  │ ┌─────┐ │  │ ┌─────┐ │  │ ┌─────┐ │    │                │
│  │  │ │ DC  │ │  │ │ DC  │ │  │ │ DC  │ │    │                │
│  │  │ └─────┘ │  │ └─────┘ │  │ └─────┘ │    │                │
│  │  └─────────┘  └─────────┘  └─────────┘    │                │
│  └────────────────────────────────────────────┘                │
└──────────────────────────────────────────────────────────────────┘
5.2 AWS CLI Setup
Bash

# ──────────────── INSTALL AWS CLI ────────────────
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# ──────────────── CONFIGURE AWS CLI ────────────────
aws configure
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name [None]: us-east-1
# Default output format [None]: json

# ──────────────── NAMED PROFILES ────────────────
aws configure --profile production
aws configure --profile staging

# Use a specific profile:
aws s3 ls --profile production
export AWS_PROFILE=production    # Set default profile

# ──────────────── VERIFY IDENTITY ────────────────
aws sts get-caller-identity
# Returns: Account ID, User ARN, UserId
PART 6: EC2 — ELASTIC COMPUTE CLOUD
6.1 What is EC2?
text

EC2 = Virtual Servers in the Cloud

Think of it as renting a computer in AWS's data center.
You choose:
  ✦ CPU, Memory, Storage (Instance Type)
  ✦ Operating System (AMI)
  ✦ Network settings (VPC, Subnet)
  ✦ Security (Security Groups)
  ✦ How you pay (Purchase Option)
6.2 EC2 Purchase Options — COMPLETE COMPARISON
text

┌──────────────────────────────────────────────────────────────────────────┐
│                    EC2 PURCHASE OPTIONS                                  │
├──────────────┬───────────┬──────────┬────────────────────────────────────┤
│ Option       │ Discount  │ Commit   │ Best For                          │
├──────────────┼───────────┼──────────┼────────────────────────────────────┤
│ On-Demand    │ 0%        │ None     │ Short-term, unpredictable workload│
│ Reserved     │ Up to 72% │ 1-3 yrs  │ Steady-state, predictable usage  │
│ Spot         │ Up to 90% │ None     │ Fault-tolerant, flexible workload│
│ Savings Plan │ Up to 72% │ 1-3 yrs  │ Flexible across instance types   │
│ Dedicated    │ Varies    │ Varies   │ Compliance, licensing, regulation │
│ Capacity Res.│ 0%        │ None     │ Guaranteed capacity in an AZ     │
└──────────────┴───────────┴──────────┴────────────────────────────────────┘
6.2.1 On-Demand Instances
text

WHAT: Pay per second (Linux) or per hour (Windows), no commitment.
WHEN: Testing, development, unpredictable workloads.

Pros: ✅ No upfront cost, ✅ Start/stop anytime, ✅ Full control
Cons: ❌ Most expensive per-hour rate

Example Cost: t3.medium (2 vCPU, 4GB) ≈ $0.0416/hour ≈ $30/month
Bash

# Launch an On-Demand EC2 instance
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t3.medium \
    --key-name my-key-pair \
    --security-group-ids sg-0123456789abcdef0 \
    --subnet-id subnet-0123456789abcdef0 \
    --count 1 \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]'
6.2.2 Spot Instances
text

WHAT: Bid on unused EC2 capacity at up to 90% discount.
CATCH: AWS can RECLAIM your instance with 2-minute warning.
WHEN: Batch processing, data analysis, CI/CD build agents, ML training.

┌───────────────────────────────────────────────────────────┐
│                 SPOT INSTANCE LIFECYCLE                     │
│                                                             │
│  You set max price ──▶ AWS has spare capacity ──▶ RUNNING  │
│                                                      │      │
│                              Spot price > your bid   │      │
│                              or AWS needs capacity    │      │
│                                        │             │      │
│                                        ▼             ▼      │
│                                   INTERRUPTED    RUNNING    │
│                            (2-min warning)                  │
│                                                             │
│  Behaviors when interrupted:                                │
│    • Terminate (default)                                    │
│    • Stop (if EBS-backed)                                   │
│    • Hibernate                                              │
└───────────────────────────────────────────────────────────┘

Example: t3.medium On-Demand = $0.0416/hr
         t3.medium Spot      = $0.0125/hr (70% savings!)
Bash

# Request a Spot Instance
aws ec2 request-spot-instances \
    --spot-price "0.03" \
    --instance-count 1 \
    --type "one-time" \
    --launch-specification '{
        "ImageId": "ami-0c55b159cbfafe1f0",
        "InstanceType": "t3.medium",
        "KeyName": "my-key-pair",
        "SecurityGroupIds": ["sg-0123456789abcdef0"],
        "SubnetId": "subnet-0123456789abcdef0"
    }'

# Check Spot price history
aws ec2 describe-spot-price-history \
    --instance-types t3.medium \
    --product-descriptions "Linux/UNIX" \
    --start-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --max-items 5

# Cancel Spot request
aws ec2 cancel-spot-instance-requests \
    --spot-instance-request-ids sir-08b93456

# ──────── SPOT FLEET (multiple instance types for reliability) ────────
# spot-fleet-config.json:
{
    "SpotPrice": "0.04",
    "TargetCapacity": 10,
    "IamFleetRole": "arn:aws:iam::role/spot-fleet-role",
    "LaunchSpecifications": [
        {
            "ImageId": "ami-0c55b159cbfafe1f0",
            "InstanceType": "t3.medium",
            "SubnetId": "subnet-abc123"
        },
        {
            "ImageId": "ami-0c55b159cbfafe1f0",
            "InstanceType": "t3.large",
            "SubnetId": "subnet-abc123"
        },
        {
            "ImageId": "ami-0c55b159cbfafe1f0",
            "InstanceType": "m5.large",
            "SubnetId": "subnet-abc123"
        }
    ],
    "AllocationStrategy": "lowestPrice"
}
6.2.3 Reserved Instances
text

WHAT: Commit to 1 or 3 years for significant discounts.
WHEN: Production databases, always-on servers.

┌─────────────────────────────────────────────────────────────┐
│              RESERVED INSTANCE PAYMENT OPTIONS               │
├─────────────────────┬────────────┬──────────────────────────┤
│ Payment Option      │ Discount   │ Cash Flow                │
├─────────────────────┼────────────┼──────────────────────────┤
│ All Upfront         │ Maximum    │ Pay everything now       │
│ Partial Upfront     │ Medium     │ Some now + monthly       │
│ No Upfront          │ Minimum    │ Monthly payments only    │
└─────────────────────┴────────────┴──────────────────────────┘

Types:
  • Standard RI:  Up to 72% off, can't change instance family
  • Convertible RI: Up to 54% off, CAN change instance family
Bash

# Purchase a Reserved Instance
aws ec2 purchase-reserved-instances-offering \
    --reserved-instances-offering-id offering-id-here \
    --instance-count 1

# List your Reserved Instances
aws ec2 describe-reserved-instances \
    --filters "Name=state,Values=active"
6.2.4 Dedicated Hosts & Dedicated Instances
text

┌────────────────────┬──────────────────────────────────────────────┐
│ Dedicated Instance │ Runs on hardware dedicated to YOUR account   │
│                    │ You DON'T control which physical server      │
│                    │ Per-instance billing                         │
├────────────────────┼──────────────────────────────────────────────┤
│ Dedicated Host     │ An ENTIRE physical server for YOU            │
│                    │ You CAN see sockets, cores, host ID          │
│                    │ Needed for: BYOL (Bring Your Own License)   │
│                    │ Per-host billing                             │
└────────────────────┴──────────────────────────────────────────────┘

Use Cases: Compliance requirements, software licenses tied to hardware
6.3 EC2 Instance Types
text

┌──────────┬──────────────┬─────────────────────────────────────────┐
│ Family   │ Optimized For│ Use Cases                               │
├──────────┼──────────────┼─────────────────────────────────────────┤
│ t3/t3a   │ General      │ Web servers, small DBs, dev/test        │
│ m5/m6i   │ General      │ App servers, mid-size DBs               │
│ c5/c6i   │ Compute      │ Batch processing, ML, gaming            │
│ r5/r6i   │ Memory       │ In-memory DBs (Redis), big data         │
│ i3/d2    │ Storage      │ Data warehousing, Hadoop                │
│ p4/g5    │ GPU          │ ML training, video rendering            │
└──────────┴──────────────┴─────────────────────────────────────────┘

Instance naming: m5.xlarge
                 │ │  │
                 │ │  └── Size (nano < micro < small < medium < large < xlarge < 2xlarge...)
                 │ └───── Generation (5th gen)
                 └─────── Family (m = general purpose)
6.4 EC2 Practical Commands
Bash

# ──────────────── LAUNCH INSTANCE ────────────────
aws ec2 run-instances \
    --image-id ami-0abcdef1234567890 \
    --instance-type t3.micro \
    --key-name MyKeyPair \
    --security-group-ids sg-903004f8 \
    --subnet-id subnet-6e7f829e \
    --user-data file://startup-script.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyServer},{Key=Environment,Value=Production}]'

# ──────────────── startup-script.sh (User Data) ────────────────
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html

# ──────────────── KEY PAIR ────────────────
aws ec2 create-key-pair \
    --key-name MyKeyPair \
    --query 'KeyMaterial' \
    --output text > MyKeyPair.pem
chmod 400 MyKeyPair.pem

# ──────────────── CONNECT TO INSTANCE ────────────────
ssh -i MyKeyPair.pem ec2-user@<public-ip>           # Amazon Linux
ssh -i MyKeyPair.pem ubuntu@<public-ip>              # Ubuntu

# ──────────────── INSTANCE MANAGEMENT ────────────────
aws ec2 describe-instances                            # List all instances
aws ec2 describe-instances \
    --filters "Name=tag:Environment,Values=Production" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
    --output table

aws ec2 start-instances --instance-ids i-1234567890abcdef0
aws ec2 stop-instances --instance-ids i-1234567890abcdef0
aws ec2 reboot-instances --instance-ids i-1234567890abcdef0
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# ──────────────── ELASTIC IP ────────────────
aws ec2 allocate-address --domain vpc
aws ec2 associate-address \
    --instance-id i-1234567890abcdef0 \
    --allocation-id eipalloc-64d5890a
aws ec2 release-address --allocation-id eipalloc-64d5890a

# ──────────────── AMI (Amazon Machine Image) ────────────────
aws ec2 create-image \
    --instance-id i-1234567890abcdef0 \
    --name "MyServer-Backup-$(date +%Y%m%d)" \
    --no-reboot

aws ec2 describe-images --owners self
aws ec2 deregister-image --image-id ami-0123456789abcdef0

# ──────────────── EBS VOLUMES ────────────────
aws ec2 create-volume \
    --size 100 \
    --volume-type gp3 \
    --availability-zone us-east-1a

aws ec2 attach-volume \
    --volume-id vol-1234567890abcdef0 \
    --instance-id i-1234567890abcdef0 \
    --device /dev/xvdf

# On the instance: format and mount the volume
sudo mkfs -t xfs /dev/xvdf
sudo mkdir /data
sudo mount /dev/xvdf /data
echo '/dev/xvdf /data xfs defaults 0 0' | sudo tee -a /etc/fstab

# EBS Volume Types:
# ┌──────────┬───────────────────────────────────────────────────────┐
# │ gp3      │ General SSD, 3000 IOPS baseline, cost effective     │
# │ gp2      │ General SSD, bursting, legacy                       │
# │ io2      │ High-performance SSD, up to 64,000 IOPS            │
# │ st1      │ HDD, throughput optimized, big data                │
# │ sc1      │ Cold HDD, infrequently accessed data               │
# └──────────┴───────────────────────────────────────────────────────┘

# ──────────────── SNAPSHOTS ────────────────
aws ec2 create-snapshot \
    --volume-id vol-1234567890abcdef0 \
    --description "Daily backup"

aws ec2 describe-snapshots --owner-ids self
aws ec2 copy-snapshot \
    --source-region us-east-1 \
    --source-snapshot-id snap-066877671789bd71b \
    --destination-region us-west-2       # Cross-region backup!
PART 7: VPC — VIRTUAL PRIVATE CLOUD (Networking Deep Dive)
7.1 What is a VPC?
text

VPC = Your own PRIVATE, ISOLATED network in AWS.

Think of it as building your own data center network in the cloud:
  • You define the IP range
  • You create subnets
  • You control routing
  • You set up security

┌────────────────────── AWS CLOUD ──────────────────────────────┐
│                                                                │
│  ┌──────────────── VPC: 10.0.0.0/16 ────────────────────┐    │
│  │                (65,536 IP addresses)                   │    │
│  │                                                        │    │
│  │  ┌─── AZ: us-east-1a ────┐  ┌─── AZ: us-east-1b ──┐ │    │
│  │  │                        │  │                       │ │    │
│  │  │ ┌──────────────────┐  │  │ ┌──────────────────┐ │ │    │
│  │  │ │  Public Subnet   │  │  │ │  Public Subnet   │ │ │    │
│  │  │ │  10.0.1.0/24     │  │  │ │  10.0.2.0/24     │ │ │    │
│  │  │ │  ┌────────────┐  │  │  │ │  ┌────────────┐  │ │ │    │
│  │  │ │  │ Web Server │  │  │  │ │  │ Web Server │  │ │ │    │
│  │  │ │  └────────────┘  │  │  │ │  └────────────┘  │ │ │    │
│  │  │ └──────────────────┘  │  │ └──────────────────┘ │ │    │
│  │  │                        │  │                       │ │    │
│  │  │ ┌──────────────────┐  │  │ ┌──────────────────┐ │ │    │
│  │  │ │  Private Subnet  │  │  │ │  Private Subnet  │ │ │    │
│  │  │ │  10.0.3.0/24     │  │  │ │  10.0.4.0/24     │ │ │    │
│  │  │ │  ┌────────────┐  │  │  │ │  ┌────────────┐  │ │ │    │
│  │  │ │  │  Database  │  │  │  │ │  │  Database  │  │ │ │    │
│  │  │ │  └────────────┘  │  │  │ │  └────────────┘  │ │ │    │
│  │  │ └──────────────────┘  │  │ └──────────────────┘ │ │    │
│  │  │                        │  │                       │ │    │
│  │  └────────────────────────┘  └───────────────────────┘ │    │
│  │                                                        │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
7.2 VPC Components Explained
text

┌────────────────────────────────────────────────────────────────────┐
│                      VPC COMPONENT MAP                             │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  INTERNET                                                          │
│     │                                                              │
│     ▼                                                              │
│  ┌──────────────────┐                                              │
│  │ Internet Gateway │ ◀── Allows public internet access            │
│  │     (IGW)        │                                              │
│  └────────┬─────────┘                                              │
│           │                                                        │
│           ▼                                                        │
│  ┌──────────────────┐                                              │
│  │   Route Table    │ ◀── Rules that determine where traffic goes  │
│  │  (Public)        │     0.0.0.0/0 → IGW                         │
│  └────────┬─────────┘                                              │
│           │                                                        │
│  ┌────────▼─────────┐                                              │
│  │  Public Subnet   │ ◀── Has route to IGW, instances get public IP│
│  │  10.0.1.0/24     │                                              │
│  │  ┌─────────────┐ │                                              │
│  │  │  EC2 + EIP  │ │ ◀── Directly accessible from internet       │
│  │  └─────────────┘ │                                              │
│  │  ┌─────────────┐ │                                              │
│  │  │ NAT Gateway │ │ ◀── Allows private subnet to reach internet │
│  │  └──────┬──────┘ │                                              │
│  └─────────┼────────┘                                              │
│            │                                                       │
│  ┌─────────▼────────┐                                              │
│  │   Route Table    │                                              │
│  │  (Private)       │     0.0.0.0/0 → NAT Gateway                 │
│  └────────┬─────────┘                                              │
│           │                                                        │
│  ┌────────▼─────────┐                                              │
│  │  Private Subnet  │ ◀── NO direct internet access                │
│  │  10.0.3.0/24     │     Can reach internet via NAT Gateway       │
│  │  ┌─────────────┐ │                                              │
│  │  │  Database   │ │ ◀── Protected from direct internet access    │
│  │  └─────────────┘ │                                              │
│  └──────────────────┘                                              │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
7.3 Build a Complete VPC — Step by Step
Bash

# ══════════════════════════════════════════════════════════
# STEP 1: CREATE THE VPC
# ══════════════════════════════════════════════════════════
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Production-VPC}]'
# Save the VpcId: vpc-0123456789abcdef0

# Enable DNS hostnames (required for public DNS names)
aws ec2 modify-vpc-attribute \
    --vpc-id vpc-0123456789abcdef0 \
    --enable-dns-hostnames '{"Value": true}'

# ══════════════════════════════════════════════════════════
# STEP 2: CREATE SUBNETS
# ══════════════════════════════════════════════════════════

# Public Subnet in AZ-1a
aws ec2 create-subnet \
    --vpc-id vpc-0123456789abcdef0 \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1a}]'
# Save: subnet-pub-1a

# Public Subnet in AZ-1b
aws ec2 create-subnet \
    --vpc-id vpc-0123456789abcdef0 \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet-1b}]'
# Save: subnet-pub-1b

# Private Subnet in AZ-1a
aws ec2 create-subnet \
    --vpc-id vpc-0123456789abcdef0 \
    --cidr-block 10.0.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet-1a}]'
# Save: subnet-priv-1a

# Private Subnet in AZ-1b
aws ec2 create-subnet \
    --vpc-id vpc-0123456789abcdef0 \
    --cidr-block 10.0.4.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet-1b}]'
# Save: subnet-priv-1b

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute \
    --subnet-id subnet-pub-1a \
    --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
    --subnet-id subnet-pub-1b \
    --map-public-ip-on-launch

# ══════════════════════════════════════════════════════════
# STEP 3: CREATE INTERNET GATEWAY
# ══════════════════════════════════════════════════════════
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Production-IGW}]'
# Save: igw-0123456789abcdef0

# Attach IGW to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id igw-0123456789abcdef0 \
    --vpc-id vpc-0123456789abcdef0

# ══════════════════════════════════════════════════════════
# STEP 4: CREATE ROUTE TABLES
# ══════════════════════════════════════════════════════════

# Public Route Table
aws ec2 create-route-table \
    --vpc-id vpc-0123456789abcdef0 \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public-RT}]'
# Save: rtb-pub

# Add route to internet via IGW
aws ec2 create-route \
    --route-table-id rtb-pub \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-0123456789abcdef0

# Associate public subnets with public route table
aws ec2 associate-route-table \
    --route-table-id rtb-pub \
    --subnet-id subnet-pub-1a

aws ec2 associate-route-table \
    --route-table-id rtb-pub \
    --subnet-id subnet-pub-1b

# Private Route Table (will add NAT route later)
aws ec2 create-route-table \
    --vpc-id vpc-0123456789abcdef0 \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private-RT}]'
# Save: rtb-priv

# Associate private subnets
aws ec2 associate-route-table \
    --route-table-id rtb-priv \
    --subnet-id subnet-priv-1a

aws ec2 associate-route-table \
    --route-table-id rtb-priv \
    --subnet-id subnet-priv-1b
PART 8: NAT GATEWAY & NAT INSTANCE
8.1 Why Do We Need NAT?
text

PROBLEM:
─────────
Instances in PRIVATE subnets can't access the internet.
But they NEED to download updates, pull Docker images, etc.

SOLUTION: NAT (Network Address Translation)
──────────────────────────────────────────────
NAT allows private instances to INITIATE outbound connections
to the internet, while PREVENTING inbound connections FROM
the internet.

┌────────────────────────────────────────────────────────────┐
│                                                            │
│  Private Instance ──▶ NAT Gateway ──▶ IGW ──▶ Internet   │
│  (10.0.3.15)          (translates      (exits              │
│                        private IP       to web)            │
│                        to public IP)                       │
│                                                            │
│  Internet ──✖──▶ Private Instance                          │
│  (CANNOT initiate inbound connections)                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
8.2 NAT Gateway vs NAT Instance
text

┌─────────────────────┬──────────────────┬──────────────────────┐
│ Feature             │ NAT Gateway      │ NAT Instance         │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Managed by          │ AWS (fully       │ YOU (EC2 instance)   │
│                     │ managed)         │                      │
│ Availability        │ Highly available │ You must set up HA   │
│                     │ within AZ        │                      │
│ Bandwidth           │ Up to 100 Gbps   │ Depends on instance  │
│                     │                  │ type                 │
│ Cost                │ ~$0.045/hr +     │ EC2 instance cost    │
│                     │ data processing  │ (can use t3.micro)   │
│ Maintenance         │ None             │ Patching, monitoring │
│ Security Groups     │ Cannot associate │ CAN associate        │
│ Port Forwarding     │ Not supported    │ Supported            │
│ Bastion Host        │ Not possible     │ Can be used as one   │
│ Best for            │ Production       │ Cost savings/testing │
└─────────────────────┴──────────────────┴──────────────────────┘

RECOMMENDATION: Use NAT Gateway for production.
                Use NAT Instance only if you need to save costs in dev/test.
8.3 Create NAT Gateway
Bash

# Step 1: Allocate an Elastic IP for the NAT Gateway
aws ec2 allocate-address --domain vpc
# Save: eipalloc-0123456789abcdef0

# Step 2: Create NAT Gateway in a PUBLIC subnet
aws ec2 create-nat-gateway \
    --subnet-id subnet-pub-1a \
    --allocation-id eipalloc-0123456789abcdef0 \
    --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=Production-NAT}]'
# Save: nat-0123456789abcdef0

# Step 3: Add route in PRIVATE route table pointing to NAT Gateway
aws ec2 create-route \
    --route-table-id rtb-priv \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id nat-0123456789abcdef0

# Now private instances can reach the internet!
# Verify from a private instance:
# ssh into private instance (via bastion) → ping google.com ✅
8.4 Create NAT Instance (Manual Method)
Bash

# Step 1: Launch an EC2 instance in a PUBLIC subnet (Amazon Linux)
aws ec2 run-instances \
    --image-id ami-0123456789abcdef0 \
    --instance-type t3.micro \
    --key-name my-key \
    --subnet-id subnet-pub-1a \
    --security-group-ids sg-nat \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=NAT-Instance}]'

# Step 2: DISABLE source/destination check (critical!)
aws ec2 modify-instance-attribute \
    --instance-id i-nat-instance \
    --no-source-dest-check

# Step 3: Configure iptables on the NAT instance
# SSH into the NAT instance:
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo yum install iptables-services -y
sudo service iptables save

# Step 4: Update private route table to point to NAT instance
aws ec2 create-route \
    --route-table-id rtb-priv \
    --destination-cidr-block 0.0.0.0/0 \
    --instance-id i-nat-instance
PART 9: SECURITY GROUPS & NACLs
9.1 Security Groups (Instance-Level Firewall)
text

┌──────────────────────────────────────────────────────────────────┐
│                    SECURITY GROUPS                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  • Acts as a VIRTUAL FIREWALL for your EC2 instances            │
│  • Operates at the INSTANCE level                                │
│  • STATEFUL: If you allow inbound, response is auto-allowed     │
│  • Default: ALL inbound DENIED, ALL outbound ALLOWED            │
│  • You can only specify ALLOW rules (no DENY rules)             │
│  • Can reference other security groups!                          │
│                                                                  │
│  ┌─────────────────────────────────────────────┐                │
│  │              EC2 Instance                    │                │
│  │  ┌───────────────────────────────────────┐  │                │
│  │  │         Security Group                 │  │                │
│  │  │                                        │  │                │
│  │  │  INBOUND RULES:                       │  │                │
│  │  │  ┌──────┬──────────┬────────────────┐ │  │                │
│  │  │  │ Port │ Protocol │ Source         │ │  │                │
│  │  │  ├──────┼──────────┼────────────────┤ │  │                │
│  │  │  │ 22   │ TCP      │ My IP only    │ │  │                │
│  │  │  │ 80   │ TCP      │ 0.0.0.0/0     │ │  │                │
│  │  │  │ 443  │ TCP      │ 0.0.0.0/0     │ │  │                │
│  │  │  │ 3306 │ TCP      │ sg-app-tier   │ │  │ ◀── SG ref!   │
│  │  │  └──────┴──────────┴────────────────┘ │  │                │
│  │  │                                        │  │                │
│  │  │  OUTBOUND RULES:                      │  │                │
│  │  │  ┌──────┬──────────┬────────────────┐ │  │                │
│  │  │  │ All  │ All      │ 0.0.0.0/0     │ │  │                │
│  │  │  └──────┴──────────┴────────────────┘ │  │                │
│  │  └───────────────────────────────────────┘  │                │
│  └─────────────────────────────────────────────┘                │
└──────────────────────────────────────────────────────────────────┘
Bash

# ──────────────── CREATE SECURITY GROUPS ────────────────

# Web Server Security Group
aws ec2 create-security-group \
    --group-name web-sg \
    --description "Security group for web servers" \
    --vpc-id vpc-0123456789abcdef0

# Add inbound rules
aws ec2 authorize-security-group-ingress \
    --group-id sg-web \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0            # Allow HTTP from anywhere

aws ec2 authorize-security-group-ingress \
    --group-id sg-web \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0            # Allow HTTPS from anywhere

aws ec2 authorize-security-group-ingress \
    --group-id sg-web \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.0/32       # Allow SSH from YOUR IP only

# App Server Security Group (only accepts traffic from web-sg)
aws ec2 create-security-group \
    --group-name app-sg \
    --description "Security group for app servers" \
    --vpc-id vpc-0123456789abcdef0

aws ec2 authorize-security-group-ingress \
    --group-id sg-app \
    --protocol tcp \
    --port 8080 \
    --source-group sg-web       # ◀── Only from web tier!

# Database Security Group (only accepts traffic from app-sg)
aws ec2 create-security-group \
    --group-name db-sg \
    --description "Security group for databases" \
    --vpc-id vpc-0123456789abcdef0

aws ec2 authorize-security-group-ingress \
    --group-id sg-db \
    --protocol tcp \
    --port 3306 \
    --source-group sg-app       # ◀── Only from app tier!

# ──────────────── REMOVE / MODIFY RULES ────────────────
aws ec2 revoke-security-group-ingress \
    --group-id sg-web \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0            # Remove overly permissive SSH rule

# List security group rules
aws ec2 describe-security-groups \
    --group-ids sg-web \
    --query 'SecurityGroups[*].IpPermissions'
9.2 Network ACLs (Subnet-Level Firewall)
text

┌──────────────────────────────────────────────────────────────────┐
│              SECURITY GROUP vs NACL COMPARISON                    │
├───────────────────┬──────────────────┬───────────────────────────┤
│ Feature           │ Security Group   │ NACL                      │
├───────────────────┼──────────────────┼───────────────────────────┤
│ Level             │ Instance         │ Subnet                    │
│ State             │ STATEFUL         │ STATELESS                 │
│ Rules             │ ALLOW only       │ ALLOW and DENY            │
│ Rule processing   │ All rules        │ Rules processed IN ORDER  │
│                   │ evaluated        │ (lowest number first)     │
│ Default           │ Deny all inbound │ Allow ALL in and out      │
│ Applied           │ Only if assigned │ Auto-applied to all       │
│                   │ to instance      │ instances in subnet       │
└───────────────────┴──────────────────┴───────────────────────────┘

STATEFUL vs STATELESS:
───────────────────────
STATEFUL (Security Group):
  Inbound ALLOW port 80 → Response on port 80 automatically allowed

STATELESS (NACL):
  Inbound ALLOW port 80 → You MUST also add outbound rule for response
  (ephemeral ports 1024-65535)
Bash

# Create a custom NACL
aws ec2 create-network-acl \
    --vpc-id vpc-0123456789abcdef0 \
    --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=Public-NACL}]'

# Add INBOUND rules (rule numbers are processed low→high)
aws ec2 create-network-acl-entry \
    --network-acl-id acl-0123456789abcdef0 \
    --rule-number 100 \
    --protocol tcp \
    --port-range From=80,To=80 \
    --cidr-block 0.0.0.0/0 \
    --rule-action allow \
    --ingress

aws ec2 create-network-acl-entry \
    --network-acl-id acl-0123456789abcdef0 \
    --rule-number 110 \
    --protocol tcp \
    --port-range From=443,To=443 \
    --cidr-block 0.0.0.0/0 \
    --rule-action allow \
    --ingress

aws ec2 create-network-acl-entry \
    --network-acl-id acl-0123456789abcdef0 \
    --rule-number 120 \
    --protocol tcp \
    --port-range From=22,To=22 \
    --cidr-block 203.0.113.0/32 \
    --rule-action allow \
    --ingress

# Add OUTBOUND rules (MUST allow ephemeral ports for responses!)
aws ec2 create-network-acl-entry \
    --network-acl-id acl-0123456789abcdef0 \
    --rule-number 100 \
    --protocol tcp \
    --port-range From=1024,To=65535 \
    --cidr-block 0.0.0.0/0 \
    --rule-action allow \
    --egress

# Block a specific malicious IP (add BEFORE allow rules)
aws ec2 create-network-acl-entry \
    --network-acl-id acl-0123456789abcdef0 \
    --rule-number 50 \
    --protocol -1 \
    --cidr-block 198.51.100.0/24 \
    --rule-action deny \
    --ingress

# Associate NACL with subnet
aws ec2 replace-network-acl-association \
    --association-id aclassoc-old \
    --network-acl-id acl-0123456789abcdef0
PART 10: ELASTIC LOAD BALANCING
10.1 What is Load Balancing?
text

WITHOUT Load Balancer:
──────────────────────
All traffic hits ONE server → Server overloaded → App crashes

                    ┌──────────┐
Users ──────────────▶│ Server 1 │ 😵 OVERLOADED!
                    └──────────┘

WITH Load Balancer:
───────────────────
Traffic distributed across multiple servers → High availability

                    ┌──────────────────┐
                    │   Load Balancer   │
                    └──────┬───────────┘
                    ┌──────┴───────┐
              ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
              │ Server 1  │ │ Server 2  │ │ Server 3  │
              │   33%     │ │   33%     │ │   33%     │
              └───────────┘ └───────────┘ └───────────┘
10.2 Types of Load Balancers
text

┌────────────────────────────────────────────────────────────────────────┐
│                    AWS LOAD BALANCER TYPES                              │
├──────────────┬─────────┬───────────────────────────────────────────────┤
│ Type         │ Layer   │ Use Case                                      │
├──────────────┼─────────┼───────────────────────────────────────────────┤
│ ALB          │ Layer 7 │ HTTP/HTTPS traffic, path-based routing,      │
│ (Application)│(HTTP)   │ microservices, containers, WebSockets        │
├──────────────┼─────────┼───────────────────────────────────────────────┤
│ NLB          │ Layer 4 │ TCP/UDP traffic, extreme performance,        │
│ (Network)    │(TCP/UDP)│ millions of requests/sec, static IP          │
├──────────────┼─────────┼───────────────────────────────────────────────┤
│ CLB          │ L4 + L7 │ LEGACY - Don't use for new applications     │
│ (Classic)    │         │ Basic load balancing                         │
├──────────────┼─────────┼───────────────────────────────────────────────┤
│ GWLB         │ Layer 3 │ Third-party virtual appliances (firewalls,  │
│ (Gateway)    │(IP)     │ IDS/IPS)                                    │
└──────────────┴─────────┴───────────────────────────────────────────────┘
10.3 Application Load Balancer (ALB) — Deep Dive
text

ALB FEATURES:
─────────────
✦ Path-based routing:   /api/* → API servers, /images/* → Image servers
✦ Host-based routing:   api.example.com → API, www.example.com → Web
✦ HTTP/2 and WebSocket support
✦ SSL/TLS termination
✦ Sticky sessions (cookie-based)
✦ Health checks
✦ Integration with WAF

┌─────────────────────────────────────────────────────────────────┐
│                     ALB ROUTING EXAMPLE                          │
│                                                                  │
│  User Request                                                    │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────┐                                                    │
│  │   ALB    │                                                    │
│  └──┬───┬───┘                                                    │
│     │   │                                                        │
│     │   │  Rule: IF path = /api/*                                │
│     │   └──────────────────▶ Target Group: API Servers           │
│     │                        ├── EC2: 10.0.1.10:8080             │
│     │                        └── EC2: 10.0.1.11:8080             │
│     │                                                            │
│     │      Rule: IF path = /static/*                             │
│     └──────────────────────▶ Target Group: Static Servers        │
│                              ├── EC2: 10.0.2.10:80               │
│                              └── EC2: 10.0.2.11:80               │
│                                                                  │
│     DEFAULT RULE ──────────▶ Target Group: Default               │
│                              └── EC2: 10.0.3.10:80               │
└─────────────────────────────────────────────────────────────────┘
Bash

# ══════════════════════════════════════════════════════════
# CREATE APPLICATION LOAD BALANCER — Step by Step
# ══════════════════════════════════════════════════════════

# Step 1: Create ALB
aws elbv2 create-load-balancer \
    --name production-alb \
    --subnets subnet-pub-1a subnet-pub-1b \
    --security-groups sg-alb \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4
# Save: ALB ARN

# Step 2: Create Target Group
aws elbv2 create-target-group \
    --name web-targets \
    --protocol HTTP \
    --port 80 \
    --vpc-id vpc-0123456789abcdef0 \
    --target-type instance \
    --health-check-protocol HTTP \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --healthy-threshold-count 3 \
    --unhealthy-threshold-count 3
# Save: Target Group ARN

# Step 3: Register targets (EC2 instances)
aws elbv2 register-targets \
    --target-group-arn arn:aws:elasticloadbalancing:...:targetgroup/web-targets/... \
    --targets Id=i-1234567890abcdef0 Id=i-0987654321fedcba0

# Step 4: Create Listener (HTTP on port 80)
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:...:loadbalancer/app/production-alb/... \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:...:targetgroup/web-targets/...

# Step 5: Create HTTPS Listener with SSL certificate
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:...:loadbalancer/app/production-alb/... \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-1:123456789:certificate/abc-123 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:...:targetgroup/web-targets/...

# Step 6: HTTP → HTTPS Redirect Rule
aws elbv2 modify-listener \
    --listener-arn arn:aws:elasticloadbalancing:...:listener/app/production-alb/.../... \
    --default-actions '[{
        "Type": "redirect",
        "RedirectConfig": {
            "Protocol": "HTTPS",
            "Port": "443",
            "StatusCode": "HTTP_301"
        }
    }]'

# Step 7: Path-Based Routing Rule
aws elbv2 create-rule \
    --listener-arn arn:aws:...:listener/... \
    --priority 10 \
    --conditions '[{
        "Field": "path-pattern",
        "Values": ["/api/*"]
    }]' \
    --actions '[{
        "Type": "forward",
        "TargetGroupArn": "arn:aws:...:targetgroup/api-targets/..."
    }]'

# Step 8: Host-Based Routing Rule
aws elbv2 create-rule \
    --listener-arn arn:aws:...:listener/... \
    --priority 20 \
    --conditions '[{
        "Field": "host-header",
        "Values": ["api.example.com"]
    }]' \
    --actions '[{
        "Type": "forward",
        "TargetGroupArn": "arn:aws:...:targetgroup/api-targets/..."
    }]'

# ──────────────── HEALTH CHECK MONITORING ────────────────
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:...:targetgroup/web-targets/...
10.4 Network Load Balancer (NLB)
text

NLB KEY FEATURES:
─────────────────
✦ Operates at Layer 4 (TCP/UDP)
✦ Handles MILLIONS of requests per second
✦ Ultra-low latency (~100 microseconds vs ~400ms for ALB)
✦ Gets a STATIC IP per AZ (or Elastic IP)
✦ Preserves source IP address
✦ Best for: gaming, IoT, financial trading, TCP services

Use Cases:
  • TCP load balancing (non-HTTP)
  • When you need static IP
  • Extreme performance requirements
  • gRPC, MQTT, or custom TCP protocols
Bash

# Create NLB
aws elbv2 create-load-balancer \
    --name production-nlb \
    --subnets subnet-pub-1a subnet-pub-1b \
    --scheme internet-facing \
    --type network

# Create TCP Target Group
aws elbv2 create-target-group \
    --name tcp-targets \
    --protocol TCP \
    --port 443 \
    --vpc-id vpc-0123456789abcdef0 \
    --target-type instance \
    --health-check-protocol TCP

# Create TCP Listener
aws elbv2 create-listener \
    --load-balancer-arn arn:aws:...:loadbalancer/net/production-nlb/... \
    --protocol TCP \
    --port 443 \
    --default-actions Type=forward,TargetGroupArn=arn:aws:...:targetgroup/tcp-targets/...
PART 11: AUTO SCALING
11.1 What is Auto Scaling?
text

Auto Scaling AUTOMATICALLY adjusts the number of EC2 instances
based on demand.

Low Traffic (night):          High Traffic (peak):
┌────┐                        ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐
│ EC2│                        │ EC2│ │ EC2│ │ EC2│ │ EC2│ │ EC2│
└────┘                        └────┘ └────┘ └────┘ └────┘ └────┘
1 instance                    5 instances
Min: 1                        Max: 10

        SCALING TIMELINE:
        ─────────────────
   Instances
   10 ┤                            ╭─────╮
    8 ┤                         ╭──╯     ╰──╮
    6 ┤                      ╭──╯            ╰──╮
    4 ┤                   ╭──╯                   ╰──╮
    2 ┤    ╭──────────────╯                          ╰──────────
    0 ┼────┴──────────────────────────────────────────────────────
      6AM   9AM   12PM  3PM   6PM   9PM   12AM  3AM   6AM
11.2 Auto Scaling Components
text

┌───────────────────────────────────────────────────────────────┐
│                AUTO SCALING COMPONENTS                         │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  1. LAUNCH TEMPLATE (What to launch)                         │
│     • AMI ID, Instance type, Key pair                        │
│     • Security groups, User data                             │
│     • EBS volumes                                            │
│                                                               │
│  2. AUTO SCALING GROUP (Where & how many)                    │
│     • VPC & Subnets (which AZs)                              │
│     • Min, Max, Desired capacity                             │
│     • Health check type (EC2 or ELB)                         │
│     • Target Group (load balancer integration)               │
│                                                               │
│  3. SCALING POLICIES (When to scale)                         │
│     • Target Tracking: Keep CPU at 50%                       │
│     • Step Scaling: Add 2 if CPU > 70%, add 4 if CPU > 90%  │
│     • Scheduled: Scale up at 9AM, scale down at 6PM         │
│     • Predictive: ML-based forecasting                       │
│                                                               │
└───────────────────────────────────────────────────────────────┘
Bash

# ══════════════════════════════════════════════════════════
# STEP 1: CREATE LAUNCH TEMPLATE
# ══════════════════════════════════════════════════════════
aws ec2 create-launch-template \
    --launch-template-name web-server-template \
    --version-description "v1" \
    --launch-template-data '{
        "ImageId": "ami-0c55b159cbfafe1f0",
        "InstanceType": "t3.medium",
        "KeyName": "my-key-pair",
        "SecurityGroupIds": ["sg-web"],
        "UserData": "'$(base64 -w 0 startup.sh)'",
        "BlockDeviceMappings": [
            {
                "DeviceName": "/dev/xvda",
                "Ebs": {
                    "VolumeSize": 20,
                    "VolumeType": "gp3",
                    "DeleteOnTermination": true
                }
            }
        ],
        "TagSpecifications": [
            {
                "ResourceType": "instance",
                "Tags": [
                    {"Key": "Name", "Value": "WebServer-ASG"},
                    {"Key": "Environment", "Value": "Production"}
                ]
            }
        ]
    }'

# ══════════════════════════════════════════════════════════
# STEP 2: CREATE AUTO SCALING GROUP
# ══════════════════════════════════════════════════════════
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name production-asg \
    --launch-template LaunchTemplateName=web-server-template,Version='$Latest' \
    --min-size 2 \
    --max-size 10 \
    --desired-capacity 2 \
    --vpc-zone-identifier "subnet-pub-1a,subnet-pub-1b" \
    --target-group-arns "arn:aws:...:targetgroup/web-targets/..." \
    --health-check-type ELB \
    --health-check-grace-period 300 \
    --tags '[
        {"Key":"Name","Value":"ASG-Instance","PropagateAtLaunch":true},
        {"Key":"Environment","Value":"Production","PropagateAtLaunch":true}
    ]'

# ══════════════════════════════════════════════════════════
# STEP 3: CREATE SCALING POLICIES
# ══════════════════════════════════════════════════════════

# Target Tracking Policy: Maintain 50% average CPU
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name production-asg \
    --policy-name cpu-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ASGAverageCPUUtilization"
        },
        "TargetValue": 50.0,
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
    }'

# Target Tracking: Maintain 1000 requests per target
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name production-asg \
    --policy-name request-count-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ALBRequestCountPerTarget",
            "ResourceLabel": "app/production-alb/.../targetgroup/web-targets/..."
        },
        "TargetValue": 1000.0
    }'

# Step Scaling Policy: Scale up based on CPU thresholds
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name production-asg \
    --policy-name scale-up-step \
    --policy-type StepScaling \
    --adjustment-type ChangeInCapacity \
    --step-adjustments '[
        {"MetricIntervalLowerBound": 0, "MetricIntervalUpperBound": 20, "ScalingAdjustment": 1},
        {"MetricIntervalLowerBound": 20, "MetricIntervalUpperBound": 40, "ScalingAdjustment": 2},
        {"MetricIntervalLowerBound": 40, "ScalingAdjustment": 4}
    ]'

# Scheduled Scaling: Scale up at 9 AM, down at 6 PM
aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name production-asg \
    --scheduled-action-name scale-up-morning \
    --recurrence "0 9 * * MON-FRI" \
    --min-size 4 \
    --max-size 10 \
    --desired-capacity 4

aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name production-asg \
    --scheduled-action-name scale-down-evening \
    --recurrence "0 18 * * MON-FRI" \
    --min-size 2 \
    --max-size 10 \
    --desired-capacity 2

# ══════════════════════════════════════════════════════════
# MONITORING AUTO SCALING
# ══════════════════════════════════════════════════════════
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names production-asg \
    --query 'AutoScalingGroups[*].[MinSize,MaxSize,DesiredCapacity,Instances[*].InstanceId]'

aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name production-asg \
    --max-items 10

# Manually set desired capacity (for testing)
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name production-asg \
    --desired-capacity 4
PART 12: S3 — SIMPLE STORAGE SERVICE
12.1 What is S3?
text

S3 = Object Storage with virtually unlimited capacity.

KEY CONCEPTS:
─────────────
• Bucket:  A container for objects (like a top-level folder)
• Object:  A file + metadata (up to 5TB per object)
• Key:     The full path of the object (folder/subfolder/file.txt)

S3 is NOT a file system — it's an object store.
There are no real "folders" — it's a flat namespace with "/" as delimiter.

DURABILITY:   99.999999999% (11 nines) — virtually indestructible
AVAILABILITY: 99.99% — 53 minutes downtime per year

STORAGE CLASSES:
┌──────────────────┬──────────┬──────────────────────────────────────┐
│ Class            │ Cost     │ Use Case                             │
├──────────────────┼──────────┼──────────────────────────────────────┤
│ S3 Standard      │ $$$$     │ Frequently accessed data             │
│ S3 Intelligent   │ $$$      │ Unknown access patterns              │
│ S3 Standard-IA   │ $$       │ Infrequent access, instant retrieval │
│ S3 One Zone-IA   │ $        │ Infrequent, non-critical data       │
│ S3 Glacier IR    │ $        │ Archive, instant retrieval           │
│ S3 Glacier Flex  │ ¢        │ Archive, 1-12 hour retrieval         │
│ S3 Glacier Deep  │ ¢        │ Long-term archive, 12-48hr retrieval │
└──────────────────┴──────────┴──────────────────────────────────────┘
Bash

# ──────────────── BUCKET OPERATIONS ────────────────
aws s3 mb s3://my-company-prod-bucket-2024         # Create bucket
aws s3 ls                                           # List all buckets
aws s3 ls s3://my-company-prod-bucket-2024         # List objects in bucket
aws s3 rb s3://my-company-prod-bucket-2024 --force # Delete bucket + contents

# ──────────────── FILE OPERATIONS ────────────────
aws s3 cp file.txt s3://my-bucket/                 # Upload file
aws s3 cp s3://my-bucket/file.txt ./               # Download file
aws s3 cp file.txt s3://my-bucket/ --storage-class GLACIER  # Upload to Glacier

aws s3 mv file.txt s3://my-bucket/archive/         # Move file
aws s3 rm s3://my-bucket/file.txt                  # Delete file
aws s3 rm s3://my-bucket/ --recursive              # Delete all objects

# ──────────────── SYNC (like rsync) ────────────────
aws s3 sync ./local-folder s3://my-bucket/backup/  # Upload folder
aws s3 sync s3://my-bucket/backup/ ./local-folder  # Download folder
aws s3 sync s3://source-bucket s3://dest-bucket    # Bucket to bucket

# ──────────────── VERSIONING ────────────────
aws s3api put-bucket-versioning \
    --bucket my-bucket \
    --versioning-configuration Status=Enabled

aws s3api list-object-versions --bucket my-bucket

# ──────────────── LIFECYCLE RULES ────────────────
# Automatically transition objects between storage classes
aws s3api put-bucket-lifecycle-configuration \
    --bucket my-bucket \
    --lifecycle-configuration '{
        "Rules": [
            {
                "ID": "MoveToIA",
                "Status": "Enabled",
                "Filter": {"Prefix": "logs/"},
                "Transitions": [
                    {"Days": 30, "StorageClass": "STANDARD_IA"},
                    {"Days": 90, "StorageClass": "GLACIER"},
                    {"Days": 365, "StorageClass": "DEEP_ARCHIVE"}
                ],
                "Expiration": {"Days": 730}
            }
        ]
    }'

# ──────────────── BUCKET POLICY (Public read example — be careful!) ────────────────
aws s3api put-bucket-policy --bucket my-bucket --policy '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::my-bucket/*"
        }
    ]
}'

# ──────────────── STATIC WEBSITE HOSTING ────────────────
aws s3 website s3://my-bucket \
    --index-document index.html \
    --error-document error.html

# ──────────────── PRESIGNED URLs (temporary access) ────────────────
aws s3 presign s3://my-bucket/private-file.pdf --expires-in 3600  # 1 hour

# ──────────────── ENCRYPTION ────────────────
# Enable default encryption (SSE-S3)
aws s3api put-bucket-encryption --bucket my-bucket \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "aws:kms",
                    "KMSMasterKeyID": "alias/my-key"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

# ──────────────── BLOCK PUBLIC ACCESS ────────────────
aws s3api put-public-access-block --bucket my-bucket \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
PART 13: ROUTE 53 — DNS SERVICE
13.1 What is Route 53?
text

Route 53 = AWS's Domain Name System (DNS) service.

DNS translates human-readable names to IP addresses:
  www.example.com → 93.184.216.34

RECORD TYPES:
┌──────────┬──────────────────────────────────────────────────────┐
│ Type     │ Purpose                                              │
├──────────┼──────────────────────────────────────────────────────┤
│ A        │ Maps domain to IPv4 address                         │
│ AAAA     │ Maps domain to IPv6 address                         │
│ CNAME    │ Maps domain to another domain (alias)               │
│ MX       │ Mail server records                                 │
│ TXT      │ Text records (verification, SPF)                    │
│ NS       │ Name server records                                 │
│ ALIAS    │ AWS-specific: Maps to AWS resources (free!)         │
└──────────┴──────────────────────────────────────────────────────┘

ROUTING POLICIES:
┌──────────────────┬─────────────────────────────────────────────┐
│ Policy           │ Use Case                                    │
├──────────────────┼─────────────────────────────────────────────┤
│ Simple           │ Single resource, no health checks           │
│ Weighted         │ Split traffic by percentage (A/B testing)   │
│ Latency          │ Route to lowest-latency region              │
│ Failover         │ Active-passive disaster recovery            │
│ Geolocation      │ Route by user's location                    │
│ Multi-Value      │ Return multiple healthy records             │
└──────────────────┴─────────────────────────────────────────────┘
Bash

# Create a hosted zone
aws route53 create-hosted-zone \
    --name example.com \
    --caller-reference $(date +%s)

# Create an A record pointing to ALB (ALIAS)
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch '{
        "Changes": [
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": "www.example.com",
                    "Type": "A",
                    "AliasTarget": {
                        "HostedZoneId": "Z35SXDOTRQ7X7K",
                        "DNSName": "production-alb-123456.us-east-1.elb.amazonaws.com",
                        "EvaluateTargetHealth": true
                    }
                }
            }
        ]
    }'

# Create a weighted routing record (90/10 split)
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch '{
        "Changes": [
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": "api.example.com",
                    "Type": "A",
                    "SetIdentifier": "production",
                    "Weight": 90,
                    "AliasTarget": {
                        "HostedZoneId": "Z35SXDOTRQ7X7K",
                        "DNSName": "prod-alb.us-east-1.elb.amazonaws.com",
                        "EvaluateTargetHealth": true
                    }
                }
            },
            {
                "Action": "CREATE",
                "ResourceRecordSet": {
                    "Name": "api.example.com",
                    "Type": "A",
                    "SetIdentifier": "canary",
                    "Weight": 10,
                    "AliasTarget": {
                        "HostedZoneId": "Z35SXDOTRQ7X7K",
                        "DNSName": "canary-alb.us-east-1.elb.amazonaws.com",
                        "EvaluateTargetHealth": true
                    }
                }
            }
        ]
    }'

# Create health check
aws route53 create-health-check \
    --caller-reference $(date +%s) \
    --health-check-config '{
        "Type": "HTTPS",
        "FullyQualifiedDomainName": "api.example.com",
        "Port": 443,
        "ResourcePath": "/health",
        "RequestInterval": 30,
        "FailureThreshold": 3
    }'
PART 14: IAM — IDENTITY & ACCESS MANAGEMENT (Deep Dive)
14.1 IAM Overview
text

IAM controls WHO can do WHAT on WHICH AWS resources.

┌───────────────────────────────────────────────────────────┐
│                    IAM COMPONENTS                          │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  USERS:    Individual people/applications                 │
│  GROUPS:   Collection of users (Developers, Admins, etc.)│
│  ROLES:    Temporary permissions for AWS services/users   │
│  POLICIES: JSON documents defining permissions            │
│                                                           │
│  ┌──────────────────────────────────────────────┐        │
│  │            IAM POLICY STRUCTURE               │        │
│  │                                                │        │
│  │  {                                             │        │
│  │    "Version": "2012-10-17",                   │        │
│  │    "Statement": [                              │        │
│  │      {                                         │        │
│  │        "Effect": "Allow" or "Deny",           │        │
│  │        "Action": "service:action",             │        │
│  │        "Resource": "arn:aws:...",             │        │
│  │        "Condition": { optional conditions }    │        │
│  │      }                                         │        │
│  │    ]                                           │        │
│  │  }                                             │        │
│  └──────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────┘

BEST PRACTICES:
✦ NEVER use root account for daily tasks
✦ Enable MFA on root and all users
✦ Follow LEAST PRIVILEGE principle
✦ Use ROLES instead of access keys when possible
✦ Rotate access keys regularly
✦ Use IAM groups to assign permissions
Bash

# ──────────────── USER MANAGEMENT ────────────────
aws iam create-user --user-name developer1
aws iam create-login-profile \
    --user-name developer1 \
    --password 'TempP@ss123!' \
    --password-reset-required

aws iam create-access-key --user-name developer1
aws iam list-users
aws iam delete-user --user-name developer1

# ──────────────── GROUP MANAGEMENT ────────────────
aws iam create-group --group-name Developers
aws iam add-user-to-group --user-name developer1 --group-name Developers
aws iam attach-group-policy \
    --group-name Developers \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess

# ──────────────── CUSTOM POLICY ────────────────
# Create policy allowing S3 read and EC2 describe
cat > custom-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowS3Read",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::my-app-bucket",
                "arn:aws:s3:::my-app-bucket/*"
            ]
        },
        {
            "Sid": "AllowEC2Describe",
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Sid": "DenyDeleteBucket",
            "Effect": "Deny",
            "Action": "s3:DeleteBucket",
            "Resource": "*"
        }
    ]
}
EOF

aws iam create-policy \
    --policy-name CustomDevPolicy \
    --policy-document file://custom-policy.json

# ──────────────── IAM ROLES ────────────────
# Create role for EC2 to access S3
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
    --role-name EC2-S3-Access \
    --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
    --role-name EC2-S3-Access \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create instance profile (needed to attach role to EC2)
aws iam create-instance-profile --instance-profile-name EC2-S3-Profile
aws iam add-role-to-instance-profile \
    --instance-profile-name EC2-S3-Profile \
    --role-name EC2-S3-Access

# Attach role to running EC2 instance
aws ec2 associate-iam-instance-profile \
    --instance-id i-1234567890abcdef0 \
    --iam-instance-profile Name=EC2-S3-Profile

# ──────────────── MFA ────────────────
aws iam enable-mfa-device \
    --user-name developer1 \
    --serial-number arn:aws:iam::123456789:mfa/developer1 \
    --authentication-code1 123456 \
    --authentication-code2 789012
PART 15: RDS & DynamoDB (DATABASES)
15.1 RDS (Relational Database Service)
text

RDS = Managed relational database service.

Supported Engines:
┌──────────────────┬──────────────────────────────────────┐
│ Engine           │ Notes                                │
├──────────────────┼──────────────────────────────────────┤
│ MySQL            │ Open source, most popular            │
│ PostgreSQL       │ Advanced features, JSON support      │
│ MariaDB          │ MySQL fork, community-driven         │
│ Oracle           │ Enterprise, licensing options        │
│ SQL Server       │ Microsoft ecosystem                  │
│ Aurora           │ AWS-built, 5x faster than MySQL     │
│                  │ 3x faster than PostgreSQL            │
└──────────────────┴──────────────────────────────────────┘

Features AWS manages for you:
  ✦ Automated backups (up to 35 days retention)
  ✦ Multi-AZ deployment (high availability)
  ✦ Read Replicas (scale reads)
  ✦ Automatic patching
  ✦ Monitoring
  ✦ Encryption at rest & in transit
Bash

# Create a MySQL RDS instance
aws rds create-db-instance \
    --db-instance-identifier prod-mysql \
    --db-instance-class db.t3.medium \
    --engine mysql \
    --engine-version "8.0" \
    --master-username admin \
    --master-user-password 'SuperSecret123!' \
    --allocated-storage 100 \
    --storage-type gp3 \
    --vpc-security-group-ids sg-db \
    --db-subnet-group-name my-db-subnet-group \
    --multi-az \
    --backup-retention-period 7 \
    --storage-encrypted \
    --no-publicly-accessible

# Create DB Subnet Group
aws rds create-db-subnet-group \
    --db-subnet-group-name my-db-subnet-group \
    --db-subnet-group-description "Private subnets for RDS" \
    --subnet-ids subnet-priv-1a subnet-priv-1b

# Create Read Replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier prod-mysql-replica \
    --source-db-instance-identifier prod-mysql \
    --db-instance-class db.t3.medium

# Create automated snapshot
aws rds create-db-snapshot \
    --db-instance-identifier prod-mysql \
    --db-snapshot-identifier prod-mysql-manual-backup

# List RDS instances
aws rds describe-db-instances \
    --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
    --output table

# Connect to MySQL RDS
mysql -h prod-mysql.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com \
      -u admin -p
15.2 DynamoDB (NoSQL)
text

DynamoDB = Fully managed NoSQL database, single-digit millisecond performance.

KEY CONCEPTS:
┌──────────────┬───────────────────────────────────────────────┐
│ Concept      │ Description                                   │
├──────────────┼───────────────────────────────────────────────┤
│ Table        │ Collection of items (like a SQL table)        │
│ Item         │ A row (collection of attributes)              │
│ Attribute    │ A column/field                                │
│ Partition Key│ Primary key (hash key)                        │
│ Sort Key     │ Optional secondary key for ordering           │
│ GSI          │ Global Secondary Index                        │
│ LSI          │ Local Secondary Index                         │
└──────────────┴───────────────────────────────────────────────┘

Capacity Modes:
  • On-Demand:  Pay per request, auto-scales (variable workloads)
  • Provisioned: Set RCU/WCU, predictable cost (steady workloads)
Bash

# Create table
aws dynamodb create-table \
    --table-name Users \
    --attribute-definitions \
        AttributeName=UserId,AttributeType=S \
        AttributeName=Email,AttributeType=S \
    --key-schema \
        AttributeName=UserId,KeyType=HASH \
    --global-secondary-indexes '[
        {
            "IndexName": "EmailIndex",
            "KeySchema": [{"AttributeName":"Email","KeyType":"HASH"}],
            "Projection": {"ProjectionType":"ALL"},
            "ProvisionedThroughput": {"ReadCapacityUnits":5,"WriteCapacityUnits":5}
        }
    ]' \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Put item
aws dynamodb put-item \
    --table-name Users \
    --item '{
        "UserId": {"S": "user123"},
        "Email": {"S": "john@example.com"},
        "Name": {"S": "John Doe"},
        "Age": {"N": "30"}
    }'

# Get item
aws dynamodb get-item \
    --table-name Users \
    --key '{"UserId": {"S": "user123"}}'

# Query
aws dynamodb query \
    --table-name Users \
    --key-condition-expression "UserId = :uid" \
    --expression-attribute-values '{":uid": {"S": "user123"}}'

# Scan (full table scan — expensive, use cautiously)
aws dynamodb scan --table-name Users

# Delete item
aws dynamodb delete-item \
    --table-name Users \
    --key '{"UserId": {"S": "user123"}}'
PART 16: LAMBDA — SERVERLESS COMPUTING
16.1 What is Lambda?
text

Lambda = Run code WITHOUT managing servers.

┌──────────────────────────────────────────────────────────────────┐
│                     LAMBDA CONCEPT                                │
│                                                                   │
│  Traditional:  You manage → OS, Patching, Scaling, Servers       │
│  Lambda:       You manage → JUST YOUR CODE                       │
│                                                                   │
│  HOW IT WORKS:                                                    │
│  ┌─────────┐     ┌──────────────┐     ┌──────────┐              │
│  │ Event   │────▶│ Lambda runs  │────▶│ Returns  │              │
│  │(trigger)│     │ your function│     │ result   │              │
│  └─────────┘     └──────────────┘     └──────────┘              │
│                                                                   │
│  TRIGGERS: API Gateway, S3, SQS, DynamoDB, CloudWatch Events,   │
│            SNS, Kinesis, ALB, and many more                      │
│                                                                   │
│  PRICING: Pay only for compute time (per ms) + requests          │
│           First 1M requests/month = FREE                         │
│           First 400,000 GB-seconds = FREE                        │
│                                                                   │
│  LIMITS:                                                          │
│    • Memory: 128 MB – 10,240 MB                                  │
│    • Timeout: Max 15 minutes                                     │
│    • Package size: 50 MB (zipped), 250 MB (unzipped)            │
│    • Concurrent executions: 1,000 (default, can increase)       │
│    • /tmp storage: 512 MB – 10,240 MB                           │
└──────────────────────────────────────────────────────────────────┘
Bash

# ──────────────── CREATE LAMBDA FUNCTION ────────────────

# Create function code
cat > index.js << 'EOF'
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event));
    
    const name = event.queryStringParameters?.name || 'World';
    
    return {
        statusCode: 200,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            message: `Hello, ${name}!`,
            timestamp: new Date().toISOString()
        })
    };
};
EOF

# Package the code
zip function.zip index.js

# Create IAM role for Lambda
cat > lambda-trust.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": { "Service": "lambda.amazonaws.com" },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
    --role-name lambda-execution-role \
    --assume-role-policy-document file://lambda-trust.json

aws iam attach-role-policy \
    --role-name lambda-execution-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create the Lambda function
aws lambda create-function \
    --function-name hello-api \
    --runtime nodejs20.x \
    --role arn:aws:iam::123456789:role/lambda-execution-role \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --memory-size 256 \
    --environment 'Variables={STAGE=production,DB_HOST=mydb.cluster-xyz.us-east-1.rds.amazonaws.com}'

# ──────────────── INVOKE LAMBDA ────────────────
aws lambda invoke \
    --function-name hello-api \
    --payload '{"queryStringParameters": {"name": "DevOps"}}' \
    --cli-binary-format raw-in-base64-out \
    output.json

cat output.json

# ──────────────── UPDATE FUNCTION CODE ────────────────
zip function.zip index.js
aws lambda update-function-code \
    --function-name hello-api \
    --zip-file fileb://function.zip

# ──────────────── ENVIRONMENT VARIABLES ────────────────
aws lambda update-function-configuration \
    --function-name hello-api \
    --environment 'Variables={STAGE=production,API_KEY=abc123}'

# ──────────────── VERSIONS & ALIASES ────────────────
aws lambda publish-version --function-name hello-api
aws lambda create-alias \
    --function-name hello-api \
    --name prod \
    --function-version 1

# ──────────────── LIST & DELETE ────────────────
aws lambda list-functions --query 'Functions[*].FunctionName'
aws lambda delete-function --function-name hello-api

# ──────────────── VIEW LOGS ────────────────
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/hello-api"
aws logs tail "/aws/lambda/hello-api" --follow
PART 17: DOCKER & CONTAINERIZATION
17.1 What is Docker?
text

┌──────────────────────────────────────────────────────────────────┐
│                    VM vs CONTAINER                                │
├─────────────────────────┬────────────────────────────────────────┤
│   Virtual Machine       │         Container                      │
│                         │                                        │
│ ┌─────┐ ┌─────┐ ┌─────┐│ ┌─────┐ ┌─────┐ ┌─────┐             │
│ │App 1│ │App 2│ │App 3││ │App 1│ │App 2│ │App 3│             │
│ ├─────┤ ├─────┤ ├─────┤│ ├─────┤ ├─────┤ ├─────┤             │
│ │Libs │ │Libs │ │Libs ││ │Libs │ │Libs │ │Libs │             │
│ ├─────┤ ├─────┤ ├─────┤│ └──┬──┘ └──┬──┘ └──┬──┘             │
│ │Guest│ │Guest│ │Guest││    └───────┼───────┘                  │
│ │ OS  │ │ OS  │ │ OS  ││    ┌──────▼──────┐                    │
│ └──┬──┘ └──┬──┘ └──┬──┘│    │Docker Engine│                    │
│    └───────┼───────┘   │    └──────┬──────┘                    │
│    ┌───────▼───────┐   │    ┌──────▼──────┐                    │
│    │  Hypervisor   │   │    │   Host OS   │                    │
│    └───────┬───────┘   │    └──────┬──────┘                    │
│    ┌───────▼───────┐   │    ┌──────▼──────┐                    │
│    │   Hardware    │   │    │  Hardware   │                    │
│    └───────────────┘   │    └─────────────┘                    │
│                         │                                        │
│ Heavy (GBs), Slow boot │ Light (MBs), Fast boot (seconds)     │
│ Full OS isolation       │ Process-level isolation               │
└─────────────────────────┴────────────────────────────────────────┘
17.2 Docker Commands
Bash

# ──────────────── INSTALL DOCKER ────────────────
sudo yum update -y && sudo yum install -y docker    # Amazon Linux
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker $USER                         # Run without sudo
newgrp docker                                         # Apply group change

# ──────────────── IMAGES ────────────────
docker pull nginx:latest                             # Download image
docker images                                         # List images
docker rmi nginx:latest                              # Remove image
docker build -t myapp:v1 .                           # Build from Dockerfile
docker tag myapp:v1 myrepo/myapp:v1                  # Tag image
docker push myrepo/myapp:v1                          # Push to registry

# ──────────────── CONTAINERS ────────────────
docker run -d --name web -p 80:80 nginx              # Run container
docker run -d --name app \
    -p 3000:3000 \
    -e NODE_ENV=production \
    -e DB_HOST=mydb.example.com \
    -v /host/data:/app/data \
    --restart unless-stopped \
    myapp:v1                                          # Full run command

docker ps                                             # List running containers
docker ps -a                                          # List ALL containers
docker logs -f web                                    # Follow container logs
docker exec -it web bash                             # Enter container shell
docker stop web                                       # Stop container
docker start web                                      # Start container
docker rm web                                         # Remove container
docker rm -f $(docker ps -aq)                        # Remove ALL containers

# ──────────────── DOCKER INSPECT & STATS ────────────────
docker inspect web                                    # Full container details
docker stats                                          # Live resource usage
docker top web                                        # Processes in container

# ──────────────── DOCKER NETWORK ────────────────
docker network create mynet                          # Create network
docker network ls                                     # List networks
docker run -d --name db --network mynet mysql        # Container on network
docker run -d --name app --network mynet myapp       # Can reach 'db' by name

# ──────────────── DOCKER VOLUMES ────────────────
docker volume create mydata                          # Create volume
docker volume ls                                      # List volumes
docker run -d -v mydata:/var/lib/mysql mysql         # Mount volume
docker run -d -v $(pwd)/config:/app/config myapp     # Bind mount

# ──────────────── DOCKER COMPOSE ────────────────
# docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - app
    restart: unless-stopped

  app:
    build: ./app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PASSWORD=${DB_PASSWORD}
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mysql:8.0
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
      - MYSQL_DATABASE=myapp
    restart: unless-stopped

volumes:
  db_data:
EOF

docker compose up -d                                  # Start all services
docker compose down                                   # Stop all services
docker compose logs -f                                # Follow all logs
docker compose ps                                     # List services
docker compose build                                  # Rebuild images
17.3 Dockerfile Best Practices
Dockerfile

# ──────────────── PRODUCTION DOCKERFILE ────────────────
# Multi-stage build for smaller image

# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Copy only necessary files
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

# Set user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["node", "dist/server.js"]

# ──────────────── BUILD & RUN ────────────────
# docker build -t myapp:v1 .
# docker run -d -p 3000:3000 myapp:v1
PART 18: ECR — ELASTIC CONTAINER REGISTRY
18.1 What is ECR?
text

ECR = AWS's private Docker image registry.

Think of it as Docker Hub, but private and integrated with AWS.

┌─────────────────────────────────────────────────────────┐
│                     ECR WORKFLOW                         │
│                                                          │
│  Developer                                               │
│     │                                                    │
│     ▼                                                    │
│  docker build ──▶ docker tag ──▶ docker push ──▶ ECR    │
│                                                    │     │
│                                                    ▼     │
│                              ECS / EKS / Lambda pulls    │
│                              images from ECR             │
└─────────────────────────────────────────────────────────┘

Features:
  ✦ Private & public repositories
  ✦ Image vulnerability scanning
  ✦ Lifecycle policies (auto-cleanup old images)
  ✦ Encryption at rest
  ✦ Cross-region replication
  ✦ Integrated with IAM for access control
Bash

# ──────────────── CREATE ECR REPOSITORY ────────────────
aws ecr create-repository \
    --repository-name myapp \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256

# ──────────────── LOGIN TO ECR ────────────────
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789012.dkr.ecr.us-east-1.amazonaws.com

# ──────────────── BUILD, TAG, PUSH ────────────────
docker build -t myapp:latest .

docker tag myapp:latest \
    123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

docker tag myapp:latest \
    123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# ──────────────── LIST IMAGES ────────────────
aws ecr list-images --repository-name myapp
aws ecr describe-images --repository-name myapp \
    --query 'imageDetails[*].[imageTags,imageSizeInBytes,imagePushedAt]' \
    --output table

# ──────────────── IMAGE SCANNING ────────────────
aws ecr start-image-scan \
    --repository-name myapp \
    --image-id imageTag=latest

aws ecr describe-image-scan-findings \
    --repository-name myapp \
    --image-id imageTag=latest

# ──────────────── LIFECYCLE POLICY (cleanup old images) ────────────────
aws ecr put-lifecycle-policy \
    --repository-name myapp \
    --lifecycle-policy-text '{
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 10 images",
                "selection": {
                    "tagStatus": "any",
                    "countType": "imageCountMoreThan",
                    "countNumber": 10
                },
                "action": {
                    "type": "expire"
                }
            },
            {
                "rulePriority": 2,
                "description": "Remove untagged images after 1 day",
                "selection": {
                    "tagStatus": "untagged",
                    "countType": "sinceImagePushed",
                    "countUnit": "days",
                    "countNumber": 1
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }'

# ──────────────── DELETE IMAGE ────────────────
aws ecr batch-delete-image \
    --repository-name myapp \
    --image-ids imageTag=old-version

# ──────────────── DELETE REPOSITORY ────────────────
aws ecr delete-repository --repository-name myapp --force
PART 19: ECS — ELASTIC CONTAINER SERVICE
19.1 What is ECS?
text

ECS = AWS's container orchestration service.
It runs and manages Docker containers at scale.

KEY CONCEPTS:
─────────────
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  CLUSTER: Logical grouping of tasks/services                 │
│     │                                                         │
│     ├── SERVICE: Maintains desired count of tasks            │
│     │     │       (ensures X copies are always running)      │
│     │     │                                                   │
│     │     └── TASK: Running instance of a task definition    │
│     │           │   (one or more containers)                 │
│     │           │                                             │
│     │           └── CONTAINER: Docker container running      │
│     │                          inside the task               │
│     │                                                         │
│     └── TASK DEFINITION: Blueprint for your application      │
│                          (like docker-compose.yml)           │
│                          - Docker image                      │
│                          - CPU/Memory                        │
│                          - Port mappings                     │
│                          - Environment variables             │
│                          - Log configuration                 │
│                                                               │
│  LAUNCH TYPES:                                                │
│  ┌──────────┬─────────────────────────────────────────────┐  │
│  │ EC2      │ You manage EC2 instances in the cluster     │  │
│  │          │ More control, potentially cheaper           │  │
│  ├──────────┼─────────────────────────────────────────────┤  │
│  │ Fargate  │ Serverless — AWS manages the infrastructure │  │
│  │          │ No EC2 instances to manage                  │  │
│  │          │ Pay per task resources                      │  │
│  └──────────┴─────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

ECS ARCHITECTURE:
─────────────────
┌──────────────────────────────────────────────────────────┐
│                     ECS CLUSTER                           │
│                                                           │
│  ┌─── Service: web-service (desired: 3) ───────────────┐ │
│  │                                                       │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐           │ │
│  │  │  Task 1  │  │  Task 2  │  │  Task 3  │           │ │
│  │  │┌────────┐│  │┌────────┐│  │┌────────┐│           │ │
│  │  ││  nginx ││  ││  nginx ││  ││  nginx ││           │ │
│  │  │└────────┘│  │└────────┘│  │└────────┘│           │ │
│  │  │┌────────┐│  │┌────────┐│  │┌────────┐│           │ │
│  │  ││  app   ││  ││  app   ││  ││  app   ││           │ │
│  │  │└────────┘│  │└────────┘│  │└────────┘│           │ │
│  │  └──────────┘  └──────────┘  └──────────┘           │ │
│  │      AZ-1a         AZ-1b         AZ-1a              │ │
│  └───────────────────────────────────────────────────────┘ │
│                         │                                   │
│              ┌──────────▼──────────┐                       │
│              │    ALB (web-alb)     │                       │
│              └─────────────────────┘                       │
└──────────────────────────────────────────────────────────┘
19.2 ECS Setup — Complete Walkthrough
Bash

# ══════════════════════════════════════════════════════════
# STEP 1: CREATE ECS CLUSTER
# ══════════════════════════════════════════════════════════
aws ecs create-cluster --cluster-name production

# ══════════════════════════════════════════════════════════
# STEP 2: CREATE TASK DEFINITION
# ══════════════════════════════════════════════════════════
cat > task-definition.json << 'EOF'
{
    "family": "web-app",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "512",
    "memory": "1024",
    "executionRoleArn": "arn:aws:iam::123456789:role/ecsTaskExecutionRole",
    "taskRoleArn": "arn:aws:iam::123456789:role/ecsTaskRole",
    "containerDefinitions": [
        {
            "name": "web",
            "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest",
            "essential": true,
            "portMappings": [
                {
                    "containerPort": 3000,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {"name": "NODE_ENV", "value": "production"},
                {"name": "PORT", "value": "3000"}
            ],
            "secrets": [
                {
                    "name": "DB_PASSWORD",
                    "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:db-password"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/web-app",
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                }
            },
            "healthCheck": {
                "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
                "interval": 30,
                "timeout": 5,
                "retries": 3,
                "startPeriod": 60
            }
        }
    ]
}
EOF

aws ecs register-task-definition \
    --cli-input-json file://task-definition.json

# ══════════════════════════════════════════════════════════
# STEP 3: CREATE LOG GROUP
# ══════════════════════════════════════════════════════════
aws logs create-log-group --log-group-name /ecs/web-app

# ══════════════════════════════════════════════════════════
# STEP 4: CREATE ECS SERVICE (with ALB)
# ══════════════════════════════════════════════════════════
aws ecs create-service \
    --cluster production \
    --service-name web-service \
    --task-definition web-app:1 \
    --desired-count 3 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-priv-1a", "subnet-priv-1b"],
            "securityGroups": ["sg-ecs-tasks"],
            "assignPublicIp": "DISABLED"
        }
    }' \
    --load-balancers '[
        {
            "targetGroupArn": "arn:aws:...:targetgroup/ecs-targets/...",
            "containerName": "web",
            "containerPort": 3000
        }
    ]' \
    --deployment-configuration '{
        "maximumPercent": 200,
        "minimumHealthyPercent": 100,
        "deploymentCircuitBreaker": {
            "enable": true,
            "rollback": true
        }
    }' \
    --enable-execute-command

# ══════════════════════════════════════════════════════════
# STEP 5: AUTO SCALING FOR ECS
# ══════════════════════════════════════════════════════════

# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/production/web-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 20

# CPU-based scaling
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/production/web-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
        "PredefinedMetricSpecification": {
            "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
        },
        "TargetValue": 50.0,
        "ScaleInCooldown": 300,
        "ScaleOutCooldown": 60
    }'

# ══════════════════════════════════════════════════════════
# ECS MANAGEMENT COMMANDS
# ══════════════════════════════════════════════════════════
# List services
aws ecs list-services --cluster production

# Describe service
aws ecs describe-services \
    --cluster production \
    --services web-service \
    --query 'services[*].[serviceName,desiredCount,runningCount,status]' \
    --output table

# List tasks
aws ecs list-tasks --cluster production --service-name web-service

# Force new deployment (rolling update)
aws ecs update-service \
    --cluster production \
    --service web-service \
    --force-new-deployment

# Scale service manually
aws ecs update-service \
    --cluster production \
    --service web-service \
    --desired-count 5

# Execute command in running container (debug)
aws ecs execute-command \
    --cluster production \
    --task arn:aws:ecs:...:task/production/abc123 \
    --container web \
    --interactive \
    --command "/bin/sh"

# View container logs
aws logs tail "/ecs/web-app" --follow

# Stop a task
aws ecs stop-task --cluster production --task arn:aws:ecs:...:task/...

# Delete service
aws ecs update-service --cluster production --service web-service --desired-count 0
aws ecs delete-service --cluster production --service web-service
PART 20: EKS — ELASTIC KUBERNETES SERVICE
20.1 What is EKS?
text

EKS = Managed Kubernetes service on AWS.

Kubernetes = An open-source container orchestration platform
             that automates deploying, scaling, and managing
             containerized applications.

ECS vs EKS:
┌─────────┬─────────────────────────────────────────────────┐
│ ECS     │ AWS-native, simpler, tightly integrated with AWS│
│ EKS     │ Kubernetes standard, portable, more complex     │
│         │ but industry standard                           │
└─────────┴─────────────────────────────────────────────────┘

Kubernetes Key Concepts:
┌────────────────┬────────────────────────────────────────────────┐
│ Pod            │ Smallest unit, one or more containers          │
│ Deployment     │ Manages replica sets and rolling updates       │
│ Service        │ Stable network endpoint for pods               │
│ Ingress        │ HTTP routing (like ALB)                        │
│ ConfigMap      │ Configuration data                             │
│ Secret         │ Sensitive data (passwords, keys)               │
│ Namespace      │ Virtual cluster within a cluster               │
│ Node           │ Worker machine (EC2 instance or Fargate)      │
│ Cluster        │ Set of nodes running containerized apps       │
└────────────────┴────────────────────────────────────────────────┘
Bash

# ──────────────── INSTALL TOOLS ────────────────
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install eksctl
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/

# ──────────────── CREATE EKS CLUSTER ────────────────
eksctl create cluster \
    --name production \
    --region us-east-1 \
    --version 1.29 \
    --nodegroup-name workers \
    --node-type t3.medium \
    --nodes 3 \
    --nodes-min 2 \
    --nodes-max 10 \
    --managed \
    --with-oidc \
    --ssh-access \
    --ssh-public-key my-key-pair

# Update kubeconfig
aws eks update-kubeconfig --name production --region us-east-1

# Verify
kubectl get nodes
kubectl cluster-info

# ──────────────── DEPLOY APPLICATION ────────────────
# deployment.yaml
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: web
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 3000
EOF

kubectl apply -f deployment.yaml

# ──────────────── KUBERNETES COMMANDS ────────────────
kubectl get pods                                  # List pods
kubectl get pods -o wide                          # With more details
kubectl get services                              # List services
kubectl get deployments                           # List deployments
kubectl describe pod <pod-name>                   # Pod details
kubectl logs <pod-name> -f                        # Follow logs
kubectl exec -it <pod-name> -- /bin/sh           # Enter pod shell
kubectl scale deployment web-app --replicas=5     # Scale up
kubectl delete -f deployment.yaml                 # Delete resources

# ──────────────── HORIZONTAL POD AUTOSCALER ────────────────
kubectl autoscale deployment web-app \
    --min=2 --max=20 --cpu-percent=50

kubectl get hpa

# ──────────────── DELETE CLUSTER ────────────────
eksctl delete cluster --name production --region us-east-1
PART 21: AWS FARGATE
21.1 What is Fargate?
text

Fargate = SERVERLESS compute engine for CONTAINERS.

┌──────────────────────────────────────────────────────────────┐
│                 EC2 vs FARGATE COMPARISON                      │
├────────────────────┬─────────────────┬───────────────────────┤
│ Aspect             │ EC2 Launch Type │ Fargate               │
├────────────────────┼─────────────────┼───────────────────────┤
│ Server management  │ YOU manage EC2  │ AWS manages servers   │
│ Scaling infra      │ YOU scale EC2   │ Auto-scaled           │
│ Patching           │ YOU patch OS    │ AWS patches           │
│ Pricing            │ Pay for EC2     │ Pay per task resources│
│ Control            │ Full control    │ Less control          │
│ Cost (large scale) │ Usually cheaper │ Usually more expensive│
│ Cost (small scale) │ More expensive  │ Usually cheaper       │
│ Security           │ Shared kernel   │ Isolated microVM      │
│ Startup time       │ Faster          │ Slightly slower       │
└────────────────────┴─────────────────┴───────────────────────┘

WHEN TO USE FARGATE:
  ✅ Small to medium workloads
  ✅ Don't want to manage infrastructure
  ✅ Batch jobs, microservices
  ✅ Variable workloads with lots of scaling
  ✅ Quick experiments and prototyping

WHEN TO USE EC2:
  ✅ Large, steady workloads (cost savings)
  ✅ Need GPU instances
  ✅ Need specific instance types
  ✅ Need to customize the host OS
Bash

# Using Fargate with ECS (just change launch type)
aws ecs create-service \
    --cluster production \
    --service-name api-service \
    --task-definition api-task:1 \
    --desired-count 3 \
    --launch-type FARGATE \                    # ◀── This makes it Fargate!
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-priv-1a", "subnet-priv-1b"],
            "securityGroups": ["sg-ecs"],
            "assignPublicIp": "DISABLED"
        }
    }'

# Using Fargate with EKS
# In your EKS cluster, create a Fargate profile:
eksctl create fargateprofile \
    --cluster production \
    --name fp-default \
    --namespace default \
    --labels app=web-app

# Any pod matching namespace=default AND label app=web-app
# will automatically run on Fargate instead of EC2 nodes!
PART 22: WAF — WEB APPLICATION FIREWALL
22.1 What is WAF?
text

WAF = Web Application Firewall that protects your web apps
      from common web exploits.

WAF sits in FRONT of your application and inspects every
HTTP/HTTPS request.

┌────────────────────────────────────────────────────────────┐
│                     WAF ARCHITECTURE                        │
│                                                             │
│  User Request                                               │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────┐                                                │
│  │   WAF   │ ◀── Inspects every request                    │
│  └────┬────┘                                                │
│       │                                                     │
│       ├── ✅ ALLOW (legitimate request)                     │
│       │       │                                             │
│       │       ▼                                             │
│       │   ┌─────────────┐                                   │
│       │   │ CloudFront  │                                   │
│       │   │  or ALB     │ → Application                    │
│       │   └─────────────┘                                   │
│       │                                                     │
│       └── ❌ BLOCK (malicious request)                      │
│               │                                             │
│               ▼                                             │
│           403 Forbidden                                     │
│                                                             │
│  WHAT WAF PROTECTS AGAINST:                                 │
│  ✦ SQL Injection (SQLi)                                     │
│  ✦ Cross-Site Scripting (XSS)                               │
│  ✦ IP-based blocking                                        │
│  ✦ Rate limiting (DDoS protection)                          │
│  ✦ Geo-blocking (country-based)                             │
│  ✦ Bot detection                                            │
│  ✦ Custom rules                                             │
│                                                             │
│  CAN BE ATTACHED TO:                                        │
│  ✦ CloudFront distributions                                 │
│  ✦ Application Load Balancers (ALB)                         │
│  ✦ API Gateway                                              │
│  ✦ AppSync (GraphQL)                                        │
│  ✦ Cognito User Pools                                       │
└────────────────────────────────────────────────────────────┘
22.2 WAF Components
text

┌───────────────────────────────────────────────────────────┐
│                     WAF COMPONENTS                         │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  WEB ACL (Access Control List)                            │
│  └── Container for rules, attached to AWS resources       │
│                                                           │
│  RULES                                                    │
│  ├── Regular Rule: Match conditions → action              │
│  └── Rate-based Rule: Count requests per IP → action      │
│                                                           │
│  RULE GROUPS                                              │
│  ├── AWS Managed Rules (pre-built)                        │
│  │   ├── AWSManagedRulesCommonRuleSet (OWASP top 10)    │
│  │   ├── AWSManagedRulesSQLiRuleSet                      │
│  │   ├── AWSManagedRulesKnownBadInputsRuleSet           │
│  │   ├── AWSManagedRulesLinuxRuleSet                     │
│  │   └── AWSManagedRulesBotControlRuleSet                │
│  └── Custom Rule Groups (your rules)                     │
│                                                           │
│  ACTIONS:                                                 │
│  ├── ALLOW  → Let the request through                    │
│  ├── BLOCK  → Return 403 Forbidden                       │
│  ├── COUNT  → Count (for testing, doesn't block)         │
│  └── CAPTCHA → Challenge with CAPTCHA                    │
│                                                           │
└───────────────────────────────────────────────────────────┘
Bash

# ══════════════════════════════════════════════════════════
# CREATE WAF WEB ACL
# ══════════════════════════════════════════════════════════

# Create IP Set (for whitelisting/blacklisting)
aws wafv2 create-ip-set \
    --name blocked-ips \
    --scope REGIONAL \
    --ip-address-version IPV4 \
    --addresses "198.51.100.0/24" "203.0.113.50/32"

# Create Web ACL with AWS managed rules
aws wafv2 create-web-acl \
    --name production-waf \
    --scope REGIONAL \
    --default-action '{"Allow": {}}' \
    --visibility-config '{
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "production-waf"
    }' \
    --rules '[
        {
            "Name": "AWS-CommonRuleSet",
            "Priority": 1,
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesCommonRuleSet"
                }
            },
            "OverrideAction": {"None": {}},
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "CommonRuleSet"
            }
        },
        {
            "Name": "AWS-SQLiRuleSet",
            "Priority": 2,
            "Statement": {
                "ManagedRuleGroupStatement": {
                    "VendorName": "AWS",
                    "Name": "AWSManagedRulesSQLiRuleSet"
                }
            },
            "OverrideAction": {"None": {}},
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "SQLiRuleSet"
            }
        },
        {
            "Name": "RateLimit",
            "Priority": 3,
            "Statement": {
                "RateBasedStatement": {
                    "Limit": 2000,
                    "AggregateKeyType": "IP"
                }
            },
            "Action": {"Block": {}},
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "RateLimit"
            }
        },
        {
            "Name": "BlockBadIPs",
            "Priority": 0,
            "Statement": {
                "IPSetReferenceStatement": {
                    "ARN": "arn:aws:wafv2:...:regional/ipset/blocked-ips/..."
                }
            },
            "Action": {"Block": {}},
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "BlockBadIPs"
            }
        },
        {
            "Name": "GeoBlock",
            "Priority": 4,
            "Statement": {
                "GeoMatchStatement": {
                    "CountryCodes": ["RU", "CN", "KP"]
                }
            },
            "Action": {"Block": {}},
            "VisibilityConfig": {
                "SampledRequestsEnabled": true,
                "CloudWatchMetricsEnabled": true,
                "MetricName": "GeoBlock"
            }
        }
    ]'

# Associate WAF with ALB
aws wafv2 associate-web-acl \
    --web-acl-arn arn:aws:wafv2:...:regional/webacl/production-waf/... \
    --resource-arn arn:aws:elasticloadbalancing:...:loadbalancer/app/production-alb/...

# ──────────────── MONITORING WAF ────────────────
# Get sampled requests
aws wafv2 get-sampled-requests \
    --web-acl-arn arn:aws:wafv2:...:regional/webacl/production-waf/... \
    --rule-metric-name CommonRuleSet \
    --scope REGIONAL \
    --time-window '{"StartTime": "2024-01-01T00:00:00Z", "EndTime": "2024-01-02T00:00:00Z"}' \
    --max-items 100

# List Web ACLs
aws wafv2 list-web-acls --scope REGIONAL
PART 23: CLOUDFRONT — CDN
23.1 What is CloudFront?
text

CloudFront = AWS's Content Delivery Network (CDN).

It caches your content at 400+ edge locations worldwide
so users get content from the CLOSEST location.

WITHOUT CDN:
  User in Tokyo ──── 150ms ────▶ Server in Virginia
                                 (high latency)

WITH CloudFront:
  User in Tokyo ──── 5ms ─────▶ Edge Location in Tokyo ✅
                                 (cached content, fast!)

┌──────────────────────────────────────────────────────────────┐
│                 CLOUDFRONT ARCHITECTURE                        │
│                                                               │
│  Users worldwide                                              │
│     │                                                         │
│     ▼                                                         │
│  ┌─────────────────────────────────────┐                      │
│  │      CloudFront Edge Locations      │                      │
│  │  (400+ locations globally)          │                      │
│  │                                     │                      │
│  │  Tokyo  London  São Paulo  Sydney   │                      │
│  └──────────────┬──────────────────────┘                      │
│                 │                                              │
│           Cache MISS?                                          │
│                 │                                              │
│                 ▼                                              │
│  ┌─────────────────────────────────────┐                      │
│  │       ORIGIN (your content)          │                      │
│  │  • S3 Bucket                         │                      │
│  │  • ALB                               │                      │
│  │  • EC2                               │                      │
│  │  • Custom HTTP server               │                      │
│  └─────────────────────────────────────┘                      │
└──────────────────────────────────────────────────────────────┘
Bash

# Create CloudFront distribution (S3 origin)
aws cloudfront create-distribution \
    --distribution-config '{
        "CallerReference": "my-dist-2024",
        "Origins": {
            "Quantity": 1,
            "Items": [
                {
                    "Id": "S3-my-bucket",
                    "DomainName": "my-bucket.s3.amazonaws.com",
                    "S3OriginConfig": {
                        "OriginAccessIdentity": "origin-access-identity/cloudfront/ABCDEFG"
                    }
                }
            ]
        },
        "DefaultCacheBehavior": {
            "TargetOriginId": "S3-my-bucket",
            "ViewerProtocolPolicy": "redirect-to-https",
            "AllowedMethods": {
                "Quantity": 2,
                "Items": ["GET", "HEAD"]
            },
            "ForwardedValues": {
                "QueryString": false,
                "Cookies": {"Forward": "none"}
            },
            "MinTTL": 0,
            "DefaultTTL": 86400,
            "MaxTTL": 31536000
        },
        "Enabled": true,
        "DefaultRootObject": "index.html",
        "Comment": "My website CDN"
    }'

# Invalidate cache
aws cloudfront create-invalidation \
    --distribution-id E1234567890 \
    --paths "/*"

# List distributions
aws cloudfront list-distributions \
    --query 'DistributionList.Items[*].[Id,DomainName,Status]' \
    --output table
PART 24: CLOUDWATCH — MONITORING
24.1 What is CloudWatch?
text

CloudWatch = AWS's monitoring and observability service.

THREE PILLARS:
┌───────────────────────────────────────────────────────────┐
│                                                           │
│  1. METRICS  → Numerical data points over time            │
│     (CPU utilization, network traffic, request count)     │
│                                                           │
│  2. LOGS     → Application and system logs                │
│     (Error logs, access logs, Lambda output)              │
│                                                           │
│  3. ALARMS   → Notifications when metrics cross thresholds│
│     (Alert when CPU > 80%, alert when errors spike)       │
│                                                           │
│  BONUS:                                                   │
│  4. DASHBOARDS → Visual monitoring panels                 │
│  5. EVENTS     → React to AWS resource changes            │
│  6. INSIGHTS   → Query and analyze log data               │
└───────────────────────────────────────────────────────────┘
Bash

# ──────────────── METRICS ────────────────
# List available metrics for EC2
aws cloudwatch list-metrics --namespace AWS/EC2

# Get CPU utilization for an instance
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
    --start-time $(date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average Maximum

# Push custom metric
aws cloudwatch put-metric-data \
    --namespace MyApp \
    --metric-name ActiveUsers \
    --value 1523 \
    --unit Count

# ──────────────── ALARMS ────────────────
# Create CPU alarm
aws cloudwatch put-metric-alarm \
    --alarm-name high-cpu-alarm \
    --alarm-description "Alert when CPU > 80%" \
    --metric-name CPUUtilization \
    --namespace AWS/EC2 \
    --statistic Average \
    --period 300 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 2 \
    --alarm-actions arn:aws:sns:us-east-1:123456789:alerts \
    --dimensions Name=InstanceId,Value=i-1234567890abcdef0

# List alarms
aws cloudwatch describe-alarms --state-value ALARM

# ──────────────── LOGS ────────────────
# Create log group
aws logs create-log-group --log-group-name /app/production

# Set retention
aws logs put-retention-policy \
    --log-group-name /app/production \
    --retention-in-days 30

# Put log events
aws logs put-log-events \
    --log-group-name /app/production \
    --log-stream-name server-1 \
    --log-events '[
        {"timestamp": 1704067200000, "message": "Application started successfully"},
        {"timestamp": 1704067201000, "message": "Connected to database"}
    ]'

# Search logs
aws logs filter-log-events \
    --log-group-name /app/production \
    --filter-pattern "ERROR" \
    --start-time $(date -u -d '-1 hour' +%s)000

# Tail logs in real-time
aws logs tail /app/production --follow

# CloudWatch Logs Insights query
aws logs start-query \
    --log-group-name /app/production \
    --start-time $(date -u -d '-1 hour' +%s) \
    --end-time $(date -u +%s) \
    --query-string '
        fields @timestamp, @message
        | filter @message like /ERROR/
        | sort @timestamp desc
        | limit 20
    '

# ──────────────── DASHBOARD ────────────────
aws cloudwatch put-dashboard \
    --dashboard-name Production \
    --dashboard-body '{
        "widgets": [
            {
                "type": "metric",
                "x": 0, "y": 0, "width": 12, "height": 6,
                "properties": {
                    "metrics": [
                        ["AWS/EC2", "CPUUtilization", "InstanceId", "i-1234567890abcdef0"]
                    ],
                    "period": 300,
                    "stat": "Average",
                    "region": "us-east-1",
                    "title": "EC2 CPU Utilization"
                }
            }
        ]
    }'
PART 25: INFRASTRUCTURE AS CODE (IaC)
25.1 CloudFormation
text

CloudFormation = AWS's native IaC service.
Define your infrastructure in YAML/JSON templates.

BENEFITS:
✦ Version control your infrastructure
✦ Repeatable deployments
✦ Automatic rollback on failure
✦ Drift detection
✦ Dependency management
YAML

# cloudformation-template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Production Web Application Stack'

Parameters:
  Environment:
    Type: String
    Default: production
    AllowedValues: [production, staging, development]
  InstanceType:
    Type: String
    Default: t3.medium
  KeyPairName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair

Resources:
  # VPC
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-vpc'

  # Public Subnet
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-public-1'

  # Internet Gateway
  IGW:
    Type: AWS::EC2::InternetGateway

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref IGW

  # Security Group
  WebSG:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Web Server Security Group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  # EC2 Instance
  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: !Ref InstanceType
      ImageId: ami-0c55b159cbfafe1f0
      KeyName: !Ref KeyPairName
      SubnetId: !Ref PublicSubnet1
      SecurityGroupIds:
        - !Ref WebSG
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-web-server'

Outputs:
  WebServerPublicIP:
    Description: Public IP of the web server
    Value: !GetAtt WebServer.PublicIp
  VPCId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub '${Environment}-VPCId'
Bash

# Deploy CloudFormation stack
aws cloudformation create-stack \
    --stack-name production-web \
    --template-body file://cloudformation-template.yaml \
    --parameters \
        ParameterKey=Environment,ParameterValue=production \
        ParameterKey=InstanceType,ParameterValue=t3.medium \
        ParameterKey=KeyPairName,ParameterValue=my-key \
    --capabilities CAPABILITY_IAM

# Update stack
aws cloudformation update-stack \
    --stack-name production-web \
    --template-body file://cloudformation-template.yaml

# Check stack status
aws cloudformation describe-stacks --stack-name production-web
aws cloudformation describe-stack-events --stack-name production-web

# Delete stack
aws cloudformation delete-stack --stack-name production-web
25.2 Terraform
text

Terraform = HashiCorp's IaC tool (works with ANY cloud provider).

Terraform vs CloudFormation:
┌───────────────────┬──────────────────┬──────────────────┐
│ Feature           │ CloudFormation   │ Terraform        │
├───────────────────┼──────────────────┼──────────────────┤
│ Provider          │ AWS only         │ Multi-cloud      │
│ Language          │ YAML/JSON        │ HCL              │
│ State management  │ AWS manages      │ You manage       │
│ Drift detection   │ Built-in         │ terraform plan   │
│ Community modules │ Limited          │ Huge ecosystem   │
└───────────────────┴──────────────────┴──────────────────┘
hcl

# main.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "production"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-1"
  }
}

# Security Group
resource "aws_security_group" "web" {
  name        = "${var.environment}-web-sg"
  description = "Web server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    echo "<h1>Hello from Terraform!</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "${var.environment}-web-server"
    Environment = var.environment
  }
}

# Outputs
output "web_server_ip" {
  value = aws_instance.web.public_ip
}
Bash

# ──────────────── TERRAFORM COMMANDS ────────────────
terraform init                    # Initialize providers & backend
terraform fmt                     # Format code
terraform validate                # Validate syntax
terraform plan                    # Preview changes (DRY RUN)
terraform apply                   # Apply changes
terraform apply -auto-approve     # Apply without confirmation
terraform destroy                 # Destroy all resources
terraform state list              # List resources in state
terraform state show aws_instance.web  # Show resource details
terraform output                  # Show outputs
terraform import aws_instance.web i-1234567890  # Import existing resource
terraform workspace list          # List workspaces
terraform workspace new staging   # Create new workspace
PART 26: SNS & SQS — MESSAGING
26.1 SNS (Simple Notification Service)
text

SNS = Pub/Sub messaging service.
One message → delivered to MANY subscribers simultaneously.

┌───────────┐     ┌───────────┐     ┌─── Email
│ Publisher  │────▶│ SNS Topic │────▶├─── SMS
│ (app, CW) │     └───────────┘     ├─── Lambda
└───────────┘                       ├─── SQS
                                    ├─── HTTP endpoint
                                    └─── Mobile push
Bash

# Create topic
aws sns create-topic --name alerts
# Returns: arn:aws:sns:us-east-1:123456789:alerts

# Subscribe email
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789:alerts \
    --protocol email \
    --notification-endpoint ops-team@company.com

# Subscribe Lambda
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789:alerts \
    --protocol lambda \
    --notification-endpoint arn:aws:lambda:...:function:alert-handler

# Publish message
aws sns publish \
    --topic-arn arn:aws:sns:us-east-1:123456789:alerts \
    --subject "CRITICAL: High CPU Alert" \
    --message "CPU utilization exceeded 90% on production-web-server"
26.2 SQS (Simple Queue Service)
text

SQS = Message queue for decoupling services.
Messages are stored until a consumer processes them.

Producer ──▶ SQS Queue ──▶ Consumer

Two types:
┌──────────────┬──────────────────────────────────────────────┐
│ Standard     │ Unlimited throughput, at-least-once delivery │
│              │ Best-effort ordering                          │
├──────────────┼──────────────────────────────────────────────┤
│ FIFO         │ 300 msg/s, exactly-once delivery             │
│              │ Strict ordering guaranteed                    │
└──────────────┴──────────────────────────────────────────────┘
Bash

# Create queue
aws sqs create-queue \
    --queue-name order-processing \
    --attributes '{
        "VisibilityTimeout": "30",
        "MessageRetentionPeriod": "86400",
        "ReceiveMessageWaitTimeSeconds": "20"
    }'

# Send message
aws sqs send-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789/order-processing \
    --message-body '{"orderId": "12345", "amount": 99.99}' \
    --message-attributes '{"OrderType": {"DataType": "String", "StringValue": "express"}}'

# Receive message
aws sqs receive-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789/order-processing \
    --max-number-of-messages 10 \
    --wait-time-seconds 20

# Delete message (after processing)
aws sqs delete-message \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789/order-processing \
    --receipt-handle "AQEBwJnKyr..."

# Create Dead Letter Queue (for failed messages)
aws sqs create-queue --queue-name order-processing-dlq

aws sqs set-queue-attributes \
    --queue-url https://sqs.us-east-1.amazonaws.com/123456789/order-processing \
    --attributes '{
        "RedrivePolicy": "{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:123456789:order-processing-dlq\",\"maxReceiveCount\":\"3\"}"
    }'
PART 27: AWS CODE PIPELINE, CODEBUILD, CODEDEPLOY
27.1 AWS CI/CD Services Overview
text

┌──────────────────────────────────────────────────────────────────┐
│                    AWS CI/CD PIPELINE                             │
│                                                                   │
│  ┌────────────┐    ┌────────────┐    ┌─────────────┐    ┌─────┐ │
│  │ CodeCommit │───▶│ CodeBuild  │───▶│ CodeDeploy  │───▶│ ECS │ │
│  │ (Source)   │    │ (Build/Test)│    │ (Deploy)    │    │ EC2 │ │
│  └────────────┘    └────────────┘    └─────────────┘    │ EKS │ │
│        │                                                 └─────┘ │
│        │           ┌──────────────────────────────────┐          │
│        └──────────▶│     CodePipeline (Orchestrator)  │          │
│                    │     Ties all stages together      │          │
│                    └──────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘

CodeCommit  = AWS's Git repository (like GitHub)
CodeBuild   = Managed build service (like Jenkins)
CodeDeploy  = Automated deployment service
CodePipeline = Orchestrates the entire CI/CD workflow
YAML

# buildspec.yml (CodeBuild)
version: 0.2

env:
  variables:
    AWS_DEFAULT_REGION: us-east-1
    IMAGE_REPO_NAME: myapp
  secrets-manager:
    DOCKER_HUB_PASSWORD: dockerhub:password

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  
  build:
    commands:
      - echo Build started on `date`
      - echo Running tests...
      - npm ci
      - npm test
      - echo Building Docker image...
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  
  post_build:
    commands:
      - echo Pushing Docker image...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
      - echo Writing image definition file...
      - printf '[{"name":"web","imageUri":"%s"}]' $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
    - appspec.yml
    - taskdef.json

cache:
  paths:
    - 'node_modules/**/*'
Bash

# Create CodePipeline
aws codepipeline create-pipeline --cli-input-json file://pipeline.json

# Example pipeline.json structure
cat > pipeline.json << 'EOF'
{
    "pipeline": {
        "name": "production-pipeline",
        "roleArn": "arn:aws:iam::123456789:role/codepipeline-role",
        "stages": [
            {
                "name": "Source",
                "actions": [{
                    "name": "GitHub-Source",
                    "actionTypeId": {
                        "category": "Source",
                        "owner": "ThirdParty",
                        "provider": "GitHub",
                        "version": "1"
                    },
                    "configuration": {
                        "Owner": "myorg",
                        "Repo": "myapp",
                        "Branch": "main",
                        "OAuthToken": "{{resolve:secretsmanager:github-token}}"
                    },
                    "outputArtifacts": [{"name": "SourceOutput"}]
                }]
            },
            {
                "name": "Build",
                "actions": [{
                    "name": "CodeBuild",
                    "actionTypeId": {
                        "category": "Build",
                        "owner": "AWS",
                        "provider": "CodeBuild",
                        "version": "1"
                    },
                    "inputArtifacts": [{"name": "SourceOutput"}],
                    "outputArtifacts": [{"name": "BuildOutput"}],
                    "configuration": {
                        "ProjectName": "myapp-build"
                    }
                }]
            },
            {
                "name": "Deploy",
                "actions": [{
                    "name": "ECS-Deploy",
                    "actionTypeId": {
                        "category": "Deploy",
                        "owner": "AWS",
                        "provider": "ECS",
                        "version": "1"
                    },
                    "inputArtifacts": [{"name": "BuildOutput"}],
                    "configuration": {
                        "ClusterName": "production",
                        "ServiceName": "web-service",
                        "FileName": "imagedefinitions.json"
                    }
                }]
            }
        ]
    }
}
EOF
PART 28: PORT FORWARDING & BASTION HOSTS
28.1 Bastion Host (Jump Box)
text

PROBLEM: Your private instances have NO public IP.
         How do you SSH into them?

SOLUTION: Bastion Host — a hardened EC2 instance in a
          PUBLIC subnet that acts as a gateway to PRIVATE instances.

┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Your Laptop                                                  │
│      │                                                        │
│      │ SSH (port 22)                                          │
│      ▼                                                        │
│  ┌──────────┐  Public Subnet                                  │
│  │ Bastion  │  (10.0.1.0/24)                                 │
│  │  Host    │  Public IP: 54.x.x.x                           │
│  └────┬─────┘                                                 │
│       │                                                       │
│       │ SSH (port 22)                                         │
│       ▼                                                       │
│  ┌──────────┐  Private Subnet                                 │
│  │ Private  │  (10.0.3.0/24)                                 │
│  │  Server  │  Private IP: 10.0.3.15                         │
│  └──────────┘  NO public IP                                  │
│                                                               │
└──────────────────────────────────────────────────────────────┘
Bash

# ──────────────── SET UP BASTION HOST ────────────────

# Launch bastion in public subnet
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1f0 \
    --instance-type t3.micro \
    --key-name bastion-key \
    --subnet-id subnet-pub-1a \
    --security-group-ids sg-bastion \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion}]'

# Bastion security group: Allow SSH only from your IP
aws ec2 authorize-security-group-ingress \
    --group-id sg-bastion \
    --protocol tcp \
    --port 22 \
    --cidr YOUR_PUBLIC_IP/32

# Private instance SG: Allow SSH only from bastion SG
aws ec2 authorize-security-group-ingress \
    --group-id sg-private \
    --protocol tcp \
    --port 22 \
    --source-group sg-bastion

# ──────────────── METHOD 1: SSH ProxyJump (Recommended) ────────────────
ssh -J ec2-user@<bastion-public-ip> ec2-user@<private-ip>

# With key files:
ssh -i private-key.pem \
    -o ProxyCommand="ssh -i bastion-key.pem -W %h:%p ec2-user@<bastion-ip>" \
    ec2-user@10.0.3.15

# ──────────────── METHOD 2: SSH Config File ────────────────
cat >> ~/.ssh/config << 'EOF'
Host bastion
    HostName 54.x.x.x
    User ec2-user
    IdentityFile ~/.ssh/bastion-key.pem

Host private-server
    HostName 10.0.3.15
    User ec2-user
    IdentityFile ~/.ssh/private-key.pem
    ProxyJump bastion
EOF

# Now simply:
ssh private-server

# ──────────────── METHOD 3: SSH Agent Forwarding ────────────────
eval $(ssh-agent)
ssh-add bastion-key.pem
ssh-add private-key.pem
ssh -A ec2-user@<bastion-ip>
# Then from bastion:
ssh ec2-user@10.0.3.15
28.2 AWS Systems Manager Session Manager (BETTER Alternative)
text

Session Manager = SSH without SSH!
No bastion host needed. No port 22. No key pairs.

BENEFITS:
✦ No need to open port 22
✦ No bastion host to manage
✦ All sessions are logged (audit trail)
✦ Works through IAM (no key pairs)
✦ Works even in private subnets (via VPC endpoints)
Bash

# Prerequisite: EC2 instance must have SSM Agent and IAM role
# with AmazonSSMManagedInstanceCore policy

# Start session
aws ssm start-session --target i-1234567890abcdef0

# Port forwarding through Session Manager
aws ssm start-session \
    --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3306"],"localPortNumber":["3306"]}'

# Now connect to RDS through the tunnel:
# mysql -h 127.0.0.1 -P 3306 -u admin -p

# Port forwarding to remote host (e.g., RDS endpoint)
aws ssm start-session \
    --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{
        "host": ["mydb.cluster-xyz.us-east-1.rds.amazonaws.com"],
        "portNumber": ["3306"],
        "localPortNumber": ["3306"]
    }'
28.3 Port Forwarding
text

PORT FORWARDING = Redirect network traffic from one port to another.

LOCAL PORT FORWARDING (SSH Tunnel):
───────────────────────────────────
Access a remote service through your local machine.

Your Laptop:3306 ────SSH Tunnel────▶ Bastion ────▶ RDS:3306

You connect to localhost:3306, traffic goes through SSH
tunnel to reach RDS in a private subnet.
Bash

# ──────────────── SSH LOCAL PORT FORWARDING ────────────────
# Forward local port 3306 to RDS through bastion
ssh -i bastion-key.pem \
    -L 3306:mydb.cluster-xyz.us-east-1.rds.amazonaws.com:3306 \
    -N ec2-user@<bastion-public-ip>

# -L = Local port forwarding
# -N = Don't execute a command (just forward)

# Now on your laptop:
mysql -h 127.0.0.1 -P 3306 -u admin -p

# ──────────────── MULTIPLE PORT FORWARDS ────────────────
ssh -i bastion-key.pem \
    -L 3306:rds-endpoint:3306 \
    -L 6379:redis-endpoint:6379 \
    -L 9200:elasticsearch-endpoint:9200 \
    -N ec2-user@<bastion-ip>

# ──────────────── DYNAMIC PORT FORWARDING (SOCKS Proxy) ────────────────
ssh -i bastion-key.pem \
    -D 1080 \
    -N ec2-user@<bastion-ip>

# Configure your browser to use SOCKS proxy localhost:1080
# Now you can access private resources through your browser!

# ──────────────── REMOTE PORT FORWARDING ────────────────
# Expose your local service to the remote server
ssh -i key.pem \
    -R 8080:localhost:3000 \
    ec2-user@<server-ip>
# Now server:8080 forwards to your localhost:3000

# ──────────────── IPTABLES PORT FORWARDING (on Linux) ────────────────
# Forward port 80 to port 8080 on the same machine
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Forward port 80 to another machine
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.0.3.15:8080
sudo iptables -t nat -A POSTROUTING -j MASQUERADE
PART 29: SECRETS MANAGER & PARAMETER STORE
29.1 Secrets Manager
text

Secrets Manager = Securely store and rotate secrets
(database passwords, API keys, tokens).

Features:
✦ Automatic rotation
✦ Encryption with KMS
✦ Audit access with CloudTrail
✦ Cross-account access
✦ Costs: $0.40/secret/month + $0.05/10,000 API calls
Bash

# Create a secret
aws secretsmanager create-secret \
    --name production/database \
    --description "Production database credentials" \
    --secret-string '{
        "username": "admin",
        "password": "SuperSecret123!",
        "host": "mydb.cluster-xyz.us-east-1.rds.amazonaws.com",
        "port": "3306",
        "dbname": "myapp"
    }'

# Retrieve a secret
aws secretsmanager get-secret-value \
    --secret-id production/database \
    --query SecretString --output text

# Update a secret
aws secretsmanager update-secret \
    --secret-id production/database \
    --secret-string '{"username":"admin","password":"NewPassword456!"}'

# Rotate secret automatically
aws secretsmanager rotate-secret \
    --secret-id production/database \
    --rotation-lambda-arn arn:aws:lambda:...:function:rotate-secret \
    --rotation-rules '{"AutomaticallyAfterDays": 30}'

# Delete secret
aws secretsmanager delete-secret \
    --secret-id production/database \
    --recovery-window-in-days 7





# The Ultimate DevOps & AWS Mastery Guide
## From Zero to Production — Every Concept, Every Command

---

# TABLE OF CONTENTS

```
PART 1:  FOUNDATIONS — Linux, Networking & Core Concepts
PART 2:  AWS CORE — EC2, VPC, Subnets, Security Groups
PART 3:  STORAGE & DATABASES — S3, EBS, EFS, RDS
PART 4:  NETWORKING DEEP-DIVE — Load Balancers, NAT, Route53
PART 5:  COMPUTE OPTIONS — On-Demand, Spot, Reserved, Fargate
PART 6:  CONTAINERS — Docker, ECR, ECS, Fargate
PART 7:  SERVERLESS — Lambda, API Gateway, EventBridge
PART 8:  AUTO SCALING — EC2, ECS, Policies
PART 9:  SECURITY — IAM, WAF, Shield, KMS, ACM
PART 10: CI/CD — CodePipeline, CodeBuild, CodeDeploy, Jenkins
PART 11: INFRASTRUCTURE AS CODE — CloudFormation, Terraform
PART 12: MONITORING — CloudWatch, CloudTrail, X-Ray
PART 13: ADVANCED — Port Forwarding, Bastion, SSM, Transit Gateway
```

---

---

# PART 1: FOUNDATIONS — Linux, Networking & Core Concepts

---

## 1.1 What is DevOps?

```
DevOps is NOT a tool. It's a CULTURE + SET OF PRACTICES that bridges
the gap between Development (Dev) and Operations (Ops) teams.

Traditional Model:
  Developer writes code → throws it over the wall → Ops deploys it
  Result: Blame games, slow releases, downtime

DevOps Model:
  Developer writes code → Automated testing → Automated deployment
  → Continuous monitoring → Feedback loop → Improvement
  Result: Fast releases, fewer bugs, happy teams
```

**The DevOps Lifecycle (∞ loop):**
```
    PLAN → CODE → BUILD → TEST → RELEASE → DEPLOY → OPERATE → MONITOR
      ↑                                                              |
      └──────────────────── FEEDBACK ←──────────────────────────────┘
```

---

## 1.2 Essential Linux Commands for DevOps

```bash
# ──────────── FILE SYSTEM ────────────
ls -la                          # List all files with permissions
cd /var/log                     # Change directory
pwd                             # Print working directory
mkdir -p /app/config            # Create nested directories
cp -r source/ dest/             # Copy recursively
mv oldname newname              # Move/rename
rm -rf /tmp/junk                # Remove recursively (CAREFUL!)
find / -name "*.log" -size +100M  # Find large log files

# ──────────── FILE VIEWING ────────────
cat /etc/os-release             # View file contents
less /var/log/syslog            # Paginated view
tail -f /var/log/syslog         # Follow log in real-time (CRITICAL for DevOps)
head -n 20 file.txt             # First 20 lines
grep -r "error" /var/log/       # Search recursively for "error"
grep -i "timeout" app.log       # Case-insensitive search

# ──────────── PERMISSIONS ────────────
chmod 755 script.sh             # rwxr-xr-x
chmod 600 private_key.pem       # rw------- (required for SSH keys)
chown ubuntu:ubuntu /app        # Change owner
# Permission numbers: r=4, w=2, x=1
# 755 = owner(7=rwx) group(5=rx) others(5=rx)

# ──────────── PROCESS MANAGEMENT ────────────
ps aux                          # All running processes
ps aux | grep nginx             # Find nginx processes
top                             # Real-time process monitor
htop                            # Better process monitor
kill -9 <PID>                   # Force kill process
systemctl start nginx           # Start a service
systemctl enable nginx          # Enable on boot
systemctl status nginx          # Check service status
journalctl -u nginx -f          # Follow service logs

# ──────────── NETWORKING ────────────
ifconfig                        # Network interfaces (older)
ip addr show                    # Network interfaces (modern)
curl -I https://google.com      # HTTP headers
wget https://example.com/file   # Download file
netstat -tulpn                  # Active ports and listeners
ss -tulpn                       # Modern alternative to netstat
ping 8.8.8.8                    # Test connectivity
traceroute google.com           # Trace network path
nslookup google.com             # DNS lookup
dig google.com                  # Detailed DNS lookup

# ──────────── DISK ────────────
df -h                           # Disk space (human readable)
du -sh /var/log/*               # Size of each item in directory
lsblk                          # List block devices
mount /dev/xvdf /data           # Mount a volume

# ──────────── USERS ────────────
whoami                          # Current user
sudo su -                       # Switch to root
useradd -m deploy               # Create user with home directory
passwd deploy                   # Set password
usermod -aG docker ubuntu       # Add user to docker group

# ──────────── PACKAGE MANAGEMENT ────────────
# Ubuntu/Debian:
apt update && apt upgrade -y
apt install nginx -y

# Amazon Linux/CentOS:
yum update -y
yum install httpd -y
```

---

## 1.3 Networking Fundamentals

```
┌─────────────────────────────────────────────┐
│           NETWORKING BASICS                  │
├─────────────────────────────────────────────┤
│                                             │
│  IP Address: Your device's address          │
│    - Public IP:  Reachable from internet    │
│    - Private IP: Internal network only      │
│                                             │
│  Private IP Ranges:                         │
│    10.0.0.0    – 10.255.255.255    (/8)     │
│    172.16.0.0  – 172.31.255.255   (/12)     │
│    192.168.0.0 – 192.168.255.255  (/16)     │
│                                             │
│  Subnet: A subdivision of a network        │
│    10.0.1.0/24 = 256 addresses              │
│    10.0.1.0/16 = 65,536 addresses           │
│                                             │
│  Port: A doorway on a machine              │
│    22   = SSH                               │
│    80   = HTTP                              │
│    443  = HTTPS                             │
│    3306 = MySQL                             │
│    5432 = PostgreSQL                        │
│    6379 = Redis                             │
│    8080 = Common app port                   │
│    3000 = Node.js default                   │
│                                             │
│  CIDR Notation:                             │
│    /32 = 1 IP (exact)                       │
│    /24 = 256 IPs                            │
│    /16 = 65,536 IPs                         │
│    /0  = ALL IPs (0.0.0.0/0 = Internet)     │
│                                             │
│  Protocol:                                  │
│    TCP = Reliable, ordered (HTTP, SSH)      │
│    UDP = Fast, no guarantee (DNS, Video)    │
│    ICMP = Ping                              │
│                                             │
└─────────────────────────────────────────────┘
```

---

---

# PART 2: AWS CORE — EC2, VPC, Subnets, Security Groups

---

## 2.1 What is AWS?

```
Amazon Web Services (AWS) is a cloud computing platform that provides
on-demand computing resources (servers, storage, databases, networking,
etc.) over the internet with pay-as-you-go pricing.

Instead of buying physical servers ($5,000+), you rent virtual ones
for cents per hour.

Key concepts:
  Region:           A geographical area (us-east-1, eu-west-1)
  Availability Zone: A data center within a region (us-east-1a, 1b, 1c)
  Edge Location:    CDN cache locations worldwide (CloudFront)
```

**Install AWS CLI:**
```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

# Configure credentials
aws configure
# AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

---

## 2.2 VPC — Virtual Private Cloud (Your Own Private Network)

```
A VPC is your ISOLATED section of the AWS cloud where you launch resources.
Think of it as your own private data center in the cloud.

┌─── AWS REGION (us-east-1) ───────────────────────────────────────────┐
│                                                                       │
│  ┌─── VPC (10.0.0.0/16) ──────────────────────────────────────────┐  │
│  │                                                                  │  │
│  │  ┌─── AZ: us-east-1a ──────┐  ┌─── AZ: us-east-1b ──────┐    │  │
│  │  │                          │  │                          │    │  │
│  │  │  ┌─ Public Subnet ──┐   │  │  ┌─ Public Subnet ──┐   │    │  │
│  │  │  │  10.0.1.0/24     │   │  │  │  10.0.2.0/24     │   │    │  │
│  │  │  │  [Web Server]    │   │  │  │  [Web Server]    │   │    │  │
│  │  │  │  [NAT Gateway]   │   │  │  │  [Load Balancer] │   │    │  │
│  │  │  └──────────────────┘   │  │  └──────────────────┘   │    │  │
│  │  │                          │  │                          │    │  │
│  │  │  ┌─ Private Subnet ─┐   │  │  ┌─ Private Subnet ─┐   │    │  │
│  │  │  │  10.0.3.0/24     │   │  │  │  10.0.4.0/24     │   │    │  │
│  │  │  │  [App Server]    │   │  │  │  [App Server]    │   │    │  │
│  │  │  │  [Database]      │   │  │  │  [Database]      │   │    │  │
│  │  │  └──────────────────┘   │  │  └──────────────────┘   │    │  │
│  │  │                          │  │                          │    │  │
│  │  └──────────────────────────┘  └──────────────────────────┘    │  │
│  │                                                                  │  │
│  │  [Internet Gateway]    ← Entry point from the internet          │  │
│  │  [Route Tables]        ← Traffic routing rules                  │  │
│  │  [Network ACLs]        ← Subnet-level firewall (stateless)     │  │
│  │  [Security Groups]     ← Instance-level firewall (stateful)    │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### Key VPC Components Explained

```
┌──────────────────┬──────────────────────────────────────────────────┐
│ Component        │ What It Does                                     │
├──────────────────┼──────────────────────────────────────────────────┤
│ VPC              │ Your private network (e.g., 10.0.0.0/16)         │
│ Subnet           │ A segment of the VPC in one AZ                   │
│ Public Subnet    │ Has route to Internet Gateway (internet access)  │
│ Private Subnet   │ NO direct internet access                        │
│ Internet Gateway │ Allows public subnet ↔ internet                  │
│ NAT Gateway      │ Allows private subnet → internet (outbound only) │
│ Route Table      │ Rules that determine where traffic goes           │
│ Security Group   │ Firewall at instance level (STATEFUL)            │
│ Network ACL      │ Firewall at subnet level (STATELESS)             │
│ Elastic IP       │ A static public IP address                       │
│ VPC Peering      │ Connect two VPCs privately                       │
│ VPC Endpoint     │ Private access to AWS services (no internet)     │
└──────────────────┴──────────────────────────────────────────────────┘
```

### Create a VPC — Step by Step (AWS CLI)

```bash
# ============================================================
# STEP 1: Create the VPC
# ============================================================
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyProductionVPC}]'
# Returns: vpc-0abc123def456

VPC_ID="vpc-0abc123def456"

# ============================================================
# STEP 2: Enable DNS hostnames (needed for public DNS names)
# ============================================================
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames '{"Value": true}'

# ============================================================
# STEP 3: Create an Internet Gateway
# ============================================================
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=MyIGW}]'
# Returns: igw-0abc123

IGW_ID="igw-0abc123"

# Attach it to your VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

# ============================================================
# STEP 4: Create Subnets
# ============================================================
# Public Subnet in AZ-a
aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet-1a}]'
# Returns: subnet-pub1a

# Public Subnet in AZ-b
aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PublicSubnet-1b}]'
# Returns: subnet-pub1b

# Private Subnet in AZ-a
aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnet-1a}]'
# Returns: subnet-priv1a

# Private Subnet in AZ-b
aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.4.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=PrivateSubnet-1b}]'
# Returns: subnet-priv1b

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute \
    --subnet-id subnet-pub1a \
    --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
    --subnet-id subnet-pub1b \
    --map-public-ip-on-launch

# ============================================================
# STEP 5: Create Route Tables
# ============================================================
# Public Route Table
aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRT}]'
# Returns: rtb-public

# Add route to Internet Gateway (THIS is what makes subnets "public")
aws ec2 create-route \
    --route-table-id rtb-public \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# Associate public subnets with public route table
aws ec2 associate-route-table \
    --route-table-id rtb-public \
    --subnet-id subnet-pub1a

aws ec2 associate-route-table \
    --route-table-id rtb-public \
    --subnet-id subnet-pub1b

# ============================================================
# STEP 6: Create NAT Gateway (for private subnet internet access)
# ============================================================
# First, allocate an Elastic IP
aws ec2 allocate-address --domain vpc
# Returns: eipalloc-0abc123

# Create NAT Gateway in a PUBLIC subnet
aws ec2 create-nat-gateway \
    --subnet-id subnet-pub1a \
    --allocation-id eipalloc-0abc123 \
    --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=MyNATGW}]'
# Returns: nat-0abc123

# Private Route Table
aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivateRT}]'
# Returns: rtb-private

# Route private traffic through NAT Gateway
aws ec2 create-route \
    --route-table-id rtb-private \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id nat-0abc123

# Associate private subnets
aws ec2 associate-route-table \
    --route-table-id rtb-private \
    --subnet-id subnet-priv1a

aws ec2 associate-route-table \
    --route-table-id rtb-private \
    --subnet-id subnet-priv1b
```

### Security Groups vs NACLs

```
┌─────────────────────┬──────────────────────┬──────────────────────┐
│ Feature             │ Security Group       │ Network ACL          │
├─────────────────────┼──────────────────────┼──────────────────────┤
│ Level               │ Instance (ENI)       │ Subnet               │
│ State               │ STATEFUL             │ STATELESS            │
│ Rules               │ Allow only           │ Allow AND Deny       │
│ Evaluation          │ All rules evaluated  │ Rules in order       │
│ Default             │ Deny all inbound     │ Allow all            │
│                     │ Allow all outbound   │                      │
│ Return traffic      │ Automatic            │ Must explicitly allow│
└─────────────────────┴──────────────────────┴──────────────────────┘

STATEFUL  = If you allow inbound on port 80, the RESPONSE is 
            automatically allowed out. You don't need an outbound rule.

STATELESS = You must explicitly create BOTH inbound AND outbound rules.
            If you allow inbound 80, you ALSO need outbound ephemeral ports.
```

```bash
# ──────────── SECURITY GROUPS ────────────

# Create Security Group for Web Servers
aws ec2 create-security-group \
    --group-name WebServerSG \
    --description "Allow HTTP, HTTPS, SSH" \
    --vpc-id $VPC_ID
# Returns: sg-web123

# Allow SSH from your IP only
aws ec2 authorize-security-group-ingress \
    --group-id sg-web123 \
    --protocol tcp \
    --port 22 \
    --cidr 203.0.113.50/32    # YOUR specific IP

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id sg-web123 \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# Allow HTTPS from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id sg-web123 \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# Create Security Group for Database (only accessible from web servers)
aws ec2 create-security-group \
    --group-name DatabaseSG \
    --description "Allow MySQL from WebServerSG only" \
    --vpc-id $VPC_ID
# Returns: sg-db123

# Allow MySQL ONLY from the Web Server security group
aws ec2 authorize-security-group-ingress \
    --group-id sg-db123 \
    --protocol tcp \
    --port 3306 \
    --source-group sg-web123    # ← Reference another SG!

# List security group rules
aws ec2 describe-security-groups --group-ids sg-web123
```

---

## 2.3 EC2 — Elastic Compute Cloud (Virtual Servers)

```
EC2 = Virtual machines (servers) running in AWS.
You choose the OS, CPU, RAM, storage, and networking.

Instance Types (think T-shirt sizes):
┌────────────┬────────┬────────┬──────────────────────────────────┐
│ Family     │ vCPU   │ RAM    │ Use Case                         │
├────────────┼────────┼────────┼──────────────────────────────────┤
│ t3.micro   │ 2      │ 1 GB   │ Testing, small apps (FREE TIER)  │
│ t3.medium  │ 2      │ 4 GB   │ Light web apps                   │
│ m5.large   │ 2      │ 8 GB   │ General purpose                  │
│ m5.xlarge  │ 4      │ 16 GB  │ Production apps                  │
│ c5.xlarge  │ 4      │ 8 GB   │ CPU-intensive (computation)      │
│ r5.xlarge  │ 4      │ 32 GB  │ Memory-intensive (databases)     │
│ g4dn.xlarge│ 4      │ 16 GB  │ GPU (ML, graphics)               │
│ i3.xlarge  │ 4      │ 30.5GB │ Storage-intensive (databases)    │
└────────────┴────────┴────────┴──────────────────────────────────┘

Naming convention: m5.xlarge
  m = family (general purpose)
  5 = generation
  xlarge = size
```

### Launch an EC2 Instance

```bash
# ============================================================
# STEP 1: Find the latest Amazon Linux 2023 AMI
# ============================================================
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023*-x86_64" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text
# Returns: ami-0abc123

# ============================================================
# STEP 2: Create a Key Pair (for SSH access)
# ============================================================
aws ec2 create-key-pair \
    --key-name MyKeyPair \
    --query 'KeyMaterial' \
    --output text > MyKeyPair.pem

# Set correct permissions (REQUIRED or SSH will refuse)
chmod 400 MyKeyPair.pem

# ============================================================
# STEP 3: Launch the Instance
# ============================================================
aws ec2 run-instances \
    --image-id ami-0abc123 \
    --instance-type t3.micro \
    --key-name MyKeyPair \
    --security-group-ids sg-web123 \
    --subnet-id subnet-pub1a \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer-1}]' \
    --user-data '#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html'
# Returns: i-0abc123def456

# ============================================================
# STEP 4: Check Instance Status
# ============================================================
aws ec2 describe-instances \
    --instance-ids i-0abc123def456 \
    --query 'Reservations[0].Instances[0].{State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}'

# ============================================================
# STEP 5: SSH into the Instance
# ============================================================
ssh -i MyKeyPair.pem ec2-user@<PUBLIC_IP>

# ============================================================
# COMMON EC2 OPERATIONS
# ============================================================
# Stop instance (you stop paying for compute, still pay for storage)
aws ec2 stop-instances --instance-ids i-0abc123def456

# Start instance
aws ec2 start-instances --instance-ids i-0abc123def456

# Reboot instance
aws ec2 reboot-instances --instance-ids i-0abc123def456

# Terminate instance (DELETE it permanently)
aws ec2 terminate-instances --instance-ids i-0abc123def456

# List all instances
aws ec2 describe-instances \
    --query 'Reservations[].Instances[].{ID:InstanceId,Name:Tags[?Key==`Name`].Value|[0],State:State.Name,Type:InstanceType,IP:PublicIpAddress}' \
    --output table

# Create an AMI (snapshot/image of your instance)
aws ec2 create-image \
    --instance-id i-0abc123def456 \
    --name "WebServer-Golden-Image-$(date +%Y%m%d)" \
    --no-reboot
```

### User Data Script (runs on first boot)

```bash
#!/bin/bash
# This script runs automatically when the instance first starts
# Runs as root

# Update system
yum update -y

# Install and start web server
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install useful tools
yum install -y git wget curl jq

# Configure the application
echo "<h1>Server: $(hostname)</h1><p>Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)</p>" > /var/www/html/index.html

# The metadata URL 169.254.169.254 is a special AWS endpoint
# available from within EC2 instances to get instance information
```

---

---

# PART 3: STORAGE & DATABASES

---

## 3.1 S3 — Simple Storage Service

```
S3 is OBJECT STORAGE — think of it as unlimited cloud storage.
NOT a file system. It stores objects (files) in buckets (containers).

Key concepts:
  Bucket:        A container for objects (globally unique name)
  Object:        A file + metadata (up to 5 TB)
  Key:           The "path" to the object (folder/file.txt)
  Region:        Where the bucket physically resides
  Versioning:    Keep multiple versions of an object

Storage Classes (cost vs. access speed):
┌────────────────────┬─────────────┬──────────────────────────┐
│ Class              │ Cost        │ Use Case                 │
├────────────────────┼─────────────┼──────────────────────────┤
│ S3 Standard        │ $$$$        │ Frequently accessed      │
│ S3 Intelligent     │ $$$         │ Unknown access patterns  │
│ S3 Standard-IA     │ $$          │ Infrequent access        │
│ S3 One Zone-IA     │ $           │ Infrequent, non-critical │
│ S3 Glacier Instant │ $           │ Archive, instant access  │
│ S3 Glacier Flexible│ ¢           │ Archive, mins-hours      │
│ S3 Glacier Deep    │ ¢¢          │ Archive, 12+ hours       │
└────────────────────┴─────────────┴──────────────────────────┘
```

```bash
# ============================================================
# S3 COMMANDS
# ============================================================

# Create a bucket
aws s3 mb s3://my-company-app-bucket-2024

# Upload a file
aws s3 cp myfile.txt s3://my-company-app-bucket-2024/

# Upload a directory (recursively)
aws s3 cp ./my-app/ s3://my-company-app-bucket-2024/my-app/ --recursive

# Sync a directory (only uploads changed files)
aws s3 sync ./build/ s3://my-company-app-bucket-2024/

# Download a file
aws s3 cp s3://my-company-app-bucket-2024/myfile.txt ./

# List buckets
aws s3 ls

# List objects in a bucket
aws s3 ls s3://my-company-app-bucket-2024/
aws s3 ls s3://my-company-app-bucket-2024/ --recursive --human-readable

# Delete a file
aws s3 rm s3://my-company-app-bucket-2024/myfile.txt

# Delete all objects in a bucket
aws s3 rm s3://my-company-app-bucket-2024/ --recursive

# Delete a bucket (must be empty first)
aws s3 rb s3://my-company-app-bucket-2024

# Delete a bucket and all contents
aws s3 rb s3://my-company-app-bucket-2024 --force

# Generate a presigned URL (temporary access to private object)
aws s3 presign s3://my-company-app-bucket-2024/secret-report.pdf --expires-in 3600
# Returns a URL that works for 1 hour (3600 seconds)

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket my-company-app-bucket-2024 \
    --versioning-configuration Status=Enabled

# Host a static website
aws s3 website s3://my-company-app-bucket-2024/ \
    --index-document index.html \
    --error-document error.html

# Bucket policy (make objects public - for static website)
aws s3api put-bucket-policy \
    --bucket my-company-app-bucket-2024 \
    --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-company-app-bucket-2024/*"
    }
  ]
}'

# Lifecycle rule (move to Glacier after 90 days, delete after 365)
aws s3api put-bucket-lifecycle-configuration \
    --bucket my-company-app-bucket-2024 \
    --lifecycle-configuration '{
  "Rules": [
    {
      "ID": "ArchiveAndDelete",
      "Status": "Enabled",
      "Filter": {"Prefix": "logs/"},
      "Transitions": [
        {"Days": 90, "StorageClass": "GLACIER"}
      ],
      "Expiration": {"Days": 365}
    }
  ]
}'
```

---

## 3.2 EBS — Elastic Block Store

```
EBS = Virtual hard drives for EC2 instances.
Like plugging a hard drive into your virtual server.

Types:
┌──────────────────┬──────────┬─────────┬────────────────────────┐
│ Type             │ IOPS     │ Cost    │ Use Case               │
├──────────────────┼──────────┼─────────┼────────────────────────┤
│ gp3 (General)    │ 3,000-16K│ $$      │ Boot volumes, dev/test │
│ gp2 (General)    │ 100-16K  │ $$      │ Legacy general purpose │
│ io2 (Provisioned)│ up to 64K│ $$$$    │ Databases (high IOPS)  │
│ st1 (Throughput) │ 500      │ $       │ Big data, data lakes   │
│ sc1 (Cold)       │ 250      │ ¢       │ Infrequently accessed  │
└──────────────────┴──────────┴─────────┴────────────────────────┘
```

```bash
# Create a volume
aws ec2 create-volume \
    --volume-type gp3 \
    --size 100 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=DataVolume}]'
# Returns: vol-0abc123

# Attach to an instance
aws ec2 attach-volume \
    --volume-id vol-0abc123 \
    --instance-id i-0abc123def456 \
    --device /dev/xvdf

# SSH into instance and use the volume
ssh -i MyKeyPair.pem ec2-user@<IP>
# Format the volume (ONLY first time!)
sudo mkfs -t xfs /dev/xvdf
# Create mount point
sudo mkdir /data
# Mount it
sudo mount /dev/xvdf /data
# Make it persist across reboots (add to fstab)
echo '/dev/xvdf /data xfs defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Create a snapshot (backup)
aws ec2 create-snapshot \
    --volume-id vol-0abc123 \
    --description "Daily backup $(date +%Y-%m-%d)"
```

---

## 3.3 EFS — Elastic File System

```
EFS = Shared file system that multiple EC2 instances can access simultaneously.
Like a network drive. NFS protocol.

EBS vs EFS:
  EBS: One volume → one instance (like a USB drive)
  EFS: One filesystem → MANY instances (like a shared network drive)
```

```bash
# Create EFS filesystem
aws efs create-file-system \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --tags Key=Name,Value=SharedFS
# Returns: fs-0abc123

# Create mount targets (one per subnet)
aws efs create-mount-target \
    --file-system-id fs-0abc123 \
    --subnet-id subnet-priv1a \
    --security-groups sg-efs123

# Mount on EC2 instance
sudo yum install -y amazon-efs-utils
sudo mkdir /shared
sudo mount -t efs fs-0abc123:/ /shared
```

---

---

# PART 4: NETWORKING DEEP-DIVE — Load Balancers, NAT, Route53

---

## 4.1 NAT Gateway — Outbound Internet for Private Subnets

```
Problem: Your private subnet (database, app servers) has NO internet.
         But they need to download updates, patches, talk to APIs.

Solution: NAT Gateway sits in PUBLIC subnet, forwards private→internet.
          Internet CANNOT initiate connections TO private instances.

    ┌─────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
    │Private  │────→│ NAT Gateway  │────→│ Internet GW  │────→│ Internet │
    │Instance │     │(Public Subnet│     │              │     │          │
    │         │     │ has Elastic IP│     │              │     │          │
    └─────────┘     └──────────────┘     └──────────────┘     └──────────┘
         ↑
    CANNOT receive
    inbound from internet

Cost: ~$0.045/hour + $0.045/GB processed
      ≈ $32/month just for running + data charges
      
Alternative (cheaper): NAT Instance (t3.micro EC2 with NAT config)
```

```bash
# Already covered in VPC section, but here's a NAT Instance alternative:

# Launch a NAT instance (cheaper option)
aws ec2 run-instances \
    --image-id ami-vpc-nat-xxxx \
    --instance-type t3.micro \
    --key-name MyKeyPair \
    --security-group-ids sg-nat123 \
    --subnet-id subnet-pub1a

# CRITICAL: Disable source/dest check for NAT to work
aws ec2 modify-instance-attribute \
    --instance-id i-nat123 \
    --no-source-dest-check

# Update private route table to use NAT instance
aws ec2 create-route \
    --route-table-id rtb-private \
    --destination-cidr-block 0.0.0.0/0 \
    --instance-id i-nat123
```

---

## 4.2 Elastic Load Balancer (ELB) — Distributing Traffic

```
A Load Balancer distributes incoming traffic across multiple targets
(EC2 instances, containers, IPs) to ensure:
  ✅ High availability (if one server dies, traffic goes to others)
  ✅ Scalability (add more servers behind the load balancer)
  ✅ Health checking (automatically removes unhealthy targets)

THREE types of Load Balancers in AWS:

┌─────────────────┬────────────┬───────────────────────────────────────┐
│ Type            │ Layer      │ Use Case                              │
├─────────────────┼────────────┼───────────────────────────────────────┤
│ ALB             │ Layer 7    │ HTTP/HTTPS, path-based routing,       │
│ (Application)   │ (HTTP)     │ host-based routing, microservices     │
│                 │            │ WebSocket, gRPC                       │
├─────────────────┼────────────┼───────────────────────────────────────┤
│ NLB             │ Layer 4    │ TCP/UDP, ultra-high performance,      │
│ (Network)       │ (TCP/UDP)  │ static IP, gaming, IoT               │
│                 │            │ Millions of requests/sec              │
├─────────────────┼────────────┼───────────────────────────────────────┤
│ GLB             │ Layer 3    │ Third-party firewalls, IDS/IPS,       │
│ (Gateway)       │ (Network)  │ deep packet inspection                │
└─────────────────┴────────────┴───────────────────────────────────────┘

Architecture:
                    ┌──────────────────┐
                    │    INTERNET      │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  ALB (Port 443)  │  ← SSL/TLS termination
                    │  my-app.com      │  ← Domain name
                    └─┬──────┬──────┬──┘
                      │      │      │     ← Health checks every 30s
              ┌───────▼┐ ┌──▼────┐ ┌▼───────┐
              │ EC2-1  │ │ EC2-2 │ │ EC2-3  │  Target Group
              │ (1a)   │ │ (1b)  │ │ (1c)   │
              └────────┘ └───────┘ └────────┘

ALB Routing Examples:
  my-app.com/api/*      → Target Group: API Servers
  my-app.com/images/*   → Target Group: Image Servers
  my-app.com/*          → Target Group: Web Servers
  api.my-app.com/*      → Target Group: API Servers (host-based)
```

### Create an Application Load Balancer (ALB)

```bash
# ============================================================
# STEP 1: Create the ALB
# ============================================================
aws elbv2 create-load-balancer \
    --name my-web-alb \
    --subnets subnet-pub1a subnet-pub1b \
    --security-groups sg-alb123 \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4
# Returns: arn:aws:elasticloadbalancing:...:loadbalancer/app/my-web-alb/abc123
# Also returns: DNSName: my-web-alb-123456.us-east-1.elb.amazonaws.com

ALB_ARN="arn:aws:elasticloadbalancing:...:loadbalancer/app/my-web-alb/abc123"

# ============================================================
# STEP 2: Create a Target Group (where traffic goes)
# ============================================================
aws elbv2 create-target-group \
    --name my-web-targets \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --health-check-protocol HTTP \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --target-type instance
# Returns: arn:aws:elasticloadbalancing:...:targetgroup/my-web-targets/abc123

TG_ARN="arn:aws:elasticloadbalancing:...:targetgroup/my-web-targets/abc123"

# ============================================================
# STEP 3: Register Targets (add EC2 instances)
# ============================================================
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=i-instance1 Id=i-instance2 Id=i-instance3

# ============================================================
# STEP 4: Create Listener (what port the ALB listens on)
# ============================================================
# HTTP Listener (port 80) - redirect to HTTPS
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=redirect,RedirectConfig='{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}'

# HTTPS Listener (port 443)
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTPS \
    --port 443 \
    --ssl-policy ELBSecurityPolicy-TLS13-1-2-2021-06 \
    --certificates CertificateArn=arn:aws:acm:...:certificate/abc123 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN

# Returns: ListenerArn
LISTENER_ARN="arn:aws:elasticloadbalancing:...:listener/app/my-web-alb/abc/def"

# ============================================================
# STEP 5: Add Path-Based Routing Rules
# ============================================================
# Create separate target group for API
aws elbv2 create-target-group \
    --name my-api-targets \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --health-check-path /api/health \
    --target-type instance

API_TG_ARN="arn:..."

# Add rule: /api/* → API target group
aws elbv2 create-rule \
    --listener-arn $LISTENER_ARN \
    --priority 10 \
    --conditions Field=path-pattern,Values='/api/*' \
    --actions Type=forward,TargetGroupArn=$API_TG_ARN

# ============================================================
# USEFUL COMMANDS
# ============================================================
# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN

# List load balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output table

# Deregister a target (for maintenance)
aws elbv2 deregister-targets \
    --target-group-arn $TG_ARN \
    --targets Id=i-instance1
```

### Security Group for ALB

```bash
# ALB Security Group - accept traffic from the internet
aws ec2 create-security-group \
    --group-name ALB-SG \
    --description "ALB Security Group" \
    --vpc-id $VPC_ID

aws ec2 authorize-security-group-ingress --group-id sg-alb123 --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-alb123 --protocol tcp --port 443 --cidr 0.0.0.0/0

# EC2 Security Group - ONLY accept traffic from the ALB
aws ec2 authorize-security-group-ingress \
    --group-id sg-web123 \
    --protocol tcp \
    --port 80 \
    --source-group sg-alb123    # ← Only ALB can reach EC2!
```

---

## 4.3 Route 53 — DNS Service

```
Route 53 is AWS's DNS (Domain Name System) service.
It translates domain names (google.com) to IP addresses (142.250.80.46).

Record Types:
  A Record:     domain.com → 1.2.3.4 (IPv4)
  AAAA Record:  domain.com → 2001:db8::1 (IPv6)
  CNAME Record: www.domain.com → domain.com (alias to another domain)
  ALIAS Record: domain.com → ALB DNS name (AWS-specific, works at zone apex)
  MX Record:    domain.com → mail server
  TXT Record:   domain.com → text (verification, SPF)

Routing Policies:
  Simple:        One record, one value
  Weighted:      Split traffic by percentage (80% v1, 20% v2)
  Latency:       Route to lowest latency region
  Failover:      Primary + secondary (disaster recovery)
  Geolocation:   Route by user's location
  Multi-value:   Return multiple healthy IPs
```

```bash
# Create a hosted zone
aws route53 create-hosted-zone \
    --name myapp.com \
    --caller-reference "$(date +%s)"

# Create an A record pointing to ALB (ALIAS)
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "myapp.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z35SXDOTRQ7X7K",
          "DNSName": "my-web-alb-123456.us-east-1.elb.amazonaws.com",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}'

# Create a simple A record
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890 \
    --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.myapp.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "1.2.3.4"}]
      }
    }
  ]
}'

# List all records
aws route53 list-resource-record-sets --hosted-zone-id Z1234567890
```

---

---

# PART 5: COMPUTE OPTIONS — Pricing Models

---

## 5.1 EC2 Pricing Models Explained

```
┌──────────────────────────────────────────────────────────────────────┐
│                    EC2 PRICING MODELS                                │
├──────────────┬───────────┬───────────────────────────────────────────┤
│ Model        │ Savings   │ Description                               │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ ON-DEMAND    │ 0%        │ Pay per hour/second. No commitment.       │
│              │           │ Start/stop anytime.                       │
│              │           │ Best for: Short-term, unpredictable       │
│              │           │ workloads, testing, development.          │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ RESERVED     │ Up to 72% │ Commit to 1 or 3 years.                  │
│ INSTANCES    │           │ Pay upfront (all/partial/none).           │
│              │           │ Best for: Steady-state applications       │
│              │           │ (databases, core web servers).            │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ SPOT         │ Up to 90% │ Bid on spare AWS capacity.               │
│ INSTANCES    │           │ Can be INTERRUPTED with 2-min warning.    │
│              │           │ Best for: Batch processing, CI/CD,        │
│              │           │ data analysis, stateless workloads.      │
│              │           │ NEVER for databases or stateful apps.    │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ SAVINGS      │ Up to 72% │ Commit to $/hour for 1 or 3 years.       │
│ PLANS        │           │ More flexible than Reserved (any          │
│              │           │ instance family, region, OS).             │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ DEDICATED    │ Premium   │ Physical server dedicated to you.         │
│ HOSTS        │           │ For licensing or compliance needs.        │
├──────────────┼───────────┼───────────────────────────────────────────┤
│ DEDICATED    │ Premium   │ Instance on dedicated hardware.           │
│ INSTANCES    │           │ Less control than Dedicated Host.         │
└──────────────┴───────────┴───────────────────────────────────────────┘

Example Pricing (us-east-1, m5.xlarge):
  On-Demand:     $0.192/hour  = ~$140/month
  Reserved (1yr): $0.120/hour = ~$87/month   (37% savings)
  Reserved (3yr): $0.079/hour = ~$57/month   (59% savings)
  Spot:          $0.040/hour  = ~$29/month   (79% savings)
```

### Spot Instances — Deep Dive

```bash
# ============================================================
# REQUEST A SPOT INSTANCE
# ============================================================
aws ec2 request-spot-instances \
    --spot-price "0.05" \
    --instance-count 1 \
    --type "one-time" \
    --launch-specification '{
        "ImageId": "ami-0abc123",
        "InstanceType": "m5.xlarge",
        "KeyName": "MyKeyPair",
        "SecurityGroupIds": ["sg-web123"],
        "SubnetId": "subnet-pub1a"
    }'

# BETTER: Use Spot Fleet (mix of instance types for better availability)
aws ec2 request-spot-fleet \
    --spot-fleet-request-config '{
  "IamFleetRole": "arn:aws:iam::role/aws-ec2-spot-fleet-role",
  "TargetCapacity": 5,
  "SpotPrice": "0.05",
  "AllocationStrategy": "diversified",
  "LaunchSpecifications": [
    {
      "ImageId": "ami-0abc123",
      "InstanceType": "m5.xlarge",
      "SubnetId": "subnet-pub1a"
    },
    {
      "ImageId": "ami-0abc123",
      "InstanceType": "m5.large",
      "SubnetId": "subnet-pub1b"
    },
    {
      "ImageId": "ami-0abc123",
      "InstanceType": "m4.xlarge",
      "SubnetId": "subnet-pub1a"
    }
  ]
}'

# Check current spot prices
aws ec2 describe-spot-price-history \
    --instance-types m5.xlarge m5.large \
    --product-descriptions "Linux/UNIX" \
    --start-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --query 'SpotPriceHistory[].{Type:InstanceType,AZ:AvailabilityZone,Price:SpotPrice}' \
    --output table

# View spot instance requests
aws ec2 describe-spot-instance-requests

# Cancel a spot request (does NOT terminate the instance)
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids sir-abc123

# Handle spot interruption (in your User Data script)
#!/bin/bash
# Check for spot interruption notice
while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        http://169.254.169.254/latest/meta-data/spot/termination-time)
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "SPOT INTERRUPTION NOTICE RECEIVED!"
        # Gracefully shut down your app
        # Drain connections
        # Save state
        # Deregister from load balancer
        systemctl stop myapp
        break
    fi
    sleep 5
done
```

---

---

# PART 6: CONTAINERS — Docker, ECR, ECS, Fargate

---

## 6.1 Docker Fundamentals

```
WHAT IS DOCKER?
Docker packages your application and ALL its dependencies into a
standardized unit called a CONTAINER.

"It works on my machine" → "It works in ANY machine" ✅

Container vs Virtual Machine:
┌────────────────────────┐  ┌────────────────────────┐
│     Virtual Machine    │  │      Container         │
├────────────────────────┤  ├────────────────────────┤
│   App A  │  App B      │  │   App A  │  App B      │
│   Libs   │  Libs       │  │   Libs   │  Libs       │
│   Guest OS│  Guest OS   │  │   Docker Engine        │
│   Hypervisor           │  │   Host OS              │
│   Host OS              │  │   Hardware             │
│   Hardware             │  │                        │
└────────────────────────┘  └────────────────────────┘
  Heavy (GBs), slow start     Light (MBs), instant start
  Minutes to boot              Seconds to boot
```

```bash
# ============================================================
# DOCKER INSTALLATION
# ============================================================
# Amazon Linux 2023 / Amazon Linux 2
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Log out and log back in for group to take effect

# Ubuntu
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Verify
docker --version
docker info

# ============================================================
# DOCKER BASICS
# ============================================================

# Run your first container
docker run hello-world

# Run Nginx web server
docker run -d -p 80:80 --name my-nginx nginx
# -d = detached (background)
# -p 80:80 = map host port 80 → container port 80
# --name = give it a name

# List running containers
docker ps

# List ALL containers (including stopped)
docker ps -a

# Stop a container
docker stop my-nginx

# Start a stopped container
docker start my-nginx

# Remove a container
docker rm my-nginx

# Remove a running container (force)
docker rm -f my-nginx

# View logs
docker logs my-nginx
docker logs -f my-nginx        # Follow logs (real-time)

# Execute command inside container
docker exec -it my-nginx bash  # Get a shell inside the container
docker exec my-nginx ls /etc/nginx/

# View resource usage
docker stats

# List images
docker images

# Remove an image
docker rmi nginx

# Pull an image
docker pull ubuntu:22.04

# Clean up everything
docker system prune -a         # Remove all stopped containers, unused images, etc.
```

### Creating a Dockerfile

```dockerfile
# ============================================================
# Dockerfile for a Node.js application
# ============================================================

# Stage 1: Build
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files first (for better caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production (smaller image)
FROM node:18-alpine AS production

# Create non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only what we need from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start command
CMD ["node", "dist/server.js"]
```

```bash
# Build the image
docker build -t my-node-app:1.0 .

# Build with no cache (fresh build)
docker build --no-cache -t my-node-app:1.0 .

# Run the application
docker run -d \
    -p 3000:3000 \
    --name my-app \
    -e NODE_ENV=production \
    -e DB_HOST=mydb.abc123.us-east-1.rds.amazonaws.com \
    --restart unless-stopped \
    my-node-app:1.0

# View image layers (good for optimization)
docker history my-node-app:1.0
```

### Docker Compose (Multi-Container Apps)

```yaml
# docker-compose.yml
version: '3.8'

services:
  # Web Application
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_PORT=5432
      - REDIS_HOST=redis
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped
    networks:
      - app-network

  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=secretpassword
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U admin -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - app-network

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - web
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f web

# Stop all services
docker compose down

# Stop and remove volumes (DELETE DATA!)
docker compose down -v

# Rebuild and restart
docker compose up -d --build

# Scale a service
docker compose up -d --scale web=3
```

---

## 6.2 ECR — Elastic Container Registry (Docker Image Storage)

```
ECR is AWS's private Docker image registry.
Like Docker Hub, but private and integrated with AWS.

Your CI/CD pipeline builds images → pushes to ECR → ECS/EKS pulls from ECR

┌──────────┐     ┌─────────┐     ┌─────────────┐
│ Developer │────→│ ECR     │────→│ ECS/EKS     │
│ Build     │push │ Registry│pull │ Deployment  │
└──────────┘     └─────────┘     └─────────────┘
```

```bash
# ============================================================
# CREATE ECR REPOSITORY
# ============================================================
aws ecr create-repository \
    --repository-name my-app \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
# Returns: repositoryUri: 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app

# ============================================================
# LOGIN TO ECR (authenticate Docker)
# ============================================================
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com

# ============================================================
# BUILD, TAG, AND PUSH IMAGE
# ============================================================
# Build the image
docker build -t my-app:latest .

# Tag for ECR
docker tag my-app:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker tag my-app:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:v1.0.0

# ============================================================
# MANAGE IMAGES
# ============================================================
# List images
aws ecr list-images --repository-name my-app

# Describe images (get details)
aws ecr describe-images \
    --repository-name my-app \
    --query 'imageDetails[*].{Tag:imageTags[0],Size:imageSizeInBytes,Pushed:imagePushedAt}' \
    --output table

# Delete an image
aws ecr batch-delete-image \
    --repository-name my-app \
    --image-ids imageTag=v1.0.0

# ============================================================
# LIFECYCLE POLICY (auto-cleanup old images)
# ============================================================
aws ecr put-lifecycle-policy \
    --repository-name my-app \
    --lifecycle-policy-text '{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}'

# Get scan results (vulnerabilities)
aws ecr describe-image-scan-findings \
    --repository-name my-app \
    --image-id imageTag=latest
```

---

## 6.3 ECS — Elastic Container Service

```
ECS is AWS's container orchestration service.
It runs and manages Docker containers at scale.

Key Concepts:
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  CLUSTER: A logical grouping of services and tasks               │
│    │                                                             │
│    ├── SERVICE: Maintains desired count of tasks                 │
│    │     │                                                       │
│    │     ├── TASK: A running instance of a task definition       │
│    │     │     │                                                  │
│    │     │     └── CONTAINER(s): Docker containers inside task   │
│    │     │                                                       │
│    │     └── TASK DEFINITION: Blueprint for your task            │
│    │           (like a docker-compose.yml)                       │
│    │                                                             │
│    └── SERVICE: Another service...                              │
│                                                                  │
│  LAUNCH TYPES:                                                   │
│    EC2:     You manage the servers (EC2 instances)               │
│    FARGATE: AWS manages the servers (SERVERLESS containers)      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

EC2 Launch Type:
  ✅ More control over infrastructure
  ✅ Can use Spot/Reserved instances
  ❌ You manage OS patching, scaling of EC2 instances
  
Fargate Launch Type:
  ✅ No servers to manage (truly serverless)
  ✅ Pay per vCPU/memory per second
  ✅ Automatic scaling
  ❌ More expensive per unit
  ❌ Less control
```

### ECS Architecture Diagram

```
                    ┌──────────────────┐
                    │    INTERNET      │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │       ALB        │
                    └──┬───────────┬───┘
                       │           │
         ┌─────────────▼──┐  ┌────▼──────────────┐
         │  ECS CLUSTER   │  │                    │
         │                │  │                    │
         │ ┌─ Fargate ──┐ │  │ ┌─ Fargate ──┐    │
         │ │ Task 1      │ │  │ │ Task 2      │   │
         │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │   │
         │ │ │Container│ │ │  │ │ │Container│ │   │
         │ │ │ (app)   │ │ │  │ │ │ (app)   │ │   │
         │ │ └─────────┘ │ │  │ │ └─────────┘ │   │
         │ │ ┌─────────┐ │ │  │ │ ┌─────────┐ │   │
         │ │ │Sidecar  │ │ │  │ │ │Sidecar  │ │   │
         │ │ │(logging)│ │ │  │ │ │(logging)│ │   │
         │ │ └─────────┘ │ │  │ │ └─────────┘ │   │
         │ └─────────────┘ │  │ └─────────────┘   │
         │   AZ: 1a        │  │   AZ: 1b          │
         └─────────────────┘  └───────────────────┘
```

### Create ECS Cluster with Fargate

```bash
# ============================================================
# STEP 1: Create ECS Cluster
# ============================================================
aws ecs create-cluster \
    --cluster-name production-cluster \
    --capacity-providers FARGATE FARGATE_SPOT \
    --default-capacity-provider-strategy \
        capacityProvider=FARGATE,weight=1,base=1 \
        capacityProvider=FARGATE_SPOT,weight=4

# ============================================================
# STEP 2: Create IAM Roles
# ============================================================
# Task Execution Role (allows ECS to pull images from ECR, write logs)
# Create trust policy
cat > ecs-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://ecs-trust-policy.json

aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Task Role (permissions YOUR application needs - e.g., access S3)
aws iam create-role \
    --role-name ecsTaskRole \
    --assume-role-policy-document file://ecs-trust-policy.json

aws iam attach-role-policy \
    --role-name ecsTaskRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# ============================================================
# STEP 3: Create Task Definition
# ============================================================
cat > task-definition.json << 'EOF'
{
  "family": "my-web-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::123456789:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "web-app",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "NODE_ENV", "value": "production"},
        {"name": "PORT", "value": "3000"}
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-web-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-definition.json

# ============================================================
# STEP 4: Create CloudWatch Log Group
# ============================================================
aws logs create-log-group --log-group-name /ecs/my-web-app

# ============================================================
# STEP 5: Create the ECS Service
# ============================================================
aws ecs create-service \
    --cluster production-cluster \
    --service-name my-web-service \
    --task-definition my-web-app:1 \
    --desired-count 3 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration '{
        "awsvpcConfiguration": {
            "subnets": ["subnet-priv1a", "subnet-priv1b"],
            "securityGroups": ["sg-ecs123"],
            "assignPublicIp": "DISABLED"
        }
    }' \
    --load-balancers '[
        {
            "targetGroupArn": "arn:aws:elasticloadbalancing:...:targetgroup/my-web-targets/abc123",
            "containerName": "web-app",
            "containerPort": 3000
        }
    ]' \
    --deployment-configuration '{
        "maximumPercent": 200,
        "minimumHealthyPercent": 100,
        "deploymentCircuitBreaker": {
            "enable": true,
            "rollback": true
        }
    }' \
    --enable-execute-command

# ============================================================
# USEFUL ECS COMMANDS
# ============================================================

# List clusters
aws ecs list-clusters

# List services in a cluster
aws ecs list-services --cluster production-cluster

# Describe service (current status, events)
aws ecs describe-services \
    --cluster production-cluster \
    --services my-web-service \
    --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Events:events[:5]}'

# List tasks
aws ecs list-tasks --cluster production-cluster --service-name my-web-service

# Describe a task (see container details)
aws ecs describe-tasks \
    --cluster production-cluster \
    --tasks arn:aws:ecs:...:task/production-cluster/abc123

# Update service (deploy new version)
# First, update task definition with new image, then:
aws ecs update-service \
    --cluster production-cluster \
    --service my-web-service \
    --task-definition my-web-app:2 \
    --force-new-deployment

# Scale service
aws ecs update-service \
    --cluster production-cluster \
    --service my-web-service \
    --desired-count 5

# Execute command in running container (like docker exec)
aws ecs execute-command \
    --cluster production-cluster \
    --task arn:aws:ecs:...:task/abc123 \
    --container web-app \
    --interactive \
    --command "/bin/sh"

# View logs
aws logs tail /ecs/my-web-app --follow

# Stop a task (ECS will start a new one if service is running)
aws ecs stop-task \
    --cluster production-cluster \
    --task arn:aws:ecs:...:task/abc123 \
    --reason "Debugging"

# Delete service (set desired to 0 first)
aws ecs update-service --cluster production-cluster --service my-web-service --desired-count 0
aws ecs delete-service --cluster production-cluster --service my-web-service

# Delete cluster
aws ecs delete-cluster --cluster production-cluster
```

---

## 6.4 Fargate — Serverless Containers

```
Fargate = Run containers WITHOUT managing servers.
You just define CPU/Memory and Fargate handles the rest.

EC2 Launch Type vs Fargate:
┌──────────────────────────┬──────────────────────────────────┐
│ EC2 Launch Type          │ Fargate                          │
├──────────────────────────┼──────────────────────────────────┤
│ You provision EC2 fleet  │ No EC2 instances to manage       │
│ You patch/update OS      │ AWS manages infrastructure       │
│ You scale EC2 instances  │ Auto-scales compute              │
│ Can use Spot/Reserved    │ Fargate/Fargate Spot pricing     │
│ More control             │ Less control, more convenience   │
│ Generally cheaper        │ Generally more expensive/unit    │
│ at scale                 │ but no operational overhead      │
└──────────────────────────┴──────────────────────────────────┘

Fargate Pricing (us-east-1):
  vCPU:   $0.04048 per vCPU per hour
  Memory: $0.004445 per GB per hour
  
  Example: 0.5 vCPU, 1GB RAM task running 24/7:
    vCPU:   0.5 × $0.04048 × 730 hours = $14.78/month
    Memory: 1 × $0.004445 × 730 hours  = $3.24/month
    Total: ~$18/month per task

Fargate Spot: Up to 70% discount (can be interrupted)
```

---

---

# PART 7: SERVERLESS — Lambda, API Gateway, EventBridge

---

## 7.1 AWS Lambda — Serverless Compute

```
Lambda runs your code WITHOUT provisioning servers.
You pay ONLY when your code runs (per millisecond).

How it works:
  1. You upload your code (function)
  2. An event triggers it (HTTP request, S3 upload, schedule, etc.)
  3. Lambda runs your code in a container
  4. You're billed for the execution time

Limits:
  - Timeout: Max 15 minutes
  - Memory: 128 MB to 10,240 MB
  - Package size: 50 MB zipped, 250 MB unzipped
  - /tmp storage: 512 MB (configurable to 10 GB)
  - Concurrent executions: 1,000 (default, can increase)

Use Cases:
  ✅ API backends
  ✅ File processing (image resize on S3 upload)
  ✅ Cron jobs (scheduled tasks)
  ✅ Event processing (SQS, SNS, Kinesis)
  ✅ Data transformation
  ❌ Long-running processes (>15 min)
  ❌ Stateful applications
```

```bash
# ============================================================
# CREATE A LAMBDA FUNCTION
# ============================================================

# Create the function code
cat > index.js << 'EOF'
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    const name = event.queryStringParameters?.name || 'World';
    
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
            message: `Hello, ${name}!`,
            timestamp: new Date().toISOString(),
            requestId: event.requestContext?.requestId
        })
    };
};
EOF

# Zip it
zip function.zip index.js

# Create IAM role for Lambda
cat > lambda-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
    --role-name lambda-execution-role \
    --assume-role-policy-document file://lambda-trust-policy.json

aws iam attach-role-policy \
    --role-name lambda-execution-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create the function
aws lambda create-function \
    --function-name my-hello-function \
    --runtime nodejs18.x \
    --role arn:aws:iam::123456789:role/lambda-execution-role \
    --handler index.handler \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --memory-size 256 \
    --environment Variables='{STAGE=production,DB_HOST=mydb.example.com}'

# ============================================================
# INVOKE THE FUNCTION
# ============================================================
# Direct invoke
aws lambda invoke \
    --function-name my-hello-function \
    --payload '{"queryStringParameters": {"name": "DevOps Engineer"}}' \
    --cli-binary-format raw-in-base64-out \
    response.json

cat response.json

# ============================================================
# UPDATE FUNCTION CODE
# ============================================================
zip function.zip index.js
aws lambda update-function-code \
    --function-name my-hello-function \
    --zip-file fileb://function.zip

# Update configuration
aws lambda update-function-configuration \
    --function-name my-hello-function \
    --timeout 60 \
    --memory-size 512 \
    --environment Variables='{STAGE=production,DB_HOST=newdb.example.com}'

# ============================================================
# LAMBDA VERSIONS AND ALIASES
# ============================================================
# Publish a version (immutable snapshot)
aws lambda publish-version \
    --function-name my-hello-function \
    --description "v1.0.0 - initial release"

# Create alias (pointer to a version)
aws lambda create-alias \
    --function-name my-hello-function \
    --name prod \
    --function-version 1

# Weighted alias (canary deployment: 90% v1, 10% v2)
aws lambda update-alias \
    --function-name my-hello-function \
    --name prod \
    --function-version 2 \
    --routing-config AdditionalVersionWeights={"1"=0.9}

# ============================================================
# USEFUL COMMANDS
# ============================================================
# List functions
aws lambda list-functions --query 'Functions[].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}' --output table

# View function logs
aws logs tail /aws/lambda/my-hello-function --follow

# Get function details
aws lambda get-function --function-name my-hello-function

# Delete function
aws lambda delete-function --function-name my-hello-function

# Add event source (trigger from SQS)
aws lambda create-event-source-mapping \
    --function-name my-hello-function \
    --event-source-arn arn:aws:sqs:us-east-1:123456789:my-queue \
    --batch-size 10

# Add S3 trigger (when file uploaded to S3)
aws s3api put-bucket-notification-configuration \
    --bucket my-bucket \
    --notification-configuration '{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "arn:aws:lambda:us-east-1:123456789:function:my-hello-function",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [
            {"Name": "prefix", "Value": "uploads/"},
            {"Name": "suffix", "Value": ".jpg"}
          ]
        }
      }
    }
  ]
}'
```

---

## 7.2 API Gateway

```
API Gateway creates RESTful APIs or WebSocket APIs that serve as
the "front door" to your Lambda functions, EC2, or any HTTP endpoint.

Client → API Gateway → Lambda/EC2/HTTP
                ↕
         Authentication
         Rate Limiting
         Caching
         Request Validation
```

```bash
# Create REST API
aws apigateway create-rest-api \
    --name "My API" \
    --description "Production API" \
    --endpoint-configuration types=REGIONAL

# For more complex setups, use HTTP API (simpler, cheaper):
aws apigatewayv2 create-api \
    --name "My HTTP API" \
    --protocol-type HTTP \
    --target "arn:aws:lambda:us-east-1:123456789:function:my-hello-function"
```

---

---

# PART 8: AUTO SCALING — Automatic Capacity Management

---

## 8.1 EC2 Auto Scaling

```
Auto Scaling automatically adjusts the number of EC2 instances
based on demand. Scale OUT when busy, scale IN when quiet.

Components:
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│  LAUNCH TEMPLATE: "What" to launch                           │
│    - AMI, instance type, key pair, security groups,           │
│      user data, EBS volumes                                  │
│                                                               │
│  AUTO SCALING GROUP (ASG): "Where" and "How many"            │
│    - Min size, Max size, Desired capacity                    │
│    - Subnets/AZs                                             │
│    - Load balancer target group                              │
│                                                               │
│  SCALING POLICIES: "When" to scale                           │
│    - Target Tracking: Keep CPU at 50%                        │
│    - Step Scaling: Add 2 instances when CPU > 80%            │
│    - Scheduled: Scale up at 9am, down at 6pm                 │
│    - Predictive: ML-based prediction                         │
│                                                               │
└───────────────────────────────────────────────────────────────┘

                    ┌───────────────────────┐
                    │   Load Balancer (ALB) │
                    └───┬──────┬──────┬─────┘
                        │      │      │
                   ┌────▼┐ ┌──▼───┐ ┌▼────┐
                   │EC2-1│ │EC2-2 │ │EC2-3│  ← Desired: 3
                   └─────┘ └──────┘ └─────┘
                   
    HIGH LOAD (CPU > 70%):
                        │      │      │      │      │
                   ┌────▼┐ ┌──▼───┐ ┌▼────┐ ┌▼────┐ ┌▼────┐
                   │EC2-1│ │EC2-2 │ │EC2-3│ │EC2-4│ │EC2-5│  ← Scaled to: 5
                   └─────┘ └──────┘ └─────┘ └─────┘ └─────┘

    LOW LOAD (CPU < 30%):
                        │      │
                   ┌────▼┐ ┌──▼───┐
                   │EC2-1│ │EC2-2 │  ← Scaled to: 2 (min)
                   └─────┘ └──────┘
```

```bash
# ============================================================
# STEP 1: Create a Launch Template
# ============================================================
aws ec2 create-launch-template \
    --launch-template-name web-server-template \
    --version-description "v1.0" \
    --launch-template-data '{
  "ImageId": "ami-0abc123",
  "InstanceType": "t3.medium",
  "KeyName": "MyKeyPair",
  "SecurityGroupIds": ["sg-web123"],
  "UserData": "'$(base64 -w 0 << 'USERDATA'
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>Hello from $INSTANCE_ID</h1>" > /var/www/html/index.html
USERDATA
)'",
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {"Key": "Name", "Value": "ASG-WebServer"},
        {"Key": "Environment", "Value": "Production"}
      ]
    }
  ],
  "IamInstanceProfile": {
    "Name": "EC2-SSM-Role"
  },
  "Monitoring": {
    "Enabled": true
  },
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/xvda",
      "Ebs": {
        "VolumeSize": 30,
        "VolumeType": "gp3",
        "Encrypted": true
      }
    }
  ]
}'

# ============================================================
# STEP 2: Create Auto Scaling Group
# ============================================================
aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name web-asg \
    --launch-template LaunchTemplateName=web-server-template,Version='$Latest' \
    --min-size 2 \
    --max-size 10 \
    --desired-capacity 3 \
    --vpc-zone-identifier "subnet-priv1a,subnet-priv1b" \
    --target-group-arns "arn:aws:elasticloadbalancing:...:targetgroup/my-web-targets/abc123" \
    --health-check-type ELB \
    --health-check-grace-period 300 \
    --tags \
        Key=Name,Value=ASG-WebServer,PropagateAtLaunch=true \
        Key=Environment,Value=Production,PropagateAtLaunch=true

# ============================================================
# STEP 3: Create Scaling Policies
# ============================================================

# TARGET TRACKING: Keep average CPU at 50%
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name web-asg \
    --policy-name cpu-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ASGAverageCPUUtilization"
  },
  "TargetValue": 50.0,
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}'

# TARGET TRACKING: Keep request count per target at 1000
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name web-asg \
    --policy-name request-count-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-configuration '{
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ALBRequestCountPerTarget",
    "ResourceLabel": "app/my-web-alb/abc123/targetgroup/my-web-targets/def456"
  },
  "TargetValue": 1000.0
}'

# STEP SCALING: More granular control
# Scale OUT: Add 1 instance when CPU > 60%, add 3 when CPU > 80%
aws autoscaling put-scaling-policy \
    --auto-scaling-group-name web-asg \
    --policy-name scale-out-policy \
    --policy-type StepScaling \
    --adjustment-type ChangeInCapacity \
    --step-adjustments \
        MetricIntervalLowerBound=0,MetricIntervalUpperBound=20,ScalingAdjustment=1 \
        MetricIntervalLowerBound=20,ScalingAdjustment=3

# SCHEDULED SCALING: Scale up for business hours
aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name web-asg \
    --scheduled-action-name scale-up-morning \
    --recurrence "0 9 * * MON-FRI" \
    --min-size 5 \
    --max-size 10 \
    --desired-capacity 5

aws autoscaling put-scheduled-update-group-action \
    --auto-scaling-group-name web-asg \
    --scheduled-action-name scale-down-evening \
    --recurrence "0 18 * * MON-FRI" \
    --min-size 2 \
    --max-size 5 \
    --desired-capacity 2

# ============================================================
# USEFUL ASG COMMANDS
# ============================================================

# Describe ASG
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names web-asg \
    --query 'AutoScalingGroups[0].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances[*].{ID:InstanceId,Health:HealthStatus,AZ:AvailabilityZone}}'

# List scaling activities (what happened and when)
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name web-asg \
    --query 'Activities[*].{Time:StartTime,Status:StatusCode,Cause:Cause}' \
    --output table

# Manually set desired capacity
aws autoscaling set-desired-capacity \
    --auto-scaling-group-name web-asg \
    --desired-capacity 5

# Temporarily protect an instance from scale-in
aws autoscaling set-instance-protection \
    --auto-scaling-group-name web-asg \
    --instance-ids i-0abc123 \
    --protected-from-scale-in

# Detach an instance (remove from ASG but keep running)
aws autoscaling detach-instances \
    --auto-scaling-group-name web-asg \
    --instance-ids i-0abc123 \
    --should-decrement-desired-capacity

# Instance Refresh (rolling deployment of new AMI/launch template)
aws autoscaling start-instance-refresh \
    --auto-scaling-group-name web-asg \
    --preferences '{
  "MinHealthyPercentage": 90,
  "InstanceWarmup": 300
}'

# Check instance refresh status
aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name web-asg
```

---

## 8.2 ECS Auto Scaling

```bash
# ============================================================
# ECS SERVICE AUTO SCALING
# ============================================================

# Register the ECS service as a scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/production-cluster/my-web-service \
    --min-capacity 2 \
    --max-capacity 20

# Target Tracking: Keep average CPU at 50%
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/production-cluster/my-web-service \
    --policy-name ecs-cpu-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "TargetValue": 50.0,
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}'

# Target Tracking: Keep average Memory at 60%
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/production-cluster/my-web-service \
    --policy-name ecs-memory-target-tracking \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageMemoryUtilization"
  },
  "TargetValue": 60.0
}'

# Scheduled scaling for ECS
aws application-autoscaling put-scheduled-action \
    --service-namespace ecs \
    --scalable-dimension ecs:service:DesiredCount \
    --resource-id service/production-cluster/my-web-service \
    --scheduled-action-name morning-scale-up \
    --schedule "cron(0 9 * * ? *)" \
    --scalable-target-action MinCapacity=5,MaxCapacity=20
```

---

---

# PART 9: SECURITY — IAM, WAF, Shield, KMS

---

## 9.1 IAM — Identity and Access Management

```
IAM controls WHO can do WHAT in your AWS account.

Key Concepts:
┌──────────────┬─────────────────────────────────────────────┐
│ Concept      │ Description                                 │
├──────────────┼─────────────────────────────────────────────┤
│ User         │ A person or application (has credentials)   │
│ Group        │ Collection of users (attach policies)       │
│ Role         │ Assumed by services/users (temporary creds) │
│ Policy       │ JSON document defining permissions          │
│ MFA          │ Multi-factor authentication                 │
└──────────────┴─────────────────────────────────────────────┘

Best Practices:
  ✅ Never use root account for daily tasks
  ✅ Enable MFA on root and all users
  ✅ Use roles instead of access keys when possible
  ✅ Follow principle of least privilege
  ✅ Use groups to assign permissions
  ✅ Rotate access keys regularly
```

```bash
# ============================================================
# IAM USERS AND GROUPS
# ============================================================

# Create a user
aws iam create-user --user-name john.developer

# Create access keys (for CLI/API)
aws iam create-access-key --user-name john.developer
# ⚠️ Save the SecretAccessKey! It's only shown once.

# Create a group
aws iam create-group --group-name Developers

# Add user to group
aws iam add-user-to-group --user-name john.developer --group-name Developers

# ============================================================
# IAM POLICIES
# ============================================================

# Attach AWS managed policy to group
aws iam attach-group-policy \
    --group-name Developers \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Create custom policy
cat > custom-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-app-bucket",
        "arn:aws:s3:::my-app-bucket/*"
      ]
    },
    {
      "Sid": "AllowEC2Describe",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyDeleteProduction",
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/Environment": "Production"
        }
      }
    }
  ]
}
EOF

aws iam create-policy \
    --policy-name CustomDevPolicy \
    --policy-document file://custom-policy.json

# ============================================================
# IAM ROLES
# ============================================================

# Create a role for EC2 to access S3
cat > ec2-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role \
    --role-name EC2-S3-Access-Role \
    --assume-role-policy-document file://ec2-trust-policy.json

aws iam attach-role-policy \
    --role-name EC2-S3-Access-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Create instance profile (required to attach role to EC2)
aws iam create-instance-profile \
    --instance-profile-name EC2-S3-Profile

aws iam add-role-to-instance-profile \
    --instance-profile-name EC2-S3-Profile \
    --role-name EC2-S3-Access-Role

# Attach to running EC2 instance
aws ec2 associate-iam-instance-profile \
    --instance-id i-0abc123 \
    --iam-instance-profile Name=EC2-S3-Profile

# ============================================================
# USEFUL IAM COMMANDS
# ============================================================
# List users
aws iam list-users --query 'Users[].{Name:UserName,Created:CreateDate}' --output table

# List attached policies for a user
aws iam list-attached-user-policies --user-name john.developer

# List roles
aws iam list-roles --query 'Roles[].{Name:RoleName,Service:AssumeRolePolicyDocument.Statement[0].Principal.Service}' --output table

# Generate credential report
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | base64 -d
```

---

## 9.2 WAF — Web Application Firewall

```
WAF protects your web applications from common web exploits.
It sits in FRONT of ALB, API Gateway, or CloudFront.

              ┌──────────────────┐
              │    INTERNET      │
              └────────┬─────────┘
                       │
              ┌────────▼─────────┐
              │    AWS WAF       │  ← Inspects every request
              │                  │
              │  Rules:          │
              │  - Block SQL Injection     │
              │  - Block XSS               │
              │  - Rate limiting (DDoS)    │
              │  - Geo blocking            │
              │  - IP whitelist/blacklist  │
              │  - Block bad bots          │
              └────────┬─────────┘
                       │ (allowed requests only)
              ┌────────▼─────────┐
              │    ALB / CF      │
              └──────────────────┘

Components:
  Web ACL:      Collection of rules
  Rule:         What to inspect and what to do
  Rule Group:   Reusable collection of rules
  IP Set:       List of IPs to allow/block
  Regex Set:    Pattern matching
```

```bash
# ============================================================
# CREATE WAF WEB ACL
# ============================================================

# Create IP Set (for whitelisting/blacklisting)
aws wafv2 create-ip-set \
    --name "BlockedIPs" \
    --scope REGIONAL \
    --ip-address-version IPV4 \
    --addresses "1.2.3.4/32" "5.6.7.0/24"

# Create Web ACL with AWS Managed Rules
aws wafv2 create-web-acl \
    --name "MyAppWebACL" \
    --scope REGIONAL \
    --default-action Allow={} \
    --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=MyAppWebACL \
    --rules '[
  {
    "Name": "AWS-AWSManagedRulesCommonRuleSet",
    "Priority": 1,
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesCommonRuleSet"
      }
    },
    "OverrideAction": {"None": {}},
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "CommonRuleSet"
    }
  },
  {
    "Name": "AWS-AWSManagedRulesSQLiRuleSet",
    "Priority": 2,
    "Statement": {
      "ManagedRuleGroupStatement": {
        "VendorName": "AWS",
        "Name": "AWSManagedRulesSQLiRuleSet"
      }
    },
    "OverrideAction": {"None": {}},
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "SQLiRuleSet"
    }
  },
  {
    "Name": "RateLimit",
    "Priority": 3,
    "Statement": {
      "RateBasedStatement": {
        "Limit": 2000,
        "AggregateKeyType": "IP"
      }
    },
    "Action": {"Block": {}},
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "RateLimit"
    }
  },
  {
    "Name": "GeoBlock",
    "Priority": 4,
    "Statement": {
      "GeoMatchStatement": {
        "CountryCodes": ["CN", "RU"]
      }
    },
    "Action": {"Block": {}},
    "VisibilityConfig": {
      "SampledRequestsEnabled": true,
      "CloudWatchMetricsEnabled": true,
      "MetricName": "GeoBlock"
    }
  }
]'

# Associate WAF with ALB
aws wafv2 associate-web-acl \
    --web-acl-arn arn:aws:wafv2:us-east-1:123456789:regional/webacl/MyAppWebACL/abc123 \
    --resource-arn arn:aws:elasticloadbalancing:us-east-1:123456789:loadbalancer/app/my-web-alb/abc123

# List Web ACLs
aws wafv2 list-web-acls --scope REGIONAL

# Get sampled requests (see what's being blocked)
aws wafv2 get-sampled-requests \
    --web-acl-arn arn:aws:wafv2:... \
    --rule-metric-name RateLimit \
    --scope REGIONAL \
    --time-window StartTime=2024-01-01T00:00:00Z,EndTime=2024-01-02T00:00:00Z \
    --max-items 100
```

---

## 9.3 AWS Shield — DDoS Protection

```
AWS Shield protects against DDoS (Distributed Denial of Service) attacks.

Shield Standard:
  ✅ FREE
  ✅ Automatic
  ✅ Protects against common Layer 3/4 attacks
  ✅ Applied to ALL AWS customers

Shield Advanced:
  💰 $3,000/month
  ✅ Enhanced detection and mitigation
  ✅ 24/7 DDoS Response Team (DRT)
  ✅ Cost protection (won't charge for DDoS-caused scaling)
  ✅ Advanced metrics and reporting
  ✅ WAF included at no extra cost
```

---

## 9.4 KMS, ACM, Secrets Manager

```bash
# ============================================================
# KMS — Key Management Service (Encryption)
# ============================================================
# Create a KMS key
aws kms create-key \
    --description "My application encryption key" \
    --key-usage ENCRYPT_DECRYPT

# Create an alias (friendly name)
aws kms create-alias \
    --alias-name alias/my-app-key \
    --target-key-id <key-id>

# Encrypt data
aws kms encrypt \
    --key-id alias/my-app-key \
    --plaintext "MySecretData" \
    --output text --query CiphertextBlob

# ============================================================
# ACM — AWS Certificate Manager (SSL/TLS Certificates)
# ============================================================
# Request a certificate (FREE for AWS services!)
aws acm request-certificate \
    --domain-name myapp.com \
    --subject-alternative-names "*.myapp.com" \
    --validation-method DNS

# List certificates
aws acm list-certificates

# ============================================================
# SECRETS MANAGER
# ============================================================
# Create a secret
aws secretsmanager create-secret \
    --name prod/db-password \
    --description "Production database password" \
    --secret-string '{"username":"admin","password":"SuperSecret123!","host":"mydb.abc.rds.amazonaws.com","port":"5432"}'

# Retrieve a secret
aws secretsmanager get-secret-value \
    --secret-id prod/db-password \
    --query SecretString --output text

# Rotate secret automatically
aws secretsmanager rotate-secret \
    --secret-id prod/db-password \
    --rotation-lambda-arn arn:aws:lambda:...:function:rotation-function \
    --rotation-rules AutomaticallyAfterDays=30

# Update a secret
aws secretsmanager update-secret \
    --secret-id prod/db-password \
    --secret-string '{"username":"admin","password":"NewPassword456!"}'
```

---

---

# PART 10: CI/CD — Continuous Integration / Continuous Deployment

---

## 10.1 CI/CD Concepts

```
CI/CD automates the process of building, testing, and deploying code.

CONTINUOUS INTEGRATION (CI):
  Developers frequently merge code → automatic build → automatic tests
  Goal: Catch bugs early, ensure code always works
  
  Developer → Git Push → Build → Unit Tests → Integration Tests → ✅/❌

CONTINUOUS DELIVERY (CD):
  After CI passes → automatic deployment to staging → manual approval → production
  
CONTINUOUS DEPLOYMENT (CD):
  After CI passes → automatic deployment to staging → automatic to production
  No human intervention!

Pipeline Stages:
┌────────┐   ┌───────┐   ┌───────┐   ┌──────────┐   ┌──────────┐   ┌────────────┐
│ SOURCE │──→│ BUILD │──→│ TEST  │──→│ STAGING  │──→│ APPROVAL │──→│ PRODUCTION │
│ (Git)  │   │       │   │       │   │ Deploy   │   │ (manual) │   │ Deploy     │
└────────┘   └───────┘   └───────┘   └──────────┘   └──────────┘   └────────────┘
```

---

## 10.2 AWS CodePipeline + CodeBuild + CodeDeploy

```
AWS CI/CD Services:
┌──────────────┬──────────────────────────────────────────────┐
│ Service      │ Purpose                                      │
├──────────────┼──────────────────────────────────────────────┤
│ CodeCommit   │ Git repository (like GitHub)                 │
│ CodeBuild    │ Build and test (like Jenkins build step)      │
│ CodeDeploy   │ Deploy to EC2/ECS/Lambda                     │
│ CodePipeline │ Orchestrate the entire pipeline              │
│ CodeArtifact │ Package repository (npm, pip, maven)         │
└──────────────┴──────────────────────────────────────────────┘
```

### CodeBuild — buildspec.yml

```yaml
# buildspec.yml — Goes in root of your repository
version: 0.2

env:
  variables:
    NODE_ENV: "production"
  parameter-store:
    DB_PASSWORD: "/prod/db-password"
  secrets-manager:
    DOCKER_USER: "prod/docker:username"
    DOCKER_PASS: "prod/docker:password"

phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
      - echo "Installing dependencies..."
      - npm ci

  pre_build:
    commands:
      - echo "Running linting..."
      - npm run lint
      - echo "Logging into ECR..."
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/my-app
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}

  build:
    commands:
      - echo "Running tests..."
      - npm test
      - echo "Building Docker image..."
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG

  post_build:
    commands:
      - echo "Pushing Docker image..."
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - echo "Creating imagedefinitions.json for ECS..."
      - printf '[{"name":"web-app","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
    - appspec.yml
    - taskdef.json

reports:
  jest-reports:
    files:
      - 'coverage/clover.xml'
    file-format: 'CLOVERXML'

cache:
  paths:
    - 'node_modules/**/*'
```

```bash
# ============================================================
# CREATE CODEBUILD PROJECT
# ============================================================
aws codebuild create-project \
    --name my-app-build \
    --source '{
  "type": "GITHUB",
  "location": "https://github.com/myorg/my-app.git",
  "buildspec": "buildspec.yml"
}' \
    --artifacts '{"type": "NO_ARTIFACTS"}' \
    --environment '{
  "type": "LINUX_CONTAINER",
  "image": "aws/codebuild/amazonlinux2-x86_64-standard:5.0",
  "computeType": "BUILD_GENERAL1_MEDIUM",
  "privilegedMode": true,
  "environmentVariables": [
    {"name": "AWS_ACCOUNT_ID", "value": "123456789", "type": "PLAINTEXT"},
    {"name": "AWS_DEFAULT_REGION", "value": "us-east-1", "type": "PLAINTEXT"}
  ]
}' \
    --service-role arn:aws:iam::123456789:role/codebuild-role

# Start a build manually
aws codebuild start-build --project-name my-app-build

# View build status
aws codebuild batch-get-builds --ids my-app-build:build-id
```

### CodePipeline — Full Pipeline

```bash
# ============================================================
# CREATE CODEPIPELINE
# ============================================================
cat > pipeline.json << 'EOF'
{
  "pipeline": {
    "name": "my-app-pipeline",
    "roleArn": "arn:aws:iam::123456789:role/codepipeline-role",
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "GitHub-Source",
            "actionTypeId": {
              "category": "Source",
              "owner": "ThirdParty",
              "provider": "GitHub",
              "version": "1"
            },
            "configuration": {
              "Owner": "myorg",
              "Repo": "my-app",
              "Branch": "main",
              "OAuthToken": "{{resolve:secretsmanager:github-token}}"
            },
            "outputArtifacts": [{"name": "SourceOutput"}]
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "Docker-Build",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "configuration": {
              "ProjectName": "my-app-build"
            },
            "inputArtifacts": [{"name": "SourceOutput"}],
            "outputArtifacts": [{"name": "BuildOutput"}]
          }
        ]
      },
      {
        "name": "Deploy-Staging",
        "actions": [
          {
            "name": "Deploy-to-ECS-Staging",
            "actionTypeId": {
              "category": "Deploy",
              "owner": "AWS",
              "provider": "ECS",
              "version": "1"
            },
            "configuration": {
              "ClusterName": "staging-cluster",
              "ServiceName": "my-web-service",
              "FileName": "imagedefinitions.json"
            },
            "inputArtifacts": [{"name": "BuildOutput"}]
          }
        ]
      },
      {
        "name": "Approval",
        "actions": [
          {
            "name": "Manual-Approval",
            "actionTypeId": {
              "category": "Approval",
              "owner": "AWS",
              "provider": "Manual",
              "version": "1"
            },
            "configuration": {
              "NotificationArn": "arn:aws:sns:us-east-1:123456789:pipeline-approvals",
              "CustomData": "Please review staging deployment before production"
            }
          }
        ]
      },
      {
        "name": "Deploy-Production",
        "actions": [
          {
            "name": "Deploy-to-ECS-Production",
            "actionTypeId": {
              "category": "Deploy",
              "owner": "AWS",
              "provider": "ECS",
              "version": "1"
            },
            "configuration": {
              "ClusterName": "production-cluster",
              "ServiceName": "my-web-service",
              "FileName": "imagedefinitions.json"
            },
            "inputArtifacts": [{"name": "BuildOutput"}]
          }
        ]
      }
    ],
    "artifactStore": {
      "type": "S3",
      "location": "my-pipeline-artifacts-bucket"
    }
  }
}
EOF

aws codepipeline create-pipeline --cli-input-json file://pipeline.json

# ============================================================
# PIPELINE MANAGEMENT
# ============================================================
# List pipelines
aws codepipeline list-pipelines

# Get pipeline status
aws codepipeline get-pipeline-state --name my-app-pipeline

# Start pipeline manually
aws codepipeline start-pipeline-execution --name my-app-pipeline

# Approve manual approval step
aws codepipeline put-approval-result \
    --pipeline-name my-app-pipeline \
    --stage-name Approval \
    --action-name Manual-Approval \
    --result summary="Looks good!",status=Approved \
    --token <approval-token>

# View pipeline execution history
aws codepipeline list-pipeline-executions --pipeline-name my-app-pipeline
```

---

## 10.3 GitHub Actions (Alternative CI/CD)

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy to AWS ECS

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: my-app
  ECS_CLUSTER: production-cluster
  ECS_SERVICE: my-web-service
  CONTAINER_NAME: web-app

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run linting
        run: npm run lint
      
      - name: Run tests
        run: npm test -- --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      
      - name: Build, tag, and push image to ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT
      
      - name: Download task definition
        run: |
          aws ecs describe-task-definition \
            --task-definition my-web-app \
            --query taskDefinition > task-definition.json
      
      - name: Update task definition with new image
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ steps.build-image.outputs.image }}
      
      - name: Deploy to Amazon ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
```

---

---

# PART 11: INFRASTRUCTURE AS CODE — CloudFormation & Terraform

---

## 11.1 AWS CloudFormation

```
CloudFormation lets you define your ENTIRE infrastructure in YAML/JSON.
Instead of clicking in the console, you write code.

Benefits:
  ✅ Repeatable: Same template → Same infrastructure every time
  ✅ Version controlled: Track changes in Git
  ✅ Automated: Create/update/delete entire stacks
  ✅ Dependency management: CloudFormation handles order of creation
  ✅ Drift detection: Know when someone changes things manually
  ✅ Rollback: Automatic on failure
```

```yaml
# infrastructure.yml — Complete VPC + ALB + ECS Stack
AWSTemplateFormatVersion: '2010-09-09'
Description: Production Infrastructure Stack

Parameters:
  EnvironmentName:
    Type: String
    Default: production
    AllowedValues: [production, staging, development]
  
  VpcCIDR:
    Type: String
    Default: 10.0.0.0/16
  
  ContainerImage:
    Type: String
    Description: ECR image URI

  DesiredCount:
    Type: Number
    Default: 3

Resources:
  # ──────────── VPC ────────────
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-vpc

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-igw

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      InternetGatewayId: !Ref InternetGateway
      VpcId: !Ref VPC

  # ──────────── SUBNETS ────────────
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-public-1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.2.0/24
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-public-2

  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.3.0/24
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-private-1

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.4.0/24
      Tags:
        - Key: Name
          Value: !Sub ${EnvironmentName}-private-2

  # ──────────── ALB ────────────
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ALB Security Group
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub ${EnvironmentName}-alb
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup

  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub ${EnvironmentName}-tg
      Port: 3000
      Protocol: HTTP
      VpcId: !Ref VPC
      TargetType: ip
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 30

  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup

  # ──────────── ECS ────────────
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub ${EnvironmentName}-cluster

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub ${EnvironmentName}-app
      Cpu: '512'
      Memory: '1024'
      NetworkMode: awsvpc
      RequiresCompatibilities: [FARGATE]
      ExecutionRoleArn: !GetAtt ECSExecutionRole.Arn
      ContainerDefinitions:
        - Name: web-app
          Image: !Ref ContainerImage
          PortMappings:
            - ContainerPort: 3000
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref LogGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: ecs

  ECSService:
    Type: AWS::ECS::Service
    DependsOn: ALBListener
    Properties:
      Cluster: !Ref ECSCluster
      TaskDefinition: !Ref TaskDefinition
      DesiredCount: !Ref DesiredCount
      LaunchType: FARGATE
      NetworkConfiguration:
        AwsvpcConfiguration:
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
          SecurityGroups:
            - !Ref ECSSecurityGroup
      LoadBalancers:
        - TargetGroupArn: !Ref TargetGroup
          ContainerName: web-app
          ContainerPort: 3000

  # ──────────── AUTO SCALING ────────────
  AutoScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 10
      MinCapacity: 2
      ResourceId: !Sub service/${ECSCluster}/${ECSService.Name}
      ScalableDimension: ecs:service:DesiredCount
      ServiceNamespace: ecs
      RoleARN: !GetAtt AutoScalingRole.Arn

  AutoScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: cpu-scaling
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref AutoScalingTarget
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        TargetValue: 50.0

Outputs:
  ALBURL:
    Description: URL of the Application Load Balancer
    Value: !Sub http://${ApplicationLoadBalancer.DNSName}
    Export:
      Name: !Sub ${EnvironmentName}-ALB-URL
  
  ClusterName:
    Value: !Ref ECSCluster
    Export:
      Name: !Sub ${EnvironmentName}-cluster-name
```

```bash
# ============================================================
# CLOUDFORMATION COMMANDS
# ============================================================

# Validate template
aws cloudformation validate-template --template-body file://infrastructure.yml

# Create stack
aws cloudformation create-stack \
    --stack-name production-infra \
    --template-body file://infrastructure.yml \
    --parameters \
        ParameterKey=EnvironmentName,ParameterValue=production \
        ParameterKey=ContainerImage,ParameterValue=123456789.dkr.ecr.us-east-1.amazonaws.com/my-app:latest \
    --capabilities CAPABILITY_IAM \
    --tags Key=Environment,Value=Production

# Watch stack creation progress
aws cloudformation describe-stack-events \
    --stack-name production-infra \
    --query 'StackEvents[*].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}' \
    --output table

# Wait for stack to complete
aws cloudformation wait stack-create-complete --stack-name production-infra

# Update stack
aws cloudformation update-stack \
    --stack-name production-infra \
    --template-body file://infrastructure.yml \
    --parameters \
        ParameterKey=DesiredCount,ParameterValue=5

# Create change set (preview changes before applying)
aws cloudformation create-change-set \
    --stack-name production-infra \
    --change-set-name update-desired-count \
    --template-body file://infrastructure.yml \
    --parameters ParameterKey=DesiredCount,ParameterValue=5

# Review change set
aws cloudformation describe-change-set \
    --stack-name production-infra \
    --change-set-name update-desired-count

# Execute change set
aws cloudformation execute-change-set \
    --stack-name production-infra \
    --change-set-name update-desired-count

# Get stack outputs
aws cloudformation describe-stacks \
    --stack-name production-infra \
    --query 'Stacks[0].Outputs'

# Delete stack (removes ALL resources!)
aws cloudformation delete-stack --stack-name production-infra

# List all stacks
aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --query 'StackSummaries[].{Name:StackName,Status:StackStatus}' --output table

# Detect drift (manual changes)
aws cloudformation detect-stack-drift --stack-name production-infra
aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id <id>
```

---

## 11.2 Terraform (Brief Overview)

```hcl
# main.tf — Terraform equivalent
provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  default = "production"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-1"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"
}

resource "aws_ecs_service" "app" {
  name            = "my-web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.ecs.id]
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "web-app"
    container_port   = 3000
  }
}

output "alb_url" {
  value = "http://${aws_lb.main.dns_name}"
}
```

```bash
# Terraform commands
terraform init          # Initialize, download providers
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Delete everything
terraform fmt           # Format code
terraform validate      # Validate syntax
terraform state list    # List managed resources
terraform import aws_instance.web i-0abc123  # Import existing resource
```

---

---

# PART 12: MONITORING — CloudWatch, CloudTrail, X-Ray

---

## 12.1 CloudWatch — Monitoring & Observability

```
CloudWatch is AWS's monitoring service. It collects:
  - Metrics: CPU, Memory, Network, Custom metrics
  - Logs: Application logs, system logs
  - Alarms: Notifications when thresholds are breached
  - Dashboards: Visual representation of metrics

┌─────────────────────────────────────────────────────────────┐
│                    CloudWatch                                │
│                                                              │
│  ┌── Metrics ──────────┐  ┌── Logs ──────────────────────┐  │
│  │ EC2 CPU             │  │ /var/log/messages            │  │
│  │ ALB RequestCount    │  │ Application stdout/stderr    │  │
│  │ ECS CPU/Memory      │  │ Lambda function logs         │  │
│  │ RDS Connections     │  │ VPC Flow Logs                │  │
│  │ Custom metrics      │  │ CloudTrail API logs          │  │
│  └─────────────────────┘  └──────────────────────────────┘  │
│                                                              │
│  ┌── Alarms ───────────┐  ┌── Dashboards ────────────────┐  │
│  │ CPU > 80% → SNS     │  │ Visual graphs and widgets    │  │
│  │ 5xx errors > 10     │  │ Auto-refresh                 │  │
│  │ Disk > 90%          │  │ Share with team               │  │
│  └─────────────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

```bash
# ============================================================
# CLOUDWATCH METRICS
# ============================================================

# Get EC2 CPU utilization
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-0abc123 \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average Maximum

# Put custom metric
aws cloudwatch put-metric-data \
    --namespace "MyApp" \
    --metric-name "ActiveUsers" \
    --value 150 \
    --unit Count \
    --dimensions Environment=Production,Service=WebApp

# ============================================================
# CLOUDWATCH ALARMS
# ============================================================

# CPU alarm — notify when CPU > 80%
aws cloudwatch put-metric-alarm \
    --alarm-name "High-CPU-Alarm" \
    --alarm-description "CPU utilization exceeds 80%" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-0abc123 \
    --statistic Average \
    --period 300 \
    --evaluation-periods 2 \
    --threshold 80 \
    --comparison-operator GreaterThanThreshold \
    --alarm-actions arn:aws:sns:us-east-1:123456789:alerts-topic \
    --ok-actions arn:aws:sns:us-east-1:123456789:alerts-topic

# ALB 5xx errors alarm
aws cloudwatch put-metric-alarm \
    --alarm-name "ALB-5xx-Errors" \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --dimensions Name=LoadBalancer,Value=app/my-web-alb/abc123 \
    --statistic Sum \
    --period 60 \
    --evaluation-periods 1 \
    --threshold 10 \
    --comparison-operator GreaterThanThreshold \
    --alarm-actions arn:aws:sns:us-east-1:123456789:alerts-topic \
    --treat-missing-data notBreaching

# List alarms
aws cloudwatch describe-alarms \
    --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}' \
    --output table

# ============================================================
# CLOUDWATCH LOGS
# ============================================================

# Create log group
aws logs create-log-group \
    --log-group-name /myapp/production \
    --retention-in-days 30

# Tail logs in real-time
aws logs tail /myapp/production --follow

# Search logs (filter)
aws logs filter-log-events \
    --log-group-name /myapp/production \
    --filter-pattern "ERROR" \
    --start-time $(date -u -d '1 hour ago' +%s000)

# Search with specific pattern
aws logs filter-log-events \
    --log-group-name /myapp/production \
    --filter-pattern '{ $.statusCode = 500 }' \
    --start-time $(date -u -d '24 hours ago' +%s000)

# Export logs to S3
aws logs create-export-task \
    --log-group-name /myapp/production \
    --from $(date -u -d '7 days ago' +%s000) \
    --to $(date -u +%s000) \
    --destination my-log-archive-bucket \
    --destination-prefix logs/myapp

# ============================================================
# CLOUDWATCH LOG INSIGHTS (query language)
# ============================================================
aws logs start-query \
    --log-group-name /ecs/my-web-app \
    --start-time $(date -u -d '1 hour ago' +%s) \
    --end-time $(date -u +%s) \
    --query-string '
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20'

# Get query results
aws logs get-query-results --query-id <query-id>

# ============================================================
# SNS — Simple Notification Service (for alerts)
# ============================================================
# Create topic
aws sns create-topic --name alerts-topic
# Returns: arn:aws:sns:us-east-1:123456789:alerts-topic

# Subscribe email
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789:alerts-topic \
    --protocol email \
    --notification-endpoint devops@company.com

# Subscribe Slack webhook (via Lambda)
# Subscribe PagerDuty
# Subscribe SMS
aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:123456789:alerts-topic \
    --protocol sms \
    --notification-endpoint +1234567890
```

---

## 12.2 CloudTrail — API Activity Logging

```
CloudTrail records ALL API calls made in your AWS account.
Who did what, when, and from where.

Use Cases:
  - Security auditing
  - Compliance
  - Troubleshooting ("who deleted that instance?!")
  - Detecting unauthorized access
```

```bash
# Create a trail (logs to S3)
aws cloudtrail create-trail \
    --name my-audit-trail \
    --s3-bucket-name my-cloudtrail-logs \
    --is-multi-region-trail \
    --enable-log-file-validation

# Start logging
aws cloudtrail start-logging --name my-audit-trail

# Look up recent events
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=EventName,AttributeValue=TerminateInstances \
    --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
    --query 'Events[].{Time:EventTime,User:Username,Event:EventName,Resources:Resources[0].ResourceName}'
```

---

---

# PART 13: ADVANCED — Port Forwarding, Bastion, SSM, VPC Endpoints

---

## 13.1 Port Forwarding & Bastion Host

```
PROBLEM: Your application runs on a private subnet. 
         You need to access it for debugging/admin.

SOLUTION 1: Bastion Host (Jump Box)
    Internet → SSH to Bastion (public) → SSH to Private instance

    ┌──────────┐     ┌──────────────────┐     ┌──────────────────┐
    │ YOU      │────→│ Bastion Host     │────→│ Private Instance │
    │ (laptop) │SSH  │ (Public Subnet)  │SSH  │ (App/DB Server)  │
    └──────────┘     └──────────────────┘     └──────────────────┘
```

```bash
# ============================================================
# BASTION HOST SETUP
# ============================================================

# Launch bastion in public subnet
aws ec2 run-instances \
    --image-id ami-0abc123 \
    --instance-type t3.micro \
    --key-name MyKeyPair \
    --security-group-ids sg-bastion \
    --subnet-id subnet-pub1a \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion}]'

# Bastion security group: Only SSH from YOUR IP
aws ec2 authorize-security-group-ingress \
    --group-id sg-bastion \
    --protocol tcp --port 22 --cidr $(curl -s ifconfig.me)/32

# Private instance SG: Only SSH from Bastion SG
aws ec2 authorize-security-group-ingress \
    --group-id sg-private \
    --protocol tcp --port 22 --source-group sg-bastion

# ============================================================
# SSH THROUGH BASTION (Port Forwarding / SSH Tunneling)
# ============================================================

# Method 1: SSH ProxyJump (modern, recommended)
ssh -i MyKeyPair.pem \
    -J ec2-user@<BASTION_PUBLIC_IP> \
    ec2-user@<PRIVATE_INSTANCE_IP>

# Method 2: SSH config file (~/.ssh/config)
cat >> ~/.ssh/config << 'EOF'
Host bastion
    HostName <BASTION_PUBLIC_IP>
    User ec2-user
    IdentityFile ~/MyKeyPair.pem

Host private-app
    HostName <PRIVATE_INSTANCE_IP>
    User ec2-user
    IdentityFile ~/MyKeyPair.pem
    ProxyJump bastion

Host private-db
    HostName <DB_PRIVATE_IP>
    User ec2-user
    IdentityFile ~/MyKeyPair.pem
    ProxyJump bastion
EOF

# Now simply:
ssh private-app
ssh private-db

# ============================================================
# LOCAL PORT FORWARDING (Access remote service on your laptop)
# ============================================================

# Scenario: Access RDS database (port 5432) on private subnet
# from your local machine through bastion

ssh -i MyKeyPair.pem \
    -L 5432:<RDS_ENDPOINT>:5432 \
    ec2-user@<BASTION_PUBLIC_IP> \
    -N    # Don't execute remote commands

# Now connect to database locally:
psql -h localhost -p 5432 -U admin -d myapp
# Traffic flow: localhost:5432 → bastion → RDS:5432

# Access private web app on port 8080
ssh -i MyKeyPair.pem \
    -L 8080:<PRIVATE_IP>:8080 \
    ec2-user@<BASTION_PUBLIC_IP> -N

# Open in browser: http://localhost:8080

# ============================================================
# REMOTE PORT FORWARDING (Expose local service to remote)
# ============================================================

# Make your local dev server accessible from EC2
ssh -i MyKeyPair.pem \
    -R 8080:localhost:3000 \
    ec2-user@<EC2_PUBLIC_IP>

# Now on EC2: curl localhost:8080 → hits YOUR local machine:3000

# ============================================================
# DYNAMIC PORT FORWARDING (SOCKS Proxy)
# ============================================================

# Create a SOCKS proxy through bastion
ssh -i MyKeyPair.pem \
    -D 1080 \
    ec2-user@<BASTION_PUBLIC_IP> -N

# Configure browser to use SOCKS proxy localhost:1080
# Now ALL browser traffic goes through the bastion
# You can access private resources by their internal IPs/DNS
```

---

## 13.2 AWS Systems Manager (SSM) — No SSH Needed!

```
SSM Session Manager lets you access EC2 instances WITHOUT:
  ❌ SSH keys
  ❌ Bastion hosts
  ❌ Open port 22
  ❌ Public IP

All sessions are logged and auditable!

Requirements:
  ✅ SSM Agent installed (pre-installed on Amazon Linux 2/2023)
  ✅ EC2 instance has IAM role with SSM permissions
  ✅ Instance can reach SSM endpoint (via NAT or VPC endpoint)
```

```bash
# ============================================================
# SSM SETUP
# ============================================================

# Attach SSM policy to EC2 role
aws iam attach-role-policy \
    --role-name EC2-Role \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# ============================================================
# SSM SESSION MANAGER
# ============================================================

# Start a session (like SSH but through SSM)
aws ssm start-session --target i-0abc123

# Port forwarding through SSM (NO bastion needed!)
aws ssm start-session \
    --target i-0abc123 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
# Now access: http://localhost:8080

# Port forwarding to RDS through an EC2 instance
aws ssm start-session \
    --target i-0abc123 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{
  "host": ["mydb.abc.us-east-1.rds.amazonaws.com"],
  "portNumber": ["5432"],
  "localPortNumber": ["5432"]
}'
# Now: psql -h localhost -p 5432 -U admin -d myapp

# ============================================================
# SSM RUN COMMAND (execute commands on multiple instances)
# ============================================================

# Run a command on one instance
aws ssm send-command \
    --instance-ids i-0abc123 \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["df -h","free -m","uptime"]'

# Run on ALL instances with a specific tag
aws ssm send-command \
    --targets Key=tag:Environment,Values=Production \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["yum update -y","systemctl restart httpd"]' \
    --comment "Patching production servers"

# Get command output
aws ssm get-command-invocation \
    --command-id <command-id> \
    --instance-id i-0abc123

# ============================================================
# SSM PARAMETER STORE (config management)
# ============================================================

# Store a parameter
aws ssm put-parameter \
    --name "/myapp/production/db-host" \
    --value "mydb.abc.rds.amazonaws.com" \
    --type String

# Store a secret (encrypted with KMS)
aws ssm put-parameter \
    --name "/myapp/production/db-password" \
    --value "SuperSecret123!" \
    --type SecureString \
    --key-id alias/my-app-key

# Get a parameter
aws ssm get-parameter \
    --name "/myapp/production/db-host" \
    --query 'Parameter.Value' --output text

# Get decrypted secret
aws ssm get-parameter \
    --name "/myapp/production/db-password" \
    --with-decryption \
    --query 'Parameter.Value' --output text

# Get all parameters by path
aws ssm get-parameters-by-path \
    --path "/myapp/production/" \
    --recursive \
    --with-decryption
```

---

## 13.3 VPC Endpoints — Private Access to AWS Services

```
Problem: Your private EC2 instances need to access S3, DynamoDB, ECR, etc.
         Currently, traffic goes: Private → NAT Gateway → Internet → S3
         This costs money (NAT data charges) and is slower.

Solution: VPC Endpoints create a PRIVATE connection to AWS services.
          Traffic never leaves the AWS network.

Two Types:
┌──────────────────┬──────────────────────────────────────────────┐
│ Gateway Endpoint │ For S3 and DynamoDB only. FREE!              │
│                  │ Added to route table.                        │
├──────────────────┼──────────────────────────────────────────────┤
│ Interface        │ For almost all other AWS services.           │
│ Endpoint (ENI)   │ Creates an ENI in your subnet.               │
│                  │ Costs ~$0.01/hour + data charges.             │
│                  │ Also called "PrivateLink"                    │
└──────────────────┴──────────────────────────────────────────────┘
```

```bash
# ============================================================
# GATEWAY ENDPOINT (S3 - FREE!)
# ============================================================
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.s3 \
    --route-table-ids rtb-private \
    --vpc-endpoint-type Gateway

# ============================================================
# INTERFACE ENDPOINT (ECR, CloudWatch, SSM, etc.)
# ============================================================

# ECR endpoints (needed for Fargate in private subnets)
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ecr.api \
    --vpc-endpoint-type Interface \
    --subnet-ids subnet-priv1a subnet-priv1b \
    --security-group-ids sg-endpoint \
    --private-dns-enabled

aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.ecr.dkr \
    --vpc-endpoint-type Interface \
    --subnet-ids subnet-priv1a subnet-priv1b \
    --security-group-ids sg-endpoint \
    --private-dns-enabled

# CloudWatch Logs endpoint
aws ec2 create-vpc-endpoint \
    --vpc-id $VPC_ID \
    --service-name com.amazonaws.us-east-1.logs \
    --vpc-endpoint-type Interface \
    --subnet-ids subnet-priv1a subnet-priv1b \
    --security-group-ids sg-endpoint \
    --private-dns-enabled

# SSM endpoints (for Session Manager without NAT)
for svc in ssm ssmmessages ec2messages; do
  aws ec2 create-vpc-endpoint \
      --vpc-id $VPC_ID \
      --service-name com.amazonaws.us-east-1.$svc \
      --vpc-endpoint-type Interface \
      --subnet-ids subnet-priv1a subnet-priv1b \
      --security-group-ids sg-endpoint \
      --private-dns-enabled
done

# List endpoints
aws ec2 describe-vpc-endpoints \
    --query 'VpcEndpoints[].{ID:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}' \
    --output table
```

---

## 13.4 VPC Peering & Transit Gateway

```
VPC PEERING: Direct private connection between TWO VPCs.
  - No transitive routing (A↔B, B↔C does NOT mean A↔C)
  - Can be cross-account, cross-region

TRANSIT GATEWAY: Hub-and-spoke model for connecting MANY VPCs.
  - Central hub
  - Transitive routing works
  - Connect VPCs, VPNs, Direct Connect

                 VPC Peering:                    Transit Gateway:
              ┌──────┐                        ┌──────┐
              │VPC A │                        │VPC A │──┐
              └──┬───┘                        └──────┘  │
                 │ peering                               │
              ┌──▼───┐                        ┌──────┐  │  ┌─────────────┐
              │VPC B │                        │VPC B │──┼──│Transit GW   │
              └──┬───┘                        └──────┘  │  │ (hub)       │
                 │ peering                               │  └─────────────┘
              ┌──▼───┐                        ┌──────┐  │
              │VPC C │                        │VPC C │──┘
              └──────┘                        └──────┘
       (A cannot reach C!)            (All can reach all!)
```

```bash
# ============================================================
# VPC PEERING
# ============================================================

# Create peering connection
aws ec2 create-vpc-peering-connection \
    --vpc-id vpc-requester \
    --peer-vpc-id vpc-accepter \
    --peer-region us-west-2    # if cross-region

# Accept peering (from accepter account/region)
aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id pcx-abc123

# Add routes in BOTH VPCs
# In VPC A route table:
aws ec2 create-route \
    --route-table-id rtb-vpca \
    --destination-cidr-block 10.1.0.0/16 \
    --vpc-peering-connection-id pcx-abc123

# In VPC B route table:
aws ec2 create-route \
    --route-table-id rtb-vpcb \
    --destination-cidr-block 10.0.0.0/16 \
    --vpc-peering-connection-id pcx-abc123

# Update security groups to allow traffic from peered VPC
aws ec2 authorize-security-group-ingress \
    --group-id sg-vpcb \
    --protocol -1 \
    --cidr 10.0.0.0/16    # VPC A CIDR
```

---

---

# QUICK REFERENCE — Complete Command Cheat Sheet

```bash
# ╔══════════════════════════════════════════════════════════════╗
# ║                    AWS CLI CHEAT SHEET                       ║
# ╚══════════════════════════════════════════════════════════════╝

# ──────────── IDENTITY ────────────
aws sts get-caller-identity                    # Who am I?
aws configure list                             # Current config

# ──────────── EC2 ────────────
aws ec2 describe-instances --output table
aws ec2 run-instances --image-id ami-xxx --instance-type t3.micro --key-name MyKey
aws ec2 start-instances --instance-ids i-xxx
aws ec2 stop-instances --instance-ids i-xxx
aws ec2 terminate-instances --instance-ids i-xxx
aws ec2 describe-security-groups
aws ec2 describe-vpcs
aws ec2 describe-subnets

# ──────────── S3 ────────────
aws s3 ls
aws s3 cp file.txt s3://bucket/
aws s3 sync ./dir s3://bucket/dir
aws s3 rm s3://bucket/file.txt
aws s3 presign s3://bucket/file --expires-in 3600

# ──────────── ECS ────────────
aws ecs list-clusters
aws ecs list-services --cluster mycluster
aws ecs describe-services --cluster mycluster --services myservice
aws ecs list-tasks --cluster mycluster
aws ecs update-service --cluster mycluster --service myservice --desired-count 5
aws ecs update-service --cluster mycluster --service myservice --task-definition newtd --force-new-deployment

# ──────────── ECR ────────────
aws ecr get-login-password | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
aws ecr describe-repositories
aws ecr list-images --repository-name myrepo

# ──────────── LAMBDA ────────────
aws lambda list-functions
aws lambda invoke --function-name myfunction response.json
aws lambda update-function-code --function-name myfunction --zip-file fileb://code.zip

# ──────────── LOAD BALANCER ────────────
aws elbv2 describe-load-balancers
aws elbv2 describe-target-health --target-group-arn arn:xxx

# ──────────── AUTO SCALING ────────────
aws autoscaling describe-auto-scaling-groups
aws autoscaling set-desired-capacity --auto-scaling-group-name myasg --desired-capacity 5

# ──────────── CLOUDWATCH ────────────
aws logs tail /ecs/myapp --follow
aws cloudwatch describe-alarms

# ──────────── IAM ────────────
aws iam list-users
aws iam list-roles
aws iam list-policies --scope Local

# ──────────── SSM ────────────
aws ssm start-session --target i-xxx
aws ssm get-parameter --name /myapp/config --with-decryption
aws ssm send-command --instance-ids i-xxx --document-name AWS-RunShellScript --parameters 'commands=["uptime"]'

# ──────────── CLOUDFORMATION ────────────
aws cloudformation list-stacks
aws cloudformation create-stack --stack-name mystack --template-body file://template.yml
aws cloudformation delete-stack --stack-name mystack
aws cloudformation describe-stack-events --stack-name mystack

# ──────────── ROUTE53 ────────────
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id ZXXXXX

# ──────────── WAF ────────────
aws wafv2 list-web-acls --scope REGIONAL
```

---

# ARCHITECTURE PATTERNS — Putting It All Together

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     PRODUCTION-READY AWS ARCHITECTURE                           │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                           INTERNET                                       │   │
│  └────────────────────────────┬──────────────────────────────────────────────┘   │
│                               │                                                 │
│                        ┌──────▼──────┐                                          │
│                        │ Route 53    │  DNS                                     │
│                        │ (DNS)       │  myapp.com → CloudFront/ALB              │
│                        └──────┬──────┘                                          │
│                               │                                                 │
│                        ┌──────▼──────┐                                          │
│                        │ CloudFront  │  CDN + WAF                               │
│                        │ + WAF       │  DDoS protection, caching                │
│                        └──────┬──────┘                                          │
│                               │                                                 │
│  ┌── VPC (10.0.0.0/16) ──────┼──────────────────────────────────────────────┐  │
│  │                            │                                              │  │
│  │  ┌── Public Subnets ──────▼────────────────────────────────────────┐     │  │
│  │  │                                                                  │     │  │
│  │  │   ┌───────────────────┐                                          │     │  │
│  │  │   │  ALB (HTTPS:443)  │  Application Load Balancer              │     │  │
│  │  │   │  SSL Termination  │  Path-based routing                     │     │  │
│  │  │   └────────┬──────────┘                                          │     │  │
│  │  │            │              ┌──────────────┐                       │     │  │
│  │  │            │              │ NAT Gateway  │  Outbound internet    │     │  │
│  │  │            │              └──────┬───────┘  for private subnets  │     │  │
│  │  └────────────┼──────────────────────┼──────────────────────────────┘     │  │
│  │               │                      │                                    │  │
│  │  ┌── Private Subnets ───────────────────────────────────────────────┐    │  │
│  │  │            │                      │                               │    │  │
│  │  │   ┌────────▼──────────┐                                           │    │  │
│  │  │   │  ECS Fargate      │  Application containers                  │    │  │
│  │  │   │  ┌─────┐ ┌─────┐ │  Auto-scaled based on CPU/memory         │    │  │
│  │  │   │  │Task │ │Task │ │                                           │    │  │
│  │  │   │  │ 1   │ │ 2   │ │                                           │    │  │
│  │  │   │  └─────┘ └─────┘ │                                           │    │  │
│  │  │   └───────────────────┘                                           │    │  │
│  │  │            │                                                      │    │  │
│  │  │   ┌────────▼──────────┐  ┌──────────────┐  ┌───────────────┐    │    │  │
│  │  │   │  RDS (Multi-AZ)   │  │ ElastiCache  │  │ S3 (via VPC   │    │    │  │
│  │  │   │  PostgreSQL       │  │ Redis        │  │  Endpoint)    │    │    │  │
│  │  │   │  Primary + Standby│  │ Session/Cache│  │ File storage  │    │    │  │
│  │  │   └───────────────────┘  └──────────────┘  └───────────────┘    │    │  │
│  │  │                                                                   │    │  │
│  │  └───────────────────────────────────────────────────────────────────┘    │  │
│  │                                                                           │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
│                                                                                 │
│  ┌── CI/CD Pipeline ──────────────────────────────────────────────────────┐    │
│  │  GitHub → CodePipeline → CodeBuild → ECR → ECS (Blue/Green Deploy)    │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌── Monitoring ──────────────────────────────────────────────────────────┐    │
│  │  CloudWatch Metrics + Logs + Alarms → SNS → Slack/PagerDuty/Email     │    │
│  │  CloudTrail → S3 (audit logs)                                          │    │
│  │  X-Ray → Distributed tracing                                          │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

# SUMMARY — Learning Path

```
BEGINNER (Weeks 1-4):
  ☐ Linux basics (commands, permissions, processes)
  ☐ Networking fundamentals (IP, ports, protocols, CIDR)
  ☐ AWS account setup, IAM basics
  ☐ EC2 (launch, SSH, security groups)
  ☐ S3 (buckets, objects, CLI)
  ☐ VPC basics (subnets, route tables, internet gateway)

INTERMEDIATE (Weeks 5-8):
  ☐ Docker (Dockerfile, compose, images)
  ☐ Load Balancers (ALB, target groups, health checks)
  ☐ Auto Scaling (launch templates, ASG, policies)
  ☐ ECR + ECS (task definitions, services, Fargate)
  ☐ Route 53 (DNS, records, routing policies)
  ☐ NAT Gateway, VPC endpoints

ADVANCED (Weeks 9-12):
  ☐ CI/CD (CodePipeline, CodeBuild, GitHub Actions)
  ☐ Infrastructure as Code (CloudFormation or Terraform)
  ☐ Security (WAF, IAM policies, KMS, Secrets Manager)
  ☐ Monitoring (CloudWatch, alarms, dashboards)
  ☐ SSM Session Manager, port forwarding
  ☐ Cost optimization (Spot, Reserved, Savings Plans)

EXPERT (Ongoing):
  ☐ Multi-account strategies (AWS Organizations)
  ☐ Kubernetes (EKS)
  ☐ Service mesh (App Mesh)
  ☐ Disaster recovery patterns
  ☐ Performance optimization
  ☐ Well-Architected Framework
```

---

> **This guide covers the foundational through advanced DevOps and AWS concepts. Each section builds on the previous one. Practice each concept in a real AWS account (use Free Tier!) — reading alone is not enough. Build, break, fix, repeat.** 🚀