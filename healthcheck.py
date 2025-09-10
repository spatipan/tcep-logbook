# healthcheck.py - Simple health check endpoint for container monitoring
from flask import Flask, jsonify
from datetime import datetime
import threading
import time
import os

app = Flask(__name__)

# Global health status
health_status = {
    'status': 'healthy',
    'timestamp': datetime.utcnow().isoformat(),
    'services': {
        'database': 'unknown',
        'scheduler': 'unknown',
        'dashboard': 'unknown'
    }
}

def check_services():
    """Background thread to check service health"""
    while True:
        try:
            # Check database connection
            from database import db_manager
            with db_manager.get_session() as session:
                session.execute("SELECT 1")
            health_status['services']['database'] = 'healthy'
        except Exception as e:
            health_status['services']['database'] = f'unhealthy: {str(e)[:100]}'
        
        # Check if scheduler process is running (simple file-based check)
        scheduler_pid_file = '/tmp/scheduler.pid'
        if os.path.exists(scheduler_pid_file):
            health_status['services']['scheduler'] = 'healthy'
        else:
            health_status['services']['scheduler'] = 'unknown'
        
        # Check if dashboard is accessible
        try:
            import requests
            response = requests.get('http://localhost:8080', timeout=5)
            if response.status_code == 200:
                health_status['services']['dashboard'] = 'healthy'
            else:
                health_status['services']['dashboard'] = f'unhealthy: HTTP {response.status_code}'
        except Exception as e:
            health_status['services']['dashboard'] = f'unhealthy: {str(e)[:100]}'
        
        # Update overall status
        unhealthy_services = [k for k, v in health_status['services'].items() if 'unhealthy' in str(v)]
        health_status['status'] = 'unhealthy' if unhealthy_services else 'healthy'
        health_status['timestamp'] = datetime.utcnow().isoformat()
        
        time.sleep(30)  # Check every 30 seconds

@app.route('/health')
def health():
    """Health check endpoint"""
    status_code = 200 if health_status['status'] == 'healthy' else 503
    return jsonify(health_status), status_code

@app.route('/health/ready')
def ready():
    """Readiness check - all services must be healthy"""
    if health_status['status'] == 'healthy':
        return jsonify({'status': 'ready'}), 200
    else:
        return jsonify({'status': 'not ready', 'details': health_status}), 503

@app.route('/health/live')
def live():
    """Liveness check - basic application responsiveness"""
    return jsonify({
        'status': 'alive',
        'timestamp': datetime.utcnow().isoformat()
    }), 200

if __name__ == '__main__':
    # Start background health checker
    health_thread = threading.Thread(target=check_services, daemon=True)
    health_thread.start()
    
    # Start Flask app
    app.run(host='0.0.0.0', port=8081, debug=False)