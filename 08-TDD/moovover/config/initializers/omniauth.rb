# OmniAuth Configuration (ESaaS §5.2)
# OmniAuth gem helps a lot by providing uniform API to different "strategies"
# Adds routes beginning with /auth & provides controller to intercept them

Rails.application.config.middleware.use OmniAuth::Builder do
  # GitHub OAuth Strategy
  # To use this, you need to:
  # 1. Register your app at https://github.com/settings/applications/new
  # 2. Set environment variables GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET
  # 3. Set callback URL to: http://127.0.0.1:3000/auth/github/callback

  provider :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET'],
           scope: 'user:email'

  # For development/demo without real OAuth, you can use the developer strategy
  # This provides a simple form-based login for testing
  provider :developer if Rails.env.development?
end

# Handle OmniAuth failures
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
