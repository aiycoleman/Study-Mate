// API configuration for Study Mate backend
// Updated for bridged adapter networking

// const String apiBaseUrl = 'http://10.0.73.0:4000';

const String apiBaseUrl = 'http://192.168.18.109:4000';

// Alternative configurations:
// For VM (when IP is found): 'http://[VM_IP]:4000'
// For Android emulator: 'http://10.0.2.2:4000'
// For web browser: 'http://localhost:4000'

// API endpoints
const String healthCheckEndpoint = '/v1/healthcheck';
const String loginEndpoint = '/v1/tokens/authentication';
const String registerEndpoint = '/v1/users';
const String activateEndpoint = '/v1/users/activated';
