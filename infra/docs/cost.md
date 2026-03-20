# Cost Guide

- **t3.micro EC2**: ~$8–9/mo
- **t4g.micro (ARM)**: ~$6/mo (use if app supports ARM images)
- **ECR storage**: ~$0.10/GB/mo
- **CloudWatch logs**: ~$0.50 per GB ingested
- **ALB (if tls_mode=alb_acm)**: ~$18–20/mo + data processed

---

## Upgrade Path
When CPU > 70% sustained:
- Switch from EC2+Docker to ECS Fargate or EKS
- Replace Nginx with ALB + Target Groups
- Use Autoscaling groups for multiple instances
