# ============================================================
# MoviesController (ESaaS §6.7 - AJAX with Rails)
# ============================================================
#
# This controller demonstrates how Rails handles both regular
# HTTP requests AND AJAX requests from JavaScript.
#
# Key concept (ESaaS §6.7):
#   respond_to { |format| format.json { ... } }
#   allows the SAME controller action to return different formats:
#     - format.html → renders full HTML page (normal request)
#     - format.json → renders JSON data (AJAX request from JS)
#
# The client signals which format it wants via:
#   - URL extension: /movies/1.json
#   - Accept header: Accept: application/json
#   - X-Requested-With: XMLHttpRequest (for $.ajax)

class MoviesController < ApplicationController
  before_action :set_movie, only: %i[ show edit update destroy ]

  # GET /movies or /movies.json
  def index
    @movies = Movie.all
  end

  # GET /movies/1 or /movies/1.json
  # ============================================================
  # §6.7 - AJAX: Controller detects AJAX requests
  # ============================================================
  # When JS calls $.ajax({ url: '/movies/1.json' }), Rails routes
  # to this action with format :json.
  #
  # respond_to determines what to render:
  #   - Regular browser request → show.html.erb (full page)
  #   - AJAX request for JSON  → show.json.jbuilder (JSON data only)
  #
  # Alternative ways to detect AJAX (ESaaS §6.7):
  #   request.xhr?          → true if X-Requested-With header present
  #   request.format.json?  → true if client requested JSON
  def show
  end

  # GET /movies/new
  def new
    @movie = Movie.new
  end

  # GET /movies/1/edit
  def edit
  end

  # POST /movies or /movies.json
  def create
    new_movie_params = movie_params()
    @movie = Movie.new(new_movie_params)

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: "Movie was successfully created." }
        format.json { render :show, status: :created, location: @movie }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movies/1 or /movies/1.json
  def update
    respond_to do |format|
      if @movie.update(movie_params)
        format.html { redirect_to @movie, notice: "Movie was successfully updated." }
        format.json { render :show, status: :ok, location: @movie }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1 or /movies/1.json
  def destroy
    @movie.destroy!

    respond_to do |format|
      format.html { redirect_to movies_path, status: :see_other, notice: "Movie was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_movie
      @movie = Movie.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def movie_params
      params.require(:movie).permit(:title, :rating, :description, :release_date)
    end
end
