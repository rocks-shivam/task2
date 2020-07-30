provider "aws" {
  region = "ap-south-1"
  profile = "shivam1"
}
resource "tls_private_key" "mykey" {
  algorithm   = "RSA"
}
resource "aws_key_pair" "mykey" {
  key_name   = "efskey"
  public_key = tls_private_key.mykey.public_key_openssh
}
resource "aws_security_group" "efssg" {
depends_on = [
aws_key_pair.mykey,
]
name = "efs_security_group"
	description = "Allow http traffic on port 80 , ssh on port 22 and nfs on port 2049."

	ingress { 
		description = "http on port 80."
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress { // Check
		description = "ssh on port 22."
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
        ingress { 
		description = "nfs on port 2049."
		from_port = 2049
		to_port = 2049
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
        }

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	lifecycle {
		create_before_destroy = true
	}

	tags = {
		Name = "myefssg"
	}
}
resource "aws_efs_file_system" "efs" {
  creation_token = "myefs"

  tags = {
    Name = "myefs"
  }
}
resource "aws_efs_mount_target" "mount1" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-d2f2c8ba"
  security_groups = [ "${aws_security_group.efssg.id}" ]

}
resource "aws_efs_mount_target" "mount2" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-c7610a8b"
  security_groups = [ "${aws_security_group.efssg.id}" ]

}
resource "aws_efs_mount_target" "mount3" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = "subnet-e1fa479a"
  security_groups = [ "${aws_security_group.efssg.id}" ]

}




resource "aws_instance" "efsinstance" {
depends_on = [
aws_efs_mount_target.mount3,
]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = aws_key_pair.mykey.key_name
  security_groups = [ aws_security_group.efssg.name]
  user_data = <<-EOF
                     #! /bin/bash
                     #cloud-config
                     repo_update: true
                     repo_upgrade: all
                     sudo yum install httpd -y
                     sudo systemctl start httpd
                     sudo systemctl enable httpd
                     yum install -y amazon-efs-utils
                     apt-get -y install amazon-efs-utils
                     yum install -y nfs-utils
                     apt-get -y install nfs-common
                     file_system_id_1="${aws_efs_file_system.efs.id}"
                     efs_mount_point_1="/var/www/html"
                     mkdir -p "$efs_mount_point_1"
                     test -f "/sbin/mount.efs" && echo "$file_system_id_1:/ $efs_mount_point_1 efs tls,_netdev" >> /etc/fstab || echo "$file_system_id_1.efs.ap-south-1.amazonaws.com:/ $efs_mount_point_1 nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
                     test -f "/sbin/mount.efs" && echo -e "\n[client-info]\nsource=liw" >> /etc/amazon/efs/efs-utils.conf
                     mount -a -t efs,nfs4 defaults
                     sudo yum install git -y
                     git clone https://github.com/rocks-shivam/mycloud2.git /var/www/html
                     
                EOF


  
  tags = {
    Name = "mytask2os"
  }

}
output "myos_ip" {
  value = aws_instance.efsinstance.public_ip
}


resource "null_resource" "local1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.efsinstance.public_ip} > publicip.txt"
  	}
}
resource "null_resource" "local2"  {


depends_on = [
    aws_instance.efsinstance,
  ]

	provisioner "local-exec" {
	    command = "firefox  ${aws_instance.efsinstance.public_ip}/file2.html"
  	}
}
