# SessionsController handles Single Sign-On authentication (ESaaS §5.2)
# Model session as its own entity - creates and deletes session,
# handles interaction with auth provider
class SessionsController < ApplicationController
  # Skip CSRF protection for OmniAuth callback (handled by omniauth-rails_csrf_protection)
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /login
  def new
    # Show login page with available providers
  end

  # POST /auth/:provider/callback (OmniAuth callback)
  # Once user is authenticated, we need a local user model
  # session[] remembers primary key (ID) of "currently authenticated user"
  def create
    auth_hash = request.env['omniauth.auth']

    if auth_hash.present?
      @moviegoer = Moviegoer.from_omniauth(auth_hash)
      session[:user_id] = @moviegoer.id
      flash[:notice] = "Welcome, #{@moviegoer.name || 'User'}!"
      redirect_to movies_path
    else
      flash[:alert] = 'Authentication failed.'
      redirect_to login_path
    end
  end

  # DELETE /logout
  def destroy
    session.delete(:user_id)
    flash[:notice] = 'You have been logged out.'
    redirect_to movies_path
  end

  # GET /auth/failure
  def failure
    flash[:alert] = "Authentication failed: #{params[:message]}"
    redirect_to login_path
  end
end
