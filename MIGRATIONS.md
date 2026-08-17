# Database Migrations Guide

This guide explains how to manage database migrations in both local development and AWS ECS production environments.

## Overview

Database migrations use Alembic and are run as **separate, one-time tasks** rather than on every container startup. This prevents race conditions, improves startup time, and provides better deployment control.

## Local Development

### Running Migrations

```bash
# Start database
docker-compose up -d postgres

# Run migrations
docker-compose exec api app-migrate upgrade head

# Or with docker-compose command override
docker-compose run --rm api migrate
```

### Creating New Migrations

```bash
# Auto-generate migration from model changes
docker-compose exec api app-migrate revision "add user profiles" --autogenerate

# Create empty migration for manual changes
docker-compose exec api app-migrate revision "add custom index" --no-autogenerate
```

### Rollback Migrations

```bash
# Rollback last migration
docker-compose exec api app-migrate downgrade -1

# Rollback to specific revision
docker-compose exec api app-migrate downgrade abc123
```

## Production (AWS ECS)

### Architecture

The migration system uses:
- **Separate ECS Task Definition**: Dedicated task that runs `app-migrate upgrade head`
- **Same Docker Image**: Uses the same API image with a different command
- **One-time Execution**: Triggered manually or via CI/CD before deploying new API containers

### Running Migrations Manually

**Option 1: Using the helper script** (Recommended)
```bash
cd infrastructure
./scripts/run-migrations.sh prod
```

**Option 2: Using AWS CLI directly**
```bash
# Get the migration command from Terraform
cd infrastructure
terraform output migration_command

# Copy and run the command
aws ecs run-task \
  --cluster my-app-prod \
  --task-definition my-app-prod-migration:5 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=DISABLED}"
```

**Option 3: Using AWS Console**
1. Go to ECS → Clusters → your cluster
2. Click "Run new task"
3. Select:
   - Launch type: FARGATE
   - Task definition: `my-app-prod-migration` (latest)
   - Cluster VPC and private subnets
   - Existing security group
4. Click "Run Task"
5. Monitor in CloudWatch Logs: `/ecs/my-app-prod/api`

### CI/CD Integration

#### GitHub Actions Example

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      # Build and push Docker image
      - name: Build and push API image
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_REGISTRY
          docker build -t $ECR_REGISTRY/api:$GITHUB_SHA -f packages/api/Dockerfile .
          docker push $ECR_REGISTRY/api:$GITHUB_SHA
      
      # Run database migrations BEFORE updating service
      - name: Run database migrations
        run: |
          TASK_ARN=$(aws ecs run-task \
            --cluster my-app-prod \
            --task-definition my-app-prod-migration \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" \
            --query 'tasks[0].taskArn' \
            --output text)
          
          echo "Waiting for migrations to complete..."
          aws ecs wait tasks-stopped --cluster my-app-prod --tasks "$TASK_ARN"
          
          EXIT_CODE=$(aws ecs describe-tasks \
            --cluster my-app-prod \
            --tasks "$TASK_ARN" \
            --query 'tasks[0].containers[0].exitCode' \
            --output text)
          
          if [ "$EXIT_CODE" != "0" ]; then
            echo "Migration failed!"
            exit 1
          fi
      
      # Update ECS service with new image
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster my-app-prod \
            --service my-app-prod-api \
            --force-new-deployment
```

#### GitLab CI Example

```yaml
deploy:
  stage: deploy
  script:
    # Build and push image
    - docker build -t $ECR_REGISTRY/api:$CI_COMMIT_SHA -f packages/api/Dockerfile .
    - docker push $ECR_REGISTRY/api:$CI_COMMIT_SHA
    
    # Run migrations
    - |
      TASK_ARN=$(aws ecs run-task \
        --cluster my-app-prod \
        --task-definition my-app-prod-migration \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" \
        --query 'tasks[0].taskArn' \
        --output text)
      aws ecs wait tasks-stopped --cluster my-app-prod --tasks "$TASK_ARN"
    
    # Deploy new version
    - aws ecs update-service --cluster my-app-prod --service my-app-prod-api --force-new-deployment
```

## Monitoring and Troubleshooting

### View Migration Logs

```bash
# Real-time logs
aws logs tail /ecs/my-app-prod/api --filter-pattern migration --follow

# Recent logs
aws logs tail /ecs/my-app-prod/api --filter-pattern migration --since 1h
```

### Check Migration Status

```bash
# List recent migration tasks
aws ecs list-tasks \
  --cluster my-app-prod \
  --family my-app-prod-migration

# Describe specific task
aws ecs describe-tasks \
  --cluster my-app-prod \
  --tasks <task-arn>
```

### Common Issues

**Migration task fails to start:**
- Check security group allows outbound traffic
- Verify subnets have internet access (NAT Gateway) for ECR pulls
- Confirm IAM roles have required permissions

**Migration hangs:**
- Check database connection (security groups, RDS availability)
- Look for migration lock conflicts (manual intervention may be needed)

**Migration fails:**
- Review CloudWatch logs for error messages
- Connect to RDS and check `alembic_version` table
- May need to manually fix and re-run

## Best Practices

1. **Always run migrations before deploying new code**
   - Use CI/CD to enforce this order
   - Migrations should be backward-compatible with current code

2. **Test migrations in staging first**
   - Run against a copy of production data
   - Measure migration time for large tables

3. **Make migrations reversible**
   - Always implement `downgrade()` functions
   - Test rollback procedures

4. **Monitor migration execution**
   - Set up CloudWatch alarms for failed migrations
   - Include migration status in deployment notifications

5. **Handle long-running migrations**
   - For large data migrations, consider:
     - Running during low-traffic periods
     - Using online schema change tools
     - Splitting into multiple smaller migrations

## Migration File Structure

```
packages/database/
├── alembic.ini              # Alembic configuration
├── src/app_database/
│   ├── cli.py              # Migration CLI (app-migrate command)
│   └── migrations/
│       ├── env.py          # Alembic environment
│       └── versions/       # Migration files
│           └── 001_initial.py
```

## Environment Variables

Migrations use the same database configuration as the API:
- `APP_DB_HOST` - Database hostname
- `APP_DB_PORT` - Database port (default: 5432)
- `APP_DB_NAME` - Database name
- `APP_DB_USER` - Database username
- `APP_DB_PASSWORD` - Database password

## Security

- Database password stored in AWS Secrets Manager
- Migration task has minimal IAM permissions (no service deployment access)
- Migration logs are retained for 30 days in CloudWatch
- No sensitive data should be logged during migrations

## Further Reading

- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [ECS Run Task API](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_RunTask.html)
- [AWS Database Migration Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/migration-database-best-practices/)
