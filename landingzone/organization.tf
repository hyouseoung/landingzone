/*
    AWS Credentials 제공자
    AWS CLI 설정에서 설정한 Profile 명을 사용하여 작성 함. (~/.aws/credentials or ~/.aws/config)
*/
provider "aws" {
    profile = "Profile Name"
    region = "ap-northeast-2"
}
 
/*
    조직 설정 활성화 및 조직에서 사용할 기능에 대한 엑세스 정의
*/
resource "aws_organizations_organization" "org" {
    aws_service_access_principals = [
        "backup.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "compute-optimizer.amazonaws.com",
        "config.amazonaws.com",
        "ds.amazonaws.com",
        "fms.amazonaws.com",
        "member.org.stacksets.cloudformation.amazonaws.com",
        "ram.amazonaws.com",
        "servicecatalog.amazonaws.com",
        "ssm.amazonaws.com",
        "sso.amazonaws.com",
        "storage-lens.s3.amazonaws.com",
        "tagpolicies.tag.amazonaws.com"
    ]
 
    enabled_policy_types = [
        "SERVICE_CONTROL_POLICY",
        "TAG_POLICY"
    ]
 
    feature_set = "ALL"
}
 
/*
    조직 하위 단위(OU) 생성
*/
resource "aws_organizations_organizational_unit" "BaseOU" {
    name      = "Base OU"
    parent_id = aws_organizations_organization.org.roots[0].id
}
 
resource "aws_organizations_organizational_unit" "ServiceOU" {
    name      = "Service OU"
    parent_id = aws_organizations_organization.org.roots[0].id
}
 
resource "aws_organizations_organizational_unit" "AServiceOU" {
    name      = "A ServiceOU"
    parent_id = aws_organizations_organizational_unit.ServiceOU.id
}
 
resource "aws_organizations_organizational_unit" "BServiceOU" {
    name      = "B ServiceOU"
    parent_id = aws_organizations_organizational_unit.ServiceOU.id
}
 
 
 
/*
    SCP 정책 정의
*/
resource "aws_organizations_policy" "BaseOUsSCP" {
    name = "Base OUs SCP"
    type = "SERVICE_CONTROL_POLICY"
    description = "Base OUs SCP Access Policy"
    content = <<-CONTENT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Statement1",
                "Effect": "Deny",
                "Action": [
                    "aws-portal:ModifyBilling",
                    "aws-portal:ModifyPaymentMethods"
                ],
                "Resource": [
                    "*"
                ]
            }
        ]
    }
    CONTENT
 
    tags = {}
}
 
resource "aws_organizations_policy" "ServiceOUsSCP" {
    name = "Service OUs"
    type = "SERVICE_CONTROL_POLICY"
    description = "Service OUs Access Policy"
    content = <<-CONTENT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Statement1",
                "Effect": "Deny",
                "Action": [
                    "aws-portal:ModifyAccount",
                    "aws-portal:ModifyBilling",
                    "aws-portal:ModifyPaymentMethods",
                    "aws-portal:ViewPaymentMethods"
                ],
                "Resource": [
                    "*"
                ]
            }
        ]
    }
    CONTENT
 
    tags = {}
}
   
/*
    OU에 대한 SCP 정책 연결
*/
resource "aws_organizations_policy_attachment" "BaseOUs" {
    policy_id = aws_organizations_policy.BaseOUsSCP.id
    target_id = aws_organizations_organizational_unit.BaseOU.id
}
 
resource "aws_organizations_policy_attachment" "ServiceOUs" {
    policy_id = aws_organizations_policy.ServicesOUSCP.id
    target_id = aws_organizations_organizational_unit.ServiceOU.id
}
 
resource "aws_organizations_policy_attachment" "AServiceOU" {
    policy_id = aws_organizations_policy.ServicesOUSCP.id
    target_id = aws_organizations_organizational_unit.AServiceOU.id
}
 
resource "aws_organizations_policy_attachment" "BServiceOU" {
    policy_id = aws_organizations_policy.ServicesOUSCP.id
    target_id = aws_organizations_organizational_unit.BServiceOU.id
}
 
 
/*
    조직 하위 계정 생성
*/
resource "aws_organizations_account" "Production" {
    name  = "Production Account"
    email = "production@test.com"
    parent_id = aws_organizations_organizational_unit.AServiceOU.id
    role_name = "OrganizationAccountAccessRole"
 
    lifecycle {
        ignore_changes = [role_name]
    }
}
 
resource "aws_organizations_account" "Development" {
    name  = "Development Account"
    email = "production@test.com"
    parent_id = aws_organizations_organizational_unit.BServiceOU.id
    role_name = "OrganizationAccountAccessRole"
 
    lifecycle {
        ignore_changes = [role_name]
    }
}