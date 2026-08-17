"""Password hashing utilities."""
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

# Industry-standard Argon2id parameters
_hasher = PasswordHasher(
    time_cost=2,
    memory_cost=65536,
    parallelism=4,
    hash_len=32,
    salt_len=16,
)


def hash_password(password: str) -> str:
    """Hash a password using Argon2id."""
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    """Verify a password against its hash."""
    try:
        _hasher.verify(password_hash, password)
        return True
    except VerifyMismatchError:
        return False


def needs_rehash(password_hash: str) -> bool:
    """Check if hash uses outdated parameters."""
    return _hasher.check_needs_rehash(password_hash)
