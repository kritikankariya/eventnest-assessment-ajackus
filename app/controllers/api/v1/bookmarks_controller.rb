module Api
    module V1
      class BookmarksController < ApplicationController
        def index
            @bookmarks = current_user.bookmarks.includes(:event).order(created_at: :desc)
            render json: @bookmarks, include: :event
        end
      end
  end
end