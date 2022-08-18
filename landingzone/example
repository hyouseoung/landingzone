/*
    EC2 인스턴스에 대한 AMI 백업 생성
*/
resource "aws_ami_from_instance" "CreateAMIFromEC2Instance" {
    name               = "CreateAMIFromEC2Instance"
    source_instance_id = "i-0c68929dcd96f2405"     // EC2 인스턴스 수동 생성후 기입 
    snapshot_without_reboot = false
    tags = {
        "key" = "value"
    }
}



/*
    EBS Volume Snapshot 백업 생성
*/
data "aws_ebs_volume" "ebs_volume" {
    most_recent = true

    filter {
        name   = "volume-type"
        values = ["gp2"]
    }

    filter {
        name   = "tag:Name"             // Name : Example 태그로 EBS 볼륨 생성 
        values = ["Example"]
    }
}

resource "aws_ebs_snapshot" "CreateSnapshotForEBSVolume" {
    volume_id = data.aws_ebs_volume.ebs_volume.id
    description = "Created Snapshot from ${data.aws_ebs_volume.ebs_volume.id}"

    // Volume Tag 복사
    tags = data.aws_ebs_volume.ebs_volume.tags
}



/*
    RDS Snapshot 백업 생성
*/
data "aws_db_instance" "database" {
    db_instance_identifier = "mytestdb-instance-1"             // db 인스턴스 ID  
}

resource "aws_db_snapshot" "test" {
    db_instance_identifier = data.aws_db_instance.database.id
    db_snapshot_identifier = "testsnapshot1234"
    tags = {
        "key" = "value"
    }
}



/*
    AWS Backup을 통한 EC2 백업
*/
resource "aws_backup_vault" "EC2DailyBackupVault" {
    name        = "EC2_Daily_Backup_Vault"
    tags = {
        "key" = "value"
    }
}

resource "aws_backup_vault" "EC2MonthlyBackupVault" {
    name        = "EC2_Monthly_Backup_Vault"
    tags = {
        "key" = "value"
    }
}

resource "aws_backup_plan" "EC2BackupPlan" {
    name = "Daily_EC2_Backup_Plan"

    rule {
        rule_name         = "DailyBackup"
        target_vault_name = aws_backup_vault.EC2DailyBackupVault.name
        schedule          = "cron(0 12 * * ? *)"
    }

    rule {
        rule_name         = "MonthlyBackup"
        target_vault_name = aws_backup_vault.EC2MonthlyBackupVault.name
        schedule          = "cron(0 12 1 * ? *)"
    }

}

// 백업을 위한 IAM Role은 사전에 생성 되어있어야 함.
data "aws_iam_role" "BackupRole" {
    name = "Role_for_AWS_Backup"                // 해당이름으로 role 생성 
}

// Tag를 기반으로 자원 선택
resource "aws_backup_selection" "TagSelection" {
    iam_role_arn = data.aws_iam_role.BackupRole.arn
    name         = "EC2_Tag_base_selection"
    plan_id      = aws_backup_plan.EC2BackupPlan.id

    selection_tag {
        type  = "STRINGEQUALS"
        key   = "foo"
        value = "bar"
    }
}

data "aws_instance" "EC2InstanceForBackup" {
    instance_id = "i-0c68929dcd96f2405"                     // ec2 인스턴스 id 값 
}

// Resource ARN 기반으로 자원 선택
resource "aws_backup_selection" "ResourceIDSelection" {
    iam_role_arn = data.aws_iam_role.BackupRole.arn
    name         = "Resource_ID_Selection"
    plan_id      = aws_backup_plan.EC2BackupPlan.id

    resources = [
        data.aws_instance.EC2InstanceForBackup.arn
    ]
}