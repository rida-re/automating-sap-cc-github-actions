# SAP Commerce Cloud (CCV2) GitHub Actions Workflow

Automating SAP Commerce Cloud deployments using Github Actions with support for both mock and real environments.

## Features

- Support for mock and real SAP Commerce Cloud environments
- Configurable deployment parameters
- Environment-based configuration validation
- Enhanced mock API for local testing
- Configurable database update modes and deployment strategies

## Prerequisites

For real environment deployments:

1. SAP Commerce Cloud subscription
2. API access token with proper permissions
3. GitHub repository secrets setup:
   - `SAP_API_TOKEN`: Your SAP Commerce Cloud API token
   - `SAP_SUBSCRIPTION_CODE`: Your subscription code

## Workflow Parameters

The workflow can be triggered manually with the following parameters:

- **Environment** (required):
  - `mock`: Uses local mock API for testing
  - `development`: Development environment
  - `staging`: Staging environment
  - `production`: Production environment

- **Branch** (required):
  - Default: `main`
  - Any valid git branch name

- **Database Update Mode** (required):
  - `UPDATE`: Normal database update (default)
  - `SKIP`: Skip database updates

- **Deployment Strategy** (required):
  - `ROLLING_UPDATE`: Rolling update strategy (default)
  - `RECREATE`: Recreate deployment strategy

## Usage

### Mock Environment Testing

1. Trigger the workflow manually from GitHub Actions
2. Select `mock` as the environment
3. Configure other parameters as needed
4. The workflow will use a local mock API for testing

### Real Environment Deployment

1. Set up the required secrets in your GitHub repository
2. Trigger the workflow manually from GitHub Actions
3. Select the target environment (`development`, `staging`, or `production`)
4. Configure other parameters as needed
5. The workflow will deploy to the real SAP Commerce Cloud environment

### Automated Daily Builds

The workflow is configured to run automatically every day at 22:00 UTC using the mock environment for testing purposes.

## Workflow Structure

1. **Setup**:
   - Validates environment configuration
   - Sets up mock API if needed

2. **Build**:
   - Checks out the code
   - Builds SAP Commerce project
   - Uses mock or real API based on environment

3. **Deploy**:
   - Deploys the built code
   - Configurable update mode and strategy
   - Environment-specific deployment handling

## Mock API Features

The mock API simulates SAP Commerce Cloud behavior:

- Build and deployment status progression
- Realistic response formats
- Configurable success/failure scenarios
- Progress tracking simulation

## Error Handling

- Validates required secrets for real environments
- Checks API responses and provides detailed error messages
- Simulates realistic error scenarios in mock mode

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details
