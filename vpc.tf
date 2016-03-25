provider "aws" {
    region = "eu-west-1"
}

resource "aws_key_pair" "deployer" {
  key_name = "svc_ssh_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzhmSRIOS7o+Uu4w4WNYG0mS1ES52Lrt+jNug+KfLkwuDoQ8PZtZ8/4FKiIhS/XlcGze/QIgMKpDDDQFLi6/PlYyleH1TeqNHTE3f8Ci/zkoouWHj9WCjKwZYIU9+gMtAoL88t7JpEpCPxUhskTscPkzh83IhSAqZZjoXrI508UoBkaj4giGER714DrgJ6azjpsBMqaGCU+1v/2VRFuXvs/ONnEYWim9jBwfClQmIrRkKS9UcvXkYKeEafIFswJR1Ykx8tc18FBQtji0vsCSohYEz3AlQ+vbOC4QUODhgUTWpeoDphKVWyVsOrcOycDenKR0pAP/PQj8E7Sd3EEKSh JuiceSSH"
}

# Create a VPC
resource "aws_vpc" "svc_vpc" {
    cidr_block = "10.0.0.0/16"
    tags {
        Name = "svc_vpc"
    }
}

# Create a security group within the VPC which allows incoming access to the Web Servers.
resource "aws_security_group" "svc_ssh_access" {
    name = "svc_ssh_access"
    description = "Allow inbound SSH traffic on port 443 and 22"
    vpc_id = "${aws_vpc.svc_vpc.id}"

    # Allow SSH from everywhere.
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # I've setup SSH on port 443 to see if the network restrictions can be bypassed.
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outgoing traffic.
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name = "svc_ssh_access"
    }
}

resource "aws_security_group" "svc_incoming_web" {
  name = "svc_incoming_web"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id = "${aws_vpc.svc_vpc.id}"

  # Allow HTTP traffic from everywhere.
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH traffic from the local VPCs.
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all outgoing traffic.
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "svc_incoming_web"
  }
}

# Create a public subnet in the "svc_vpc" VPC for each availability zone.
resource "aws_subnet" "svc_vpc_public_subnet_a" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.129.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-west-1a"
    tags {
      Name = "svc_vpc_public_subnet_a"
    }
}

resource "aws_subnet" "svc_vpc_public_subnet_b" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.130.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-west-1b"
    tags {
      Name = "svc_vpc_public_subnet_b"
    }
}

resource "aws_subnet" "svc_vpc_public_subnet_c" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.131.0/24"
    map_public_ip_on_launch = true
    availability_zone = "eu-west-1c"
    tags {
      Name = "svc_vpc_public_subnet_c"
    }
}

# Create a private subnet in the "svc_vpc" VPC for each availability zone.
resource "aws_subnet" "svc_vpc_private_subnet_a" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = false
    availability_zone = "eu-west-1a"
    tags {
      Name = "svc_vpc_private_subnet_a"
    }
}

resource "aws_subnet" "svc_vpc_private_subnet_b" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = false
    availability_zone = "eu-west-1b"
    tags {
      Name = "svc_vpc_private_subnet_b"
    }
}

resource "aws_subnet" "svc_vpc_private_subnet_c" {
    vpc_id = "${aws_vpc.svc_vpc.id}"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = false
    availability_zone = "eu-west-1c"
    tags {
      Name = "svc_vpc_private_subnet_c"
    }
}

# Create instances and add them to the subnets created above.

# Create a bastion host for SSH access and Ansible execution.
resource "aws_instance" "ansible_controller" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_public_subnet_a.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_ssh_access.id}" ]
    tags {
      Name = "ansible_controller"
    }
    user_data = "${file("setup_ansible_controller.sh")}"
}

resource "aws_instance" "web1" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_public_subnet_a.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_incoming_web.id}" ]
    tags {
      Name = "web1"
    }
    user_data = "${file("run_app.sh")}"
}

resource "aws_instance" "web2" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1b"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_public_subnet_b.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_incoming_web.id}" ]
    tags {
      Name = "web2"
    }
    user_data = "${file("run_app.sh")}"
}

resource "aws_instance" "web3" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1c"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_public_subnet_c.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_incoming_web.id}" ]
    tags {
      Name = "web3"
    }
    user_data = "${file("run_app.sh")}"
}

# Setup a load balancer.

# Create an Internet gateway to route traffic to the Web servers.
resource "aws_internet_gateway" "svc_gateway" {
    vpc_id = "${aws_vpc.svc_vpc.id}"

    tags {
        Name = "svc_gateway"
    }
}

# Grant the VPC Internet access on its main route table
resource "aws_route" "svc_internet_access" {
  route_table_id         = "${aws_vpc.svc_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.svc_gateway.id}"
}

# Now create a NAT gateway in the public subnet which the private subnet can
# access.

# To do this, setup a elastic IP.
resource "aws_eip" "svc_nat_eip" {
    vpc = true
}

# Add a NAT gateway in the public subnet which uses the eip.
# Note that the NAT gateway only runs in subnet A.
resource "aws_nat_gateway" "svc_nat_gateway" {
    allocation_id = "${aws_eip.svc_nat_eip.id}"
    subnet_id = "${aws_subnet.svc_vpc_public_subnet_a.id}"
    depends_on = ["aws_internet_gateway.svc_gateway"]
}

# Create a route to connect the private subnets to the NAT gateway.
resource "aws_route_table" "svc_vpc_private_subnet_nat_route_table" {
    vpc_id = "${aws_vpc.svc_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.svc_nat_gateway.id}"
    }

    tags {
        Name = "svc_vpc_private_subnet_nat_route_table"
    }
}

# Associate the route with the private subnets.
resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_a.id}"
    route_table_id = "${aws_route_table.svc_vpc_private_subnet_nat_route_table.id}"
}

resource "aws_route_table_association" "b" {
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_b.id}"
    route_table_id = "${aws_route_table.svc_vpc_private_subnet_nat_route_table.id}"
}

resource "aws_route_table_association" "c" {
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_c.id}"
    route_table_id = "${aws_route_table.svc_vpc_private_subnet_nat_route_table.id}"
}

# Setup a load balancer.
resource "aws_elb" "svc_elb" {
  name = "scv-elb"
  subnets = [
    "${aws_subnet.svc_vpc_public_subnet_a.id}",
    "${aws_subnet.svc_vpc_public_subnet_b.id}",
    "${aws_subnet.svc_vpc_public_subnet_c.id}"
  ]
  security_groups = [ "${aws_security_group.svc_incoming_web.id}" ]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 8
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  instances = [ "${aws_instance.web1.id}", "${aws_instance.web2.id}", "${aws_instance.web3.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "scv-elb"
  }
}

# Create MongoDB instances.

# Create a security group for MongoDB.
resource "aws_security_group" "svc_mongo_access" {
    name = "svc_mongo_access"
    description = "Allow inbound port 27017 from the Web servers and SSH from the bastion."
    vpc_id = "${aws_vpc.svc_vpc.id}"

    # Allow MongoDB from the Web Servers.
    ingress {
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    # Allow SSH from the Web Servers.
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    # Allow all outgoing traffic.
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name = "svc_mongo_access"
    }
}

resource "aws_instance" "mongo1" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1a"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_a.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_mongo_access.id}" ]
    private_ip = "10.0.1.250"
    tags {
      Name = "mongo1"
    }
}

resource "aws_instance" "mongo2" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1b"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_b.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_mongo_access.id}" ]
    private_ip = "10.0.2.250"
    tags {
      Name = "mongo2"
    }
}

resource "aws_instance" "mongo3" {
    ami = "ami-e1398992"
    availability_zone = "eu-west-1c"
    instance_type = "t2.micro"
    key_name = "svc_ssh_key"
    subnet_id = "${aws_subnet.svc_vpc_private_subnet_c.id}"
    vpc_security_group_ids = [ "${aws_security_group.svc_mongo_access.id}" ]
    private_ip = "10.0.3.250"
    tags {
      Name = "mongo3"
    }
}
