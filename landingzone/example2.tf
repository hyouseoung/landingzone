/*
    Cross Account를 위한 Assume Role 생성
*/
resource "aws_iam_role" "EC2S3AccessRole" {
    name = "ADMIN_ROLE"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
    {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
            "Service" = "ec2.amazonaws.com"
        }
    },
    ]
})


    tags = {
    tag-key = "tag-value"
    }
}

// Role 권한 연결
resource "aws_iam_role_policy_attachment" "EC2S3AccessRoleAttachment" {
    role       = aws_iam_role.EC2S3AccessRole.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

data "aws_iam_role" "EC2S3AccessRole" {
    name = "EC2S3AccessRole"
}

resource "aws_instance" "EC2ForS3Access" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"

    iam_instance_profile = data.aws_iam_role.EC2S3AccessRole.id

    tags = {
        Name = "EC2 For S3 Access"
    }
}