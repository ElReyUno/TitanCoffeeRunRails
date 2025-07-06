class HomeController < ApplicationController
  # Skip authentication for the landing page
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    # Landing page - no authentication required
  end
end
