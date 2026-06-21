import os
import subprocess
import sys

port = os.environ.get('PORT', '8000')

# Run migrations first
subprocess.run([sys.executable, 'manage.py', 'migrate', '--noinput'], check=True)

# Start daphne with the correct port
os.execv(
    sys.executable,
    [sys.executable, '-m', 'daphne', '-b', '0.0.0.0', '-p', port, 'core.asgi:application']
)