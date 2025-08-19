#!/bin/bash


# ----------------------------------------
# Local Variables
# ----------------------------------------
# Cache directory for mock projects
MOCK_CACHE_DIR="/tmp/riso-mock-cache"
mkdir -p "$MOCK_CACHE_DIR"

# ----------------------------------------
# utils/layer-0/mock-generator.sh - Generate mock files for testing
# ----------------------------------------
# Main entry point for all mock generation
generate_mock_project() {
    local project_type="$1"  # bash|python|nodejs|template|combo
    local variant="$2"       # devcontainer|flask|express|cookiecutter|etc
    local output_path="$3"   # Where to generate
    local options="$4"       # Additional options (comma-separated)

    echo "Generating mock $project_type project (variant: $variant) at $output_path" >&2

    mkdir -p "$output_path"

    case "$project_type" in
        "bash") generate_mock_bash_project "$variant" "$output_path" "$options" ;;
        "python") generate_mock_python_project_variant "$variant" "$output_path" "$options" ;;
        "nodejs") generate_mock_nodejs_project "$variant" "$output_path" "$options" ;;
        "template") generate_mock_template_project "$variant" "$output_path" "$options" ;;
        "combo") generate_mock_combo_project "$variant" "$output_path" "$options" ;;
        *) echo "Unknown project type: $project_type" >&2; return 1 ;;
    esac

    # Generate common files
    generate_common_files "$output_path" "$(basename "$output_path")"

    echo "Mock project generated successfully at $output_path" >&2
}

# Bash Project Generator
generate_mock_bash_project() {
    local variant="$1"
    local output_path="$2"
    local options="$3"

    case "$variant" in
        "devcontainer") generate_mock_devcontainer_feature "$output_path" ;;
        "scripts") generate_mock_bash_scripts "$output_path" ;;
        *) echo "Unknown bash variant: $variant" >&2; return 1 ;;
    esac
}

# DevContainer Feature Generator
generate_mock_devcontainer_feature() {
    local project_path="$1"

    # Create devcontainer-feature.json
    cat > "$project_path/devcontainer-feature.json" << 'EOF'
{
    "id": "test-feature",
    "version": "1.0.0",
    "name": "Test DevContainer Feature",
    "description": "A mock feature for testing riso-bootstrap scanning",
    "options": {
        "version": {
            "type": "string",
            "proposals": ["latest", "1.0", "2.0"],
            "default": "latest",
            "description": "Version to install"
        },
        "enableFeature": {
            "type": "boolean",
            "default": true,
            "description": "Enable the test feature"
        }
    },
    "installsAfter": [
        "ghcr.io/devcontainers/features/common-utils"
    ]
}
EOF

    # Create install.sh
    cat > "$project_path/install.sh" << 'EOF'
#!/bin/bash
set -e

# Parse options
VERSION=${VERSION:-"latest"}
ENABLE_FEATURE=${ENABLEFEATURE:-"true"}

echo "Installing test feature version: $VERSION"
echo "Feature enabled: $ENABLE_FEATURE"

# Mock installation commands
if command -v apt-get >/dev/null 2>&1; then
    echo "Installing dependencies via apt..."
    # apt-get update && apt-get install -y curl wget
fi

# Create test executable
mkdir -p /usr/local/bin
cat > /usr/local/bin/test-feature << 'INNER_EOF'
#!/bin/bash
echo "Test feature is working! Version: $VERSION"
INNER_EOF
chmod +x /usr/local/bin/test-feature

echo "Test feature installation completed"
EOF

    # Create test scenarios
    mkdir -p "$project_path/test"
    cat > "$project_path/test/test.sh" << 'EOF'
#!/bin/bash
set -e

# Test the feature installation
source dev-container-features-test-lib

check "test-feature command exists" test-feature
check "test-feature version output" bash -c "test-feature | grep -q 'Version:'"

reportResults
EOF

    # Create utility scripts
    mkdir -p "$project_path/utils"
    cat > "$project_path/utils/helper.sh" << 'EOF'
#!/bin/bash

# Helper functions for test feature

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_dependency() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required dependency not found: $cmd"
        return 1
    fi
    log_info "Dependency found: $cmd"
}
EOF
}

# Bash Project Generator
generate_mock_bash_scripts() {
    local project_path="$1"

    # Create main script
    cat > "$project_path/main.sh" << 'EOF'
#!/bin/bash
set -e

# Source utilities
source "$(dirname "$0")/utils/common.sh"

main() {
    log_info "Starting main script"

    # Process arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v) VERBOSE=true; shift ;;
            --help|-h) show_help; exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    # Main logic
    process_data
    cleanup

    log_info "Script completed successfully"
}

show_help() {
    cat << 'HELP_EOF'
Usage: main.sh [OPTIONS]

Options:
    -v, --verbose    Enable verbose output
    -h, --help       Show this help message

HELP_EOF
}

process_data() {
    log_info "Processing data..."

    # Mock data processing
    local data_files=(data1.txt data2.txt data3.txt)
    for file in "${data_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_info "Processing $file"
            wc -l "$file"
        fi
    done
}

cleanup() {
    log_info "Cleaning up temporary files..."
    # Mock cleanup
}

main "$@"
EOF

    # Create utilities
    mkdir -p "$project_path/utils"
    cat > "$project_path/utils/common.sh" << 'EOF'
#!/bin/bash

# Common utilities

VERBOSE=${VERBOSE:-false}

log_info() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2
    fi
}
EOF
}

# Python Project Generator
generate_mock_python_project_variant() {
    local variant="$1"
    local output_path="$2"
    local options="$3"

    case "$variant" in
        "simple") generate_mock_python_project "$output_path" ;;
        "flask") generate_mock_flask_api "$output_path" ;;
        "django") generate_mock_django_app "$output_path" ;;
        "fastapi") generate_mock_fastapi_service "$output_path" ;;
        *) echo "Unknown python variant: $variant" >&2; return 1 ;;
    esac
}

# Flask API Generator
generate_mock_flask_api() {
    local project_path="$1"

    # Create Flask app
    cat > "$project_path/app.py" << 'EOF'
#!/usr/bin/env python3
"""Flask API mock project"""

from flask import Flask, jsonify, request
from typing import Dict, List
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

# Mock data store
users: List[Dict] = [
    {"id": 1, "name": "John Doe", "email": "john@example.com"},
    {"id": 2, "name": "Jane Smith", "email": "jane@example.com"}
]

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users"""
    return jsonify({"users": users, "count": len(users)})

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id: int):
    """Get user by ID"""
    user = next((u for u in users if u["id"] == user_id), None)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user)

@app.route('/api/users', methods=['POST'])
def create_user():
    """Create new user"""
    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({"error": "Name is required"}), 400

    new_user = {
        "id": max([u["id"] for u in users]) + 1,
        "name": data["name"],
        "email": data.get("email", "")
    }
    users.append(new_user)
    return jsonify(new_user), 201

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "flask-api"})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
EOF

    # Create requirements.txt
    cat > "$project_path/requirements.txt" << 'EOF'
Flask==2.3.3
pytest==7.4.0
pytest-flask==1.2.0
black==23.7.0
mypy==1.5.0
EOF

    # Create models
    cat > "$project_path/models.py" << 'EOF'
"""Data models for Flask API"""

from dataclasses import dataclass
from typing import Optional

@dataclass
class User:
    id: int
    name: str
    email: Optional[str] = None

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email
        }
EOF

    # Create tests
    mkdir -p "$project_path/tests"
    cat > "$project_path/tests/test_api.py" << 'EOF'
"""Tests for Flask API"""

import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_check(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_get_users(client):
    """Test get all users"""
    response = client.get('/api/users')
    assert response.status_code == 200
    data = response.get_json()
    assert 'users' in data
    assert 'count' in data

def test_get_user_by_id(client):
    """Test get user by ID"""
    response = client.get('/api/users/1')
    assert response.status_code == 200
    data = response.get_json()
    assert data['id'] == 1
EOF
}

# Django Project Generator
generate_mock_django_app() {
    local project_path="$1"

    # Create Django project structure
    mkdir -p "$project_path/myproject"

    # Create settings.py
    cat > "$project_path/myproject/settings.py" << 'EOF'
"""Django settings for mock project"""

SECRET_KEY = 'django-insecure-mock-key-for-testing'
DEBUG = True
ALLOWED_HOSTS = []

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

ROOT_URLCONF = 'myproject.urls'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'db.sqlite3',
    }
}
EOF

    # Create urls.py
    cat > "$project_path/myproject/urls.py" << 'EOF'
"""URL configuration for Django project"""

from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
EOF

    # Create manage.py
    cat > "$project_path/manage.py" << 'EOF'
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myproject.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
EOF

    # Create requirements.txt
    cat > "$project_path/requirements.txt" << 'EOF'
Django==4.2.5
djangorestframework==3.14.0
pytest-django==4.5.2
pytest==7.4.0
EOF
}

# FastAPI Service Generator
generate_mock_fastapi_service() {
    local project_path="$1"

    # Create FastAPI main file
    cat > "$project_path/main.py" << 'EOF'
"""FastAPI service mock project"""

from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

app = FastAPI(title="Mock FastAPI Service", version="1.0.0")

# Pydantic models
class User(BaseModel):
    id: Optional[int] = None
    name: str
    email: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    name: str
    email: Optional[str] = None

# Mock database
users_db: List[UserResponse] = [
    UserResponse(id=1, name="John Doe", email="john@example.com"),
    UserResponse(id=2, name="Jane Smith", email="jane@example.com")
]

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "FastAPI Mock Service", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "fastapi"}

@app.get("/api/users", response_model=List[UserResponse])
async def get_users():
    """Get all users"""
    return users_db

@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """Get user by ID"""
    user = next((u for u in users_db if u.id == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/api/users", response_model=UserResponse)
async def create_user(user: User):
    """Create new user"""
    new_id = max([u.id for u in users_db]) + 1 if users_db else 1
    new_user = UserResponse(id=new_id, name=user.name, email=user.email)
    users_db.append(new_user)
    return new_user

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

    # Create requirements.txt
    cat > "$project_path/requirements.txt" << 'EOF'
fastapi==0.103.1
uvicorn[standard]==0.23.2
pydantic==2.3.0
pytest==7.4.0
httpx==0.24.1
EOF

    # Create tests
    mkdir -p "$project_path/tests"
    cat > "$project_path/tests/test_main.py" << 'EOF'
"""Tests for FastAPI service"""

from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data

def test_health_check():
    """Test health check"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_get_users():
    """Test get users endpoint"""
    response = client.get("/api/users")
    assert response.status_code == 200
    users = response.json()
    assert isinstance(users, list)
EOF
}

# Node.js Project Generator
generate_mock_nodejs_project() {
    local variant="$1"
    local output_path="$2"
    local options="$3"

    case "$variant" in
        "express") generate_mock_express_api "$output_path" ;;
        "react") generate_mock_react_app "$output_path" ;;
        "nextjs") generate_mock_nextjs_app "$output_path" ;;
        "cli") generate_mock_nodejs_cli "$output_path" ;;
        *) echo "Unknown nodejs variant: $variant" >&2; return 1 ;;
    esac
}

# Express API Generator
generate_mock_express_api() {
    local project_path="$1"

    # Create project directory
    mkdir -p "$project_path"

    # Create package.json
    cat > "$project_path/package.json" << 'EOF'
{
  "name": "mock-express-api",
  "version": "1.0.0",
  "description": "Mock Express API for testing",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest",
    "lint": "eslint ."
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.6.2",
    "supertest": "^6.3.3",
    "eslint": "^8.46.0"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF

    # Create server.js
    cat > "$project_path/server.js" << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Mock data
let users = [
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
];

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'Mock Express API',
        version: '1.0.0',
        endpoints: ['/api/users', '/health']
    });
});

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'express-api' });
});

app.get('/api/users', (req, res) => {
    res.json({ users, count: users.length });
});

app.get('/api/users/:id', (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
});

app.post('/api/users', (req, res) => {
    const { name, email } = req.body;
    if (!name) {
        return res.status(400).json({ error: 'Name is required' });
    }

    const newUser = {
        id: Math.max(...users.map(u => u.id)) + 1,
        name,
        email: email || ''
    };
    users.push(newUser);
    res.status(201).json(newUser);
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

module.exports = app;
EOF

    # Create tests
    mkdir -p "$project_path/tests"
    cat > "$project_path/tests/server.test.js" << 'EOF'
const request = require('supertest');
const app = require('../server');

describe('Express API', () => {
    test('GET / should return API info', async () => {
        const response = await request(app).get('/');
        expect(response.status).toBe(200);
        expect(response.body.message).toBe('Mock Express API');
    });

    test('GET /health should return health status', async () => {
        const response = await request(app).get('/health');
        expect(response.status).toBe(200);
        expect(response.body.status).toBe('healthy');
    });

    test('GET /api/users should return users', async () => {
        const response = await request(app).get('/api/users');
        expect(response.status).toBe(200);
        expect(response.body.users).toBeInstanceOf(Array);
    });
});
EOF
}

# React Project Generator
generate_mock_react_app() {
    local project_path="$1"

    # Create project directory
    mkdir -p "$project_path"

    # Create package.json
    cat > "$project_path/package.json" << 'EOF'
{
  "name": "mock-react-app",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.15.0",
    "axios": "^1.4.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "devDependencies": {
    "react-scripts": "5.0.1",
    "@testing-library/jest-dom": "^5.17.0",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^14.4.3"
  },
  "browserslist": {
    "production": [">0.2%", "not dead", "not op_mini all"],
    "development": ["last 1 chrome version", "last 1 firefox version", "last 1 safari version"]
  }
}
EOF

    # Create public/index.html
    mkdir -p "$project_path/public"
    cat > "$project_path/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Mock React App</title>
</head>
<body>
    <div id="root"></div>
</body>
</html>
EOF

    # Create src structure
    mkdir -p "$project_path/src/components"

    # Create src/App.js
    cat > "$project_path/src/App.js" << 'EOF'
import React, { useState, useEffect } from 'react';
import UserList from './components/UserList';
import './App.css';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Mock API call
    setTimeout(() => {
      setUsers([
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ]);
      setLoading(false);
    }, 1000);
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>Mock React App</h1>
        <p>Testing React project scanning</p>
      </header>
      <main>
        {loading ? (
          <p>Loading users...</p>
        ) : (
          <UserList users={users} />
        )}
      </main>
    </div>
  );
}

export default App;
EOF

    # Create src/components/UserList.js
    cat > "$project_path/src/components/UserList.js" << 'EOF'
import React from 'react';

const UserList = ({ users }) => {
  return (
    <div className="user-list">
      <h2>Users</h2>
      {users.map(user => (
        <div key={user.id} className="user-card">
          <h3>{user.name}</h3>
          <p>{user.email}</p>
        </div>
      ))}
    </div>
  );
};

export default UserList;
EOF

    # Create src/index.js
    cat > "$project_path/src/index.js" << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
EOF

    # Create src/App.css
    cat > "$project_path/src/App.css" << 'EOF'
.App {
  text-align: center;
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
  margin-bottom: 20px;
}

.user-list {
  margin-top: 20px;
}

.user-card {
  border: 1px solid #ddd;
  padding: 15px;
  margin: 10px 0;
  border-radius: 5px;
}
EOF
}

# Next.js Project Generator
generate_mock_nextjs_app() {
    local project_path="$1"

    # Create package.json
    cat > "$project_path/package.json" << 'EOF'
{
  "name": "mock-nextjs-app",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "13.4.19",
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "eslint": "^8.46.0",
    "eslint-config-next": "13.4.19"
  }
}
EOF

    # Create next.config.js
    cat > "$project_path/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
}

module.exports = nextConfig
EOF

    # Create pages structure
    mkdir -p "$project_path/pages/api"

    # Create pages/index.js
    cat > "$project_path/pages/index.js" << 'EOF'
import { useState, useEffect } from 'react';

export default function Home() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/users')
      .then(res => res.json())
      .then(data => {
        setUsers(data.users);
        setLoading(false);
      });
  }, []);

  return (
    <div>
      <h1>Mock Next.js App</h1>
      <p>Testing Next.js project scanning</p>

      {loading ? (
        <p>Loading...</p>
      ) : (
        <div>
          <h2>Users</h2>
          {users.map(user => (
            <div key={user.id}>
              <h3>{user.name}</h3>
              <p>{user.email}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

    # Create pages/api/users.js
    cat > "$project_path/pages/api/users.js" << 'EOF'
export default function handler(req, res) {
  const users = [
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
  ];

  if (req.method === 'GET') {
    res.status(200).json({ users });
  } else {
    res.setHeader('Allow', ['GET']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
EOF
}

# Template Project Generator
generate_mock_template_project() {
    local variant="$1"
    local output_path="$2"
    local options="$3"

    case "$variant" in
        "cookiecutter") generate_mock_cookiecutter_template "$output_path" ;;
        *) echo "Unknown template variant: $variant" >&2; return 1 ;;
    esac
}

# Cookiecutter Template Generator
generate_mock_cookiecutter_template() {
    local project_path="$1"

    # Create project directory
    mkdir -p "$project_path"

    # Create cookiecutter.json
    cat > "$project_path/cookiecutter.json" << 'EOF'
{
    "project_name": "My Awesome Project",
    "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '_').replace('-', '_') }}",
    "author_name": "Your Name",
    "author_email": "your.email@example.com",
    "version": "0.1.0",
    "project_type": {
        "python": "Python Package",
        "nodejs": "Node.js Application",
        "fullstack": "Full Stack Application"
    },
    "use_docker": ["y", "n"],
    "use_tests": ["y", "n"],
    "license": ["MIT", "Apache-2.0", "GPL-3.0", "BSD-3-Clause"]
}
EOF

    # Create template structure
    mkdir -p "$project_path/{{cookiecutter.project_slug}}"

    # Create template README
    cat > "$project_path/{{cookiecutter.project_slug}}/README.md" << 'EOF'
# {{cookiecutter.project_name}}

{{cookiecutter.project_name}} - Generated from cookiecutter template

## Author
{{cookiecutter.author_name}} <{{cookiecutter.author_email}}>

## Version
{{cookiecutter.version}}

## Project Type
{{cookiecutter.project_type}}

{% if cookiecutter.use_docker == "y" -%}
## Docker Support
This project includes Docker configuration.
{% endif %}

{% if cookiecutter.use_tests == "y" -%}
## Testing
This project includes test configuration.
{% endif %}

## License
{{cookiecutter.license}}
EOF

    # Create conditional Python files
    mkdir -p "$project_path/{{cookiecutter.project_slug}}/{% if cookiecutter.project_type == 'python' %}src{% endif %}"
    cat > "$project_path/{{cookiecutter.project_slug}}/{% if cookiecutter.project_type == 'python' %}requirements.txt{% endif %}" << 'EOF'
# Python dependencies for {{cookiecutter.project_name}}
pytest>=7.0.0
black>=22.0.0
{% if cookiecutter.use_tests == "y" -%}
coverage>=6.0.0
{% endif %}
EOF

    # Create conditional Node.js files
    cat > "$project_path/{{cookiecutter.project_slug}}/{% if cookiecutter.project_type == 'nodejs' %}package.json{% endif %}" << 'EOF'
{
  "name": "{{cookiecutter.project_slug}}",
  "version": "{{cookiecutter.version}}",
  "description": "{{cookiecutter.project_name}}",
  "author": "{{cookiecutter.author_name}} <{{cookiecutter.author_email}}>",
  "license": "{{cookiecutter.license}}"
}
EOF

    # Create hooks
    mkdir -p "$project_path/hooks"
    cat > "$project_path/hooks/pre_gen_project.py" << 'EOF'
import re
import sys

MODULE_REGEX = r'^[_a-zA-Z][_a-zA-Z0-9]+$'
project_slug = '{{ cookiecutter.project_slug }}'

if not re.match(MODULE_REGEX, project_slug):
    print(f'ERROR: {project_slug} is not a valid Python module name!')
    sys.exit(1)
EOF

    cat > "$project_path/hooks/post_gen_project.py" << 'EOF'
import os
import shutil

# Remove unnecessary files based on project type
project_type = '{{ cookiecutter.project_type }}'

if project_type != 'python':
    if os.path.exists('requirements.txt'):
        os.remove('requirements.txt')
    if os.path.exists('src'):
        shutil.rmtree('src')

if project_type != 'nodejs':
    if os.path.exists('package.json'):
        os.remove('package.json')

print(f"Project {project_type} generated successfully!")
EOF
}

# Combo Project Generator
generate_mock_combo_project() {
    local combo_type="$1"
    local output_path="$2"
    local options="$3"

    echo "Generating combo project: $combo_type" >&2

    case "$combo_type" in
        "bash-python")
            generate_mock_bash_project "devcontainer" "$output_path"
            generate_mock_python_project_variant "simple" "$output_path"
            ;;
        "nodejs-template")
            generate_mock_nodejs_project "express" "$output_path"
            mkdir -p "$output_path/template"
            generate_mock_template_project "cookiecutter" "$output_path/template"
            ;;
        "all-tech")
            generate_mock_bash_project "devcontainer" "$output_path"
            mkdir -p "$output_path/api"
            generate_mock_python_project_variant "flask" "$output_path/api"
            mkdir -p "$output_path/frontend"
            generate_mock_nodejs_project "react" "$output_path/frontend"
            mkdir -p "$output_path/templates"
            generate_mock_template_project "cookiecutter" "$output_path/templates"
            ;;
        *) echo "Unknown combo type: $combo_type" >&2; return 1 ;;
    esac
}

# Common Project Generator
generate_common_files() {
    local project_path="$1"
    local project_name="$2"

    # Generate .gitignore if not exists
    if [[ ! -f "$project_path/.gitignore" ]]; then
        cat > "$project_path/.gitignore" << 'EOF'
# Common ignores
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.vscode/
.idea/
*.log
.DS_Store
Thumbs.db
EOF
    fi

    # Enhance README if it's basic
    if [[ ! -f "$project_path/README.md" ]]; then
        cat > "$project_path/README.md" << EOF
# $project_name

Mock project generated for testing riso-bootstrap context scanning.

## Generated Structure

\`\`\`
$(cd "$project_path" && find . -type f -name ".*" -prune -o -type f -print | head -20)
\`\`\`

## Purpose

This project is generated to test:
- Multi-technology detection
- PROJECT.md generation
- Cross-technology integration analysis

## Generated Components

- **Bash Scripts**: DevContainer features và utilities
- **Python**: Web frameworks (Flask/Django/FastAPI)
- **Node.js**: Frontend/backend applications
- **Templates**: Cookiecutter project generators

Generated on: $(date)
EOF
    fi
}

# Function to generate mock Python project for Serena testing (LEGACY - keep for compatibility)
generate_mock_python_project() {
    local project_path="${1:-.}"

    # Create main Python file
    cat > "$project_path/main.py" << 'EOF'
#!/usr/bin/env python3
"""Mock Python application for testing Serena semantic analysis"""

from typing import List, Optional
import json

class DataProcessor:
    """Process data with various methods"""

    def __init__(self, name: str):
        self.name = name
        self.data: List[dict] = []

    def add_data(self, item: dict) -> None:
        """Add item to data collection"""
        self.data.append(item)

    def process(self) -> dict:
        """Process all data and return summary"""
        return {
            "processor": self.name,
            "count": len(self.data),
            "data": self.data
        }

def calculate_sum(numbers: List[int]) -> int:
    """Calculate sum of numbers"""
    return sum(numbers)

def find_max(numbers: List[int]) -> Optional[int]:
    """Find maximum value in list"""
    return max(numbers) if numbers else None

def main():
    """Main entry point"""
    processor = DataProcessor("TestProcessor")
    processor.add_data({"id": 1, "value": "test"})
    result = processor.process()
    print(json.dumps(result, indent=2))

    numbers = [1, 2, 3, 4, 5]
    print(f"Sum: {calculate_sum(numbers)}")
    print(f"Max: {find_max(numbers)}")

if __name__ == "__main__":
    main()
EOF

    # Create utils module
    mkdir -p "$project_path/utils"
    cat > "$project_path/utils/__init__.py" << 'EOF'
"""Utilities module for mock project"""
EOF

    cat > "$project_path/utils/helpers.py" << 'EOF'
"""Helper functions for testing"""

def format_string(text: str) -> str:
    """Format string for display"""
    return text.strip().title()

def validate_input(value: any) -> bool:
    """Validate input value"""
    return value is not None and value != ""
EOF

    # Create test file
    cat > "$project_path/test_main.py" << 'EOF'
#!/usr/bin/env python3
"""Test file for mock project"""

import unittest
from main import DataProcessor, calculate_sum, find_max

class TestDataProcessor(unittest.TestCase):
    def test_add_data(self):
        processor = DataProcessor("Test")
        processor.add_data({"test": "data"})
        self.assertEqual(len(processor.data), 1)

    def test_calculate_sum(self):
        self.assertEqual(calculate_sum([1, 2, 3]), 6)

    def test_find_max(self):
        self.assertEqual(find_max([1, 5, 3]), 5)
        self.assertIsNone(find_max([]))

if __name__ == "__main__":
    unittest.main()
EOF

    # Create README
    cat > "$project_path/README.md" << 'EOF'
# Mock Test Project

This is a mock Python project generated for testing Serena code analysis capabilities.

## Structure
- `main.py` - Main application file
- `utils/` - Utility modules
- `test_main.py` - Unit tests

## Purpose
Used for testing the riso-bootstrap devcontainer feature with Serena integration.
EOF

    # Create requirements.txt
    cat > "$project_path/requirements.txt" << 'EOF'
# Mock requirements for testing
pytest>=7.0.0
black>=22.0.0
mypy>=0.900
EOF

    return 0
}
