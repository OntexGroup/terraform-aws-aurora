# tf-aws-aurora

AWS Aurora DB Cluster & Instance(s) Terraform Module.

Gives you:

 - A DB subnet group
 - An Aurora DB cluster
 - An Aurora DB instance + 'n' number of additional instances
 - Optionally RDS 'Enhanced Monitoring' + associated required IAM role/policy (by simply setting the `monitoring_interval` param to > `0`
 - Optionally sensible alarms to SNS (high CPU, high connections, slow replication)
 - Optionally configure autoscaling for read replicas (MySQL clusters only)

## Contributing

Ensure any variables you add have a type and a description.
This README is generated with [terraform-docs](https://github.com/segmentio/terraform-docs):

`terraform-docs md . > README.md`

## Usage examples

*It is recommended you always create a parameter group, even if it exactly matches the defaults.*
Changing the parameter group in use requires a restart of the DB cluster, modifying parameters within a group
may not (depending on the parameter being altered)

## Known issues
AWS doesn't automatically remove RDS instances created from autoscaling when you remove the autoscaling rules and this can cause issues when using Terraform to destroy the cluster.  To work around this, you should make sure there are no automatically created RDS instances running before attempting to destroy a cluster.

## Breaking changes

* As of version 5.0.0 of the module all name are construct with an id, using, env, role and project.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| apply\_immediately | Determines whether or not any DB modifications are applied immediately, or during the maintenance window | `string` | `"false"` | no |
| auto\_minor\_version\_upgrade | Determines whether minor engine upgrades will be performed automatically in the maintenance window | `string` | `"true"` | no |
| aws | aws region parameters | `map` | `{}` | no |
| azs | List of AZs to use | `list(string)` | n/a | yes |
| backup\_retention\_period | How long to keep backups for (in days) | `string` | `"7"` | no |
| custom\_tags | A list of custom tags to add to the resource | `map` | `{}` | no |
| cw\_alarms | Whether to enable CloudWatch alarms - requires `cw_sns_topic` is specified | `string` | `false` | no |
| cw\_eval\_period\_connections | Evaluation period for the DB connections alarms | `string` | `"1"` | no |
| cw\_eval\_period\_cpu | Evaluation period for the DB CPU alarms | `string` | `"2"` | no |
| cw\_eval\_period\_replica\_lag | Evaluation period for the DB replica lag alarm | `string` | `"5"` | no |
| cw\_max\_conns | Connection count beyond which to trigger a CloudWatch alarm | `string` | `"500"` | no |
| cw\_max\_cpu | CPU threshold above which to alarm | `string` | `"85"` | no |
| cw\_max\_replica\_lag | Maximum Aurora replica lag in milliseconds above which to alarm | `string` | `"2000"` | no |
| cw\_sns\_topic | An SNS topic to publish CloudWatch alarms to | `string` | `"false"` | no |
| db\_cluster\_parameter\_group\_name | The name of a DB Cluster parameter group to use | `string` | `"default.aurora5.6"` | no |
| db\_parameter\_group\_name | The name of a DB parameter group to use | `string` | `"default.aurora5.6"` | no |
| deletion\_protection | If the DB instance should have deletion protection enabled | `bool` | `false` | no |
| enable\_cloudwatch\_logs\_exports | List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported | `list(string)` | <pre>[<br>  "error"<br>]<br></pre> | no |
| enable\_general\_log | This value will enable general log to cloudwatch for the cluster | `bool` | `false` | no |
| enable\_slow\_query\_log | This value will enable slow query log to cloudwatch for the cluster | `bool` | `false` | no |
| enabled | Whether the database resources should be created | `string` | `true` | no |
| engine | Aurora database engine type, currently aurora, aurora-mysql or aurora-postgresql | `string` | `"aurora-mysql"` | no |
| engine\_family | Amazon RDS Instance Types | `string` | `"db.t2.small"` | no |
| engine\_version | Aurora database engine version. | `string` | `"5.7.mysql_aurora.2.04.4"` | no |
| env | Environment type (eg,prod or nonprod) | `string` | n/a | yes |
| family | Instance family for the db parameters group | `string` | `"aurora-mysql5.7"` | no |
| final\_snapshot\_identifier | The name to use when creating a final snapshot on cluster destroy, appends a random 8 digits to name to ensure it's unique too. | `string` | `"final"` | no |
| iam\_database\_authentication\_enabled | Whether to enable IAM database authentication for the RDS Cluster | `string` | `false` | no |
| identifier\_prefix | Prefix for cluster and instance identifier | `string` | `""` | no |
| instance\_type | Instance type to use | `string` | `"db.t2.small"` | no |
| monitoring\_interval | The interval (seconds) between points when Enhanced Monitoring metrics are collected | `string` | `0` | no |
| namespace | Company owning the aws account | `string` | `"ontex"` | no |
| password | Master DB password | `string` | n/a | yes |
| performance\_insights\_enabled | Whether to enable Performance Insights | `string` | `false` | no |
| port | The port on which to accept connections | `string` | `"3306"` | no |
| preferred\_backup\_window | When to perform DB backups | `string` | `"02:00-03:00"` | no |
| preferred\_maintenance\_window | When to perform DB maintenance | `string` | `"sun:05:00-sun:06:00"` | no |
| project | Used to identify the project(s) the resource supports | `string` | n/a | yes |
| publicly\_accessible | Whether the DB should have a public IP address | `string` | `"false"` | no |
| replica\_count | Number of reader nodes to create.  If `replica_scale_enable` is `true`, the value of `replica_scale_min` is used instead. | `string` | `"0"` | no |
| replica\_scale\_cpu | CPU usage to trigger autoscaling at | `string` | `"70"` | no |
| replica\_scale\_enabled | Whether to enable autoscaling for RDS Aurora (MySQL) read replicas | `string` | `false` | no |
| replica\_scale\_in\_cooldown | Cooldown in seconds before allowing further scaling operations after a scale in | `string` | `"300"` | no |
| replica\_scale\_max | Maximum number of replicas to allow scaling for | `string` | `"0"` | no |
| replica\_scale\_min | Maximum number of replicas to allow scaling for | `string` | `"2"` | no |
| replica\_scale\_out\_cooldown | Cooldown in seconds before allowing further scaling operations after a scale out | `string` | `"300"` | no |
| security\_groups | VPC Security Group IDs | `list(string)` | n/a | yes |
| skip\_final\_snapshot | Should a final snapshot be created on cluster destroy | `string` | `"false"` | no |
| snapshot\_identifier | DB snapshot to create this database from | `string` | `""` | no |
| storage\_encrypted | Specifies whether the underlying storage layer should be encrypted | `string` | `"true"` | no |
| subnets | List of subnet IDs to use | `list(string)` | n/a | yes |
| username | Master DB username | `string` | `"root"` | no |
| vpc\_id | VPC id for the vpc | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| all\_instance\_endpoints\_list | Aurora endpoint(s). |
| cluster\_endpoint | The 'writer' endpoint for the cluster |
| cluster\_identifier | Aurora identifier id. |
| cluster\_security\_group\_id | Security group id attach to the aurora cluster. |
| db\_master\_password | Aurora master password. |
| db\_master\_user | Aurora master user. |
| reader\_endpoint | Aurora reader endpoint. |

