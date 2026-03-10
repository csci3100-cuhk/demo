class ApplicationController < ActionController::Base
  # ============================================================
  # Controller Filters (ESaaS §5.1)
  # ============================================================
  # before_action :require_login, except: [:index, :show]
  # Uncomment the line above to require login for all controllers
  # Currently, require_login is only used in ReviewsController

  # Make current_user available in views (ESaaS §5.2)
  helper_method :current_user, :logged_in?

  protected  # prevents method from being invoked by a route

  # ============================================================
  # require_login filter
  # ============================================================
  # We exploit the fact that find_by_id(nil) returns nil
  def require_login
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
    redirect_to login_path, alert: 'You must be logged in.' and return unless @current_user
  end

  private

  # session[] remembers primary key (ID) of "currently authenticated user"
  def current_user
    @current_user ||= Moviegoer.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end
end
