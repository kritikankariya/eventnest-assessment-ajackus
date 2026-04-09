class Events::BookmarksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event

  # Bookmark an event
  def create
    @bookmark = @event.bookmarks.build(user: current_user)
    
    if @bookmark.save
      render json: @bookmark, status: :created
    else
      render json: { errors: @bookmark.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Remove a bookmark
  def destroy
    @bookmark = current_user.bookmarks.find_by(event_id: @event.id)
    
    if @bookmark&.destroy
      head :no_content
    else
      render json: { error: "Bookmark not found" }, status: :not_found
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end