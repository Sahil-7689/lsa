const express = require('express');
const cors = require('cors');
const complianceRoutes = require('./routes/compliance');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for local Flutter web / desktop / emulator requests
app.use(cors());

// Parse application/json
app.use(express.json());

// Mount API version 1 routes
app.use('/v1', complianceRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'habotconnect-compliance-mock-api',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Root informational endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'HabotConnect HPF Mock Compliance REST API',
    endpoint: 'POST /v1/compliance/verify',
    note: 'Local Mock REST API used to demonstrate the required API contract and fail-closed integration behavior.'
  });
});

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log('====================================================');
    console.log(` HabotConnect Mock REST API running on port ${PORT}`);
    console.log(` Endpoint: http://localhost:${PORT}/v1/compliance/verify`);
    console.log(` Android Emulator Endpoint: http://10.0.2.2:${PORT}/v1/compliance/verify`);
    console.log('====================================================');
  });
}

module.exports = app;
