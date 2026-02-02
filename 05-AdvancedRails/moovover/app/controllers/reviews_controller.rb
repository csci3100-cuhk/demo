# ReviewsController with nested routes (ESaaS §5.6)
# Reviews are accessed through movies: /movies/:movie_id/reviews
class ReviewsController < ApplicationController
  # ============================================================
  # Controller Filters (ESaaS §5.1)
  # ============================================================
  # Filters inherit! A filter in ApplicationController will apply to all controllers
  # require_login is inherited from ApplicationController
  before_action :set_movie
  before_action :require_login, except: [:index, :show]  # Allow viewing without login
  before_action :set_review, only: [:show, :edit, :update, :destroy]

  # GET /movies/:movie_id/reviews
  def index
    @reviews = @movie.reviews.includes(:moviegoer)
  end

  # GET /movies/:movie_id/reviews/:id
  def show
  end

  # GET /movies/:movie_id/reviews/new
  def new
    # movie_id because of nested route
    @movie = Movie.find(params[:movie_id])
    # new sets movie_id foreign key automatically
    @review ||= @movie.reviews.new
    # equivalent: @review = @review || @movie.reviews.new
  end

  # POST /movies/:movie_id/reviews
  def create
    # movie_id because of nested route, or use set_movie action
    @movie = Movie.find(params[:movie_id])
    # build sets the movie_id foreign key automatically
    @review = @movie.reviews.build(review_params)
    @review.moviegoer = current_user

    if @review.save
      flash[:notice] = 'Review successfully created.'
      redirect_to movie_reviews_path(@movie)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /movies/:movie_id/reviews/:id/edit
  def edit
  end

  # PATCH/PUT /movies/:movie_id/reviews/:id
  def update
    if @review.update(review_params)
      flash[:notice] = 'Review successfully updated.'
      redirect_to movie_review_path(@movie, @review)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /movies/:movie_id/reviews/:id
  def destroy
    @review.destroy
    flash[:notice] = 'Review successfully deleted.'
    redirect_to movie_reviews_path(@movie), status: :see_other
  end

  private

  # ============================================================
  # before_action :set_movie
  # ============================================================
  # Another possibility: do it in a before-filter
  def set_movie
    @movie = Movie.find(params[:movie_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movies_path, alert: 'Movie not found'
  end

  def set_review
    @review = @movie.reviews.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to movie_reviews_path(@movie), alert: 'Review not found'
  end

  def review_params
    params.require(:review).permit(:potatoes)
  end

  # NOTE: require_login can now be inherited from ApplicationController
  # No need to define it here - filters inherit!
  def require_login
    # we exploit the fact that find_by_id(nil) returns nil
    @current_user ||= Moviegoer.find_by_id(session[:user_id])
    redirect_to login_path, alert: 'You must be logged in :(.' and return unless @current_user
  end

  
end
