# Create a VPC with a CIDR block specified by the variable `cidr`
resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr
}

# Create the first subnet in availability zone "ap-south-1a" with a CIDR block of "10.0.0.0/24"
resource "aws_subnet" "sub1" {
    vpc_id                  = aws_vpc.myvpc.id
    cidr_block              = "10.0.0.0/24"
    availability_zone       = "ap-south-1a"
    map_public_ip_on_launch = true # Automatically assign public IPs to instances in this subnet
}

# Create the second subnet in availability zone "ap-south-1b" with a CIDR block of "10.0.1.0/24"
resource "aws_subnet" "sub2" {
    vpc_id                  = aws_vpc.myvpc.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "ap-south-1b"
    map_public_ip_on_launch = true # Automatically assign public IPs to instances in this subnet
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
}

# Create a route table for the VPC
resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.myvpc.id

    # Add a route to allow all outbound traffic (0.0.0.0/0) through the Internet Gateway
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

# Associate the first subnet with the route table
resource "aws_route_table_association" "rta1" {
    subnet_id      = aws_subnet.sub1.id
    route_table_id = aws_route_table.rt.id
}

# Associate the second subnet with the route table
resource "aws_route_table_association" "rta2" {
    subnet_id      = aws_subnet.sub2.id
    route_table_id = aws_route_table.rt.id
}

# Create a security group for the VPC
resource "aws_security_group" "sg" {
    name_prefix = "web-sg" # Prefix for the security group name
    vpc_id      = aws_vpc.myvpc.id

    # Allow inbound HTTP traffic (port 80) from any IP address
    ingress {
        description = "HTTP from VPC"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow inbound SSH traffic (port 22) from any IP address
    ingress {
        description = "SSH from VPC"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound traffic from the security group
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1 # -1 means all protocols
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Add a tag to the security group for identification
    tags = {
        Name = "Web-sg"
    }
}

# Create an S3 bucket
resource "aws_s3_bucket" "example" {
    bucket = "chinmayterraform"
}

# Launch the first EC2 instance in the first subnet
resource "aws_instance" "webserver1" {
    ami                    = "ami-01a00762f46d584a1" # AMI ID for the instance
    instance_type          = "t2.micro" # Instance type
    vpc_security_group_ids = [aws_security_group.sg.id] # Attach security group
    subnet_id              = aws_subnet.sub1.id # Place in the first subnet
    user_data              = base64encode(file("userdata.sh")) # User data script for initialization
}

# Launch the second EC2 instance in the second subnet
resource "aws_instance" "webserver2" {
    ami                    = "ami-01a00762f46d584a1" # AMI ID for the instance
    instance_type          = "t2.micro" # Instance type
    vpc_security_group_ids = [aws_security_group.sg.id] # Attach security group
    subnet_id              = aws_subnet.sub2.id # Place in the second subnet
    user_data              = base64encode(file("userdata1.sh")) # User data script for initialization
}

# Create an Application Load Balancer (ALB)
resource "aws_alb" "my_alb" {
    name               = "myalb" # Name of the ALB
    internal           = false # Public ALB
    load_balancer_type = "application" # ALB type

    security_groups = [aws_security_group.sg.id] # Attach security group
    subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id] # Attach subnets

    tags = {
        Name = "web"
    }
}

# Create a target group for the ALB
resource "aws_lb_target_group" "tg" {
    name     = "myTg" # Name of the target group
    port     = 80 # Port for the target group
    protocol = "HTTP" # Protocol for the target group
    vpc_id   = aws_vpc.myvpc.id # VPC ID

    health_check {
        path = "/" # Health check path
        port = "traffic-port" # Health check port
    }
}

# Attach the first EC2 instance to the target group
resource "aws_lb_target_group_attachment" "attach1" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id        = aws_instance.webserver1.id
    port             = 80
}

# Attach the second EC2 instance to the target group
resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id        = aws_instance.webserver2.id
    port             = 80
}

# Create a listener for the ALB
resource "aws_lb_listener" "listener" {
    load_balancer_arn = aws_alb.my_alb.arn
    port              = 80 # Listener port
    protocol          = "HTTP" # Listener protocol

    default_action {
        target_group_arn = aws_lb_target_group.tg.arn
        type             = "forward" # Forward traffic to the target group
    }
}

# Output the DNS name of the ALB
output "loadbalancerdns" {
    value = aws_alb.my_alb.dns_name
}