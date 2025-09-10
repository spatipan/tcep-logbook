#!/bin/bash
# start.sh - Container startup script

set -e

echo "Starting TCEP Logbook Application..."

# Wait for database to be ready
echo "Waiting for database connection..."
python -c "
import time
import sys
from database import db_manager

max_retries = 30
for i in range(max_retries):
    try:
        db_manager.create_tables()
        print('Database connection successful!')
        break
    except Exception as e:
        if i == max_retries - 1:
            print(f'Failed to connect to database after {max_retries} attempts: {e}')
            sys.exit(1)
        print(f'Database connection attempt {i+1} failed, retrying in 5 seconds...')
        time.sleep(5)
"

# Start health check endpoint in background
echo "Starting health check endpoint..."
python healthcheck.py &
HEALTHCHECK_PID=$!

# Start scheduler in background
echo "Starting scraper scheduler..."
python scheduler.py &
SCHEDULER_PID=$!

# Start dashboard
echo "Starting dashboard..."
streamlit run dashboard.py --server.port=8080 --server.address=0.0.0.0 --server.headless=true &
DASHBOARD_PID=$!

# Function to handle shutdown
shutdown() {
    echo "Shutting down services..."
    kill $HEALTHCHECK_PID $SCHEDULER_PID $DASHBOARD_PID 2>/dev/null
    wait $HEALTHCHECK_PID $SCHEDULER_PID $DASHBOARD_PID 2>/dev/null
    echo "All services stopped."
    exit 0
}

# Trap signals
trap shutdown SIGTERM SIGINT

# Wait for any process to exit
wait -n

# If we get here, one of the processes exited, so shutdown everything
shutdown