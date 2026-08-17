#!/usr/bin/env python3
"""
Run database migrations for template-app-ecs.

Usage:
    ./run_migration.py dev
    ./run_migration.py prod
"""

# /// script
# dependencies = ["boto3"]
# ///

import sys
import boto3


def get_network_config(ecs, cluster_name, service_name):
    """Extract network configuration from the running ECS service."""
    response = ecs.describe_services(
        cluster=cluster_name,
        services=[service_name]
    )
    
    if not response['services']:
        raise Exception(f"Service {service_name} not found in cluster {cluster_name}")
    
    service = response['services'][0]
    network_config = service['networkConfiguration']['awsvpcConfiguration']
    
    return {
        'awsvpcConfiguration': {
            'subnets': network_config['subnets'],
            'securityGroups': network_config['securityGroups'],
            'assignPublicIp': 'DISABLED'
        }
    }


def run_migration_task(env):
    """Run the migration task in the specified environment."""
    app_name = "template-app-ecs"
    
    ecs = boto3.client('ecs', region_name='us-east-1')
    
    # Get cluster and task definition from the running service
    cluster_name = f"atg-{env}"
    service_name = f"atg-{app_name}-api-{env}"
    migration_task_def = f"atg-{app_name}-{env}-migration"
    
    print(f"Running migration for {env} environment...")
    print(f"  Cluster: {cluster_name}")
    print(f"  Task definition: {migration_task_def}")
    print()
    
    # Get network config from service
    network_config = get_network_config(ecs, cluster_name, service_name)
    
    # Run the migration task
    response = ecs.run_task(
        cluster=cluster_name,
        taskDefinition=migration_task_def,
        launchType='FARGATE',
        networkConfiguration=network_config
    )
    
    if response['tasks']:
        task_arn = response['tasks'][0]['taskArn']
        task_id = task_arn.split('/')[-1]
        print(f"✓ Migration task started: {task_id}")
        print()
        print("Monitor logs in Splunk:")
        print(f"  index=soc-isites source=atg-{app_name}-{env}")
        print()
        print("Or check ECS console:")
        print(f"  https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/{cluster_name}/tasks/{task_id}/details")
    else:
        print("✗ Failed to start migration task")
        if response['failures']:
            for failure in response['failures']:
                print(f"  Reason: {failure['reason']}")
        sys.exit(1)


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ['dev', 'prod']:
        print(__doc__)
        sys.exit(1)
    
    env = sys.argv[1]
    
    try:
        run_migration_task(env)
    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
