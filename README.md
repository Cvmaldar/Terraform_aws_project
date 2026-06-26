# Summary of Terraform Configuration

## Flow of User Access

### User Access via Browser or HTTP Client
- Users access the Application Load Balancer (ALB) using its DNS name (`loadbalancerdns`).
- The ALB listens on port 80 for HTTP traffic.

### Application Load Balancer (ALB)
- The ALB is public-facing (`internal = false`), accessible from the internet.
- It is associated with two subnets (`sub1` and `sub2`) for high availability.
- The ALB forwards traffic to the target group based on listener configuration.

### Target Group
- Defines backend resources (EC2 instances) for routing traffic.
- Configured to use HTTP on port 80.
- Performs health checks on backend instances using the `/` path.
- Ensures only healthy instances receive traffic, improving application reliability.

### Additional Details for Beginners
- **Internet-Facing ALB**: The ALB is internet-facing, meaning it can accept traffic from the public internet. This is achieved by setting `internal = false` in the ALB configuration.
- **High Availability**: By associating the ALB with multiple subnets (`sub1` and `sub2`) across different availability zones, the setup ensures high availability and fault tolerance.
- **Listener Configuration**: The ALB listener is configured to forward HTTP traffic (port 80) to the target group. This setup can be extended to include HTTPS (port 443) for secure communication.
- **Health Checks**: Health checks are critical for monitoring the status of backend instances. The ALB periodically sends requests to the `/` path of each instance to verify its health. Unhealthy instances are automatically removed from the target group.

### Beginner Tips
- **Understand the Flow**: Start by understanding how user requests flow from the ALB to the EC2 instances. This will help you grasp the overall architecture.
- **Experiment with Configurations**: Modify the ALB and target group settings to see how changes affect traffic routing and instance health.
- **Learn Security Best Practices**: Ensure the security group rules are configured to allow only necessary traffic. For example, restrict SSH access to specific IPs instead of allowing all IPs.
- **Practice with Terraform**: Use this setup as a hands-on project to practice Terraform commands (`terraform init`, `terraform plan`, `terraform apply`) and understand how infrastructure is provisioned.

This detailed explanation will help beginners understand the concepts and prepare for interviews effectively.
- Defines backend resources (EC2 instances) for routing traffic.
- Configured to use HTTP on port 80.
- Performs health checks on backend instances using the `/` path.

### EC2 Instances
- Includes two EC2 instances (`webserver1` and `webserver2`) as targets.
- Instances are launched in separate subnets (`sub1` and `sub2`) for redundancy.
- Configured with user data scripts (`userdata.sh` and `userdata1.sh`) for software setup.

### Security Group
- Allows:
  - Inbound HTTP traffic (port 80) from any IP address.
  - Inbound SSH traffic (port 22) for administrative access.
  - All outbound traffic for external communication.

### Internet Gateway and Route Table
- The VPC includes an Internet Gateway (`aws_internet_gateway.igw`) for internet access.
- Route tables are configured to direct traffic through the gateway.