# AWS Scalable Web Application Project

A complete end-to-end cloud project built on AWS, featuring EC2 Auto Scaling, Load Balancing, S3 static hosting, CloudFront CDN, and CloudWatch monitoring.  
Designed as a real-world production-style architecture for learning and portfolio use.

---

# 🚀 Architecture Overview

## 🌐 Frontend (Static Content)
- S3 bucket hosting `index.html`
- Bucket is private
- CloudFront (with Origin Access Control) delivers the content globally

## 🖥 Backend (Dynamic Content)
- EC2 instances running Amazon Linux 2023
- Apache (httpd) installed automatically via User Data
- Auto Scaling Group maintains capacity and scales based on CPU
- Application Load Balancer distributes traffic

## 📊 Monitoring
- CloudWatch Agent installed on EC2 instances
- Collects CPU, RAM, disk usage
- Sends Apache access & error logs
- CloudWatch Alarms trigger Auto Scaling events

---

# 🛠️ Deployment Steps

## **1️⃣ Create S3 Bucket (Frontend)**
- Bucket name: **s3-bucket-us-1**
- Upload `index.html`
- Disable *Block public access*
- Enable *Static website hosting*
- Website endpoint example:  
  `http://s3-bucket-us-1.s3-website-us-east-1.amazonaws.com`

---

## **2️⃣ Create CloudFront Distribution**
- Origin: S3 *website* endpoint  
- Enable **Origin Access Control (OAC)**
- Copy the recommended bucket policy into S3 Bucket Policy
- After deployed, access the distribution URL  
  Example:  
  `https://d39dqsbgpgycom.cloudfront.net`

---

## **3️⃣ Create Security Groups**

### **SG-for-EC2**
Inbound:
- HTTP 80 → from Load Balancer SG  
- SSH 22 → from my IP only

### **SG-for-LoadBalancer**
Inbound:
- HTTP 80 → from Anywhere (0.0.0.0/0)

---

## **4️⃣ Create Launch Template**
- AMI: **Amazon Linux 2023**
- Type: `t3.micro`
- SG: **SG-for-EC2**
- User Data:

```bash
#!/bin/bash
dnf update -y
dnf install -y httpd aws-cli
systemctl enable httpd
systemctl start httpd
aws s3 cp s3://s3-bucket-us-1/index.html /var/www/html/index.html
```

---

## **5️⃣ Create Application Load Balancer**
- Type: **Application Load Balancer**
- Port 80 listener
- SG: SG-for-LoadBalancer
- Create Target Group:
  - Type: Instances  
  - Health check path: `/`
- Do NOT register instances (ASG will)

---

## **6️⃣ Create Auto Scaling Group**
- Use the Launch Template
- Choose 2+ subnets
- Attach ALB Target Group
- Capacity:
  - Min: 2  
  - Desired: 2  
  - Max: 4  

---

## **7️⃣ Auto Scaling Policy**
- Policy type: **Target Tracking**
- Metric: *Average CPU Utilization*
- Target: **40%**
- Instance warmup: 120 seconds

---

## **8️⃣ Install CloudWatch Agent on EC2**
SSH into an EC2 instance and run:

```bash
sudo yum install amazon-cloudwatch-agent -y
```

Create config:

```bash
sudo nano /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

Paste:

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "/aws/ec2/webapp/access",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/httpd/error_log",
            "log_group_name": "/aws/ec2/webapp/error",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
```

Start the agent:

```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
```

---

# 📂 Project Files Structure

```
aws-scalable-webapp-project/
│
├── README.md
│
├── project-files/
│   ├── index.html
│   ├── user-data.sh
│   ├── cloudwatch-agent.json
│   └── architecture-diagram.png
```

---

# 🧪 Load Testing
Simulate CPU load:

```bash
sudo stress --cpu 8 --timeout 300
```

The ASG will automatically scale out if CPU > 40%.

---

# ✔️ Technologies Used
- AWS EC2
- Auto Scaling Groups
- Application Load Balancer
- Amazon S3
- CloudFront OAC
- CloudWatch Logs & Metrics
- Amazon Linux 2023
- Apache (httpd)



