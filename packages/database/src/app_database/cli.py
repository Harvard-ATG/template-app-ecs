"""CLI for database operations."""
import os
from pathlib import Path

import typer

app = typer.Typer(help="Database management commands")


def get_alembic_config():
    """Get Alembic config with correct path."""
    from alembic.config import Config
    
    # Find alembic.ini - check current dir first, then package dir
    config_path = Path("alembic.ini")
    if not config_path.exists():
        # Try from package directory
        package_dir = Path(__file__).parent.parent.parent.parent
        config_path = package_dir / "alembic.ini"
    
    if not config_path.exists():
        typer.echo(f"Error: alembic.ini not found", err=True)
        raise typer.Exit(1)
    
    return Config(str(config_path))


@app.command()
def upgrade(revision: str = "head"):
    """Upgrade database to a later version."""
    from alembic import command
    
    config = get_alembic_config()
    command.upgrade(config, revision)
    typer.echo(f"✓ Upgraded to {revision}")


@app.command()
def downgrade(revision: str = "-1"):
    """Revert database to a previous version."""
    from alembic import command
    
    config = get_alembic_config()
    command.downgrade(config, revision)
    typer.echo(f"✓ Downgraded to {revision}")


@app.command()
def revision(message: str, autogenerate: bool = True):
    """Create a new migration."""
    from alembic import command
    
    config = get_alembic_config()
    command.revision(config, message=message, autogenerate=autogenerate)
    typer.echo(f"✓ Created migration: {message}")


if __name__ == "__main__":
    app()
