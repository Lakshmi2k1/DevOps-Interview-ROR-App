# Single-AZ Postgres in the private subnets, reachable only from the EKS
# nodes. Master password is auto-generated and lives in Secrets Manager,
# never in code.

resource "random_password" "db" {
  length  = 20
  special = true
  # RDS does not allow these characters in the master password.
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${local.name}/rds/credentials"
  description = "Master credentials for the ${local.name} RDS PostgreSQL instance"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
    host     = aws_db_instance.this.address
    port     = var.db_port
  })
}

resource "aws_security_group" "db" {
  name        = "${local.name}-rds-sg"
  description = "Allow PostgreSQL access from the EKS worker nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-rds-sg" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnets"
  subnet_ids = module.vpc.private_subnets
  tags       = merge(local.tags, { Name = "${local.name}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name}-postgres"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = merge(local.tags, { Name = "${local.name}-postgres" })
}
