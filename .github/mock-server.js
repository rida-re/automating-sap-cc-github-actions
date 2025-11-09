const express = require('express');
const app = express();
const port = 8080;

// Middleware to parse JSON bodies
app.use(express.json());

// Store mock data in memory
let builds = [];
let deployments = [];

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// Build endpoints
app.post('/v2/subscriptions/:subId/builds', (req, res) => {
    const buildCode = `BUILD_${Date.now()}`;
    const build = {
        code: buildCode,
        status: 'BUILDING',
        percentage: 0,
        ...req.body
    };
    builds.push(build);
    res.json(build);
});

app.get('/v2/subscriptions/:subId/builds/:code/progress', (req, res) => {
    const build = builds.find(b => b.code === req.params.code) || {
        code: req.params.code,
        status: 'SUCCESS',
        percentage: 100
    };
    
    if (build.percentage < 100) {
        build.percentage += 20;
        if (build.percentage >= 100) {
            build.status = 'SUCCESS';
        }
    }
    
    res.json(build);
});

// Deployment endpoints
app.post('/v2/subscriptions/:subId/deployments', (req, res) => {
    const deployCode = `DEPLOY_${Date.now()}`;
    const deployment = {
        code: deployCode,
        status: 'SCHEDULED',
        percentage: 0,
        ...req.body
    };
    deployments.push(deployment);
    res.json(deployment);
});

app.get('/v2/subscriptions/:subId/deployments/:code/progress', (req, res) => {
    const deployment = deployments.find(d => d.code === req.params.code) || {
        code: req.params.code,
        status: 'SCHEDULED',
        percentage: 0
    };
    
    if (deployment.status === 'SCHEDULED') {
        deployment.status = 'DEPLOYING';
        deployment.percentage = 20;
    } else if (deployment.status === 'DEPLOYING' && deployment.percentage < 100) {
        deployment.percentage += 20;
        if (deployment.percentage >= 100) {
            deployment.status = 'DEPLOYED';
        }
    }
    
    res.json(deployment);
});

// Start server
app.listen(port, () => {
    console.log(`Mock server running on port ${port}`);
});