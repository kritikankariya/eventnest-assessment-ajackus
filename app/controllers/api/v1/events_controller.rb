module Api
  module V1
    class EventsController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index, :show]

      def index
        events = Event.published.upcoming

        if params[:search].present?
          events = Event.where("title LIKE ? OR description LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
        end

        if params[:category].present?
          events = events.where(category: params[:category])
        end

        if params[:city].present?
          events = events.where(city: params[:city])
        end

        events = events.order(params[:sort_by] || "starts_at ASC")

        render json: events.map { |event|
          {
            id: event.id,
            title: event.title,
            description: event.description,
            venue: event.venue,
            city: event.city,
            starts_at: event.starts_at,
            ends_at: event.ends_at,
            category: event.category,
            organizer: event.user.name,
            total_tickets: event.total_tickets,
            tickets_sold: event.total_sold,
            ticket_tiers: event.ticket_tiers.map { |t|
              {
                id: t.id,
                name: t.name,
                price: t.price.to_f,
                available: t.available_quantity
              }
            }
          }
        }
      end

      def show
        event = Event.find(params[:id])

        render json: {
          id: event.id,
          title: event.title,
          description: event.description,
          venue: event.venue,
          city: event.city,
          starts_at: event.starts_at,
          ends_at: event.ends_at,
          status: event.status,
          category: event.category,
          organizer: {
            id: event.user.id,
            name: event.user.name
          },
          ticket_tiers: event.ticket_tiers.map { |t|
            {
              id: t.id,
              name: t.name,
              price: t.price.to_f,
              quantity: t.quantity,
              sold: t.sold_count,
              available: t.available_quantity
            }
          }
        }
      end

      def create
        event = Event.new(event_params)
        event.user = current_user

        if event.save
          render json: event, status: :created
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        # FIX: Scope to current_user
        event = current_user.events.find_by(id: params[:id])
        
        if event.nil?
          return render json: { error: "Event not found or unauthorized" }, status: :not_found
        end

        if event.update(event_params)
          render json: event
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        # FIX: Scope to current_user
        event = current_user.events.find_by(id: params[:id])
        
        if event.nil?
          return render json: { error: "Event not found or unauthorized" }, status: :not_found
        end

        event.destroy
        head :no_content
      end

      def bookmark_count
        @event = Event.find(params[:id])
        
        if current_user.organizer? && current_user.id == @event.user_id
          render json: { event_id: @event.id, bookmark_count: @event.bookmarks.count }
        else
          render json: { error: "Unauthorized. Only the organizer can view this." }, status: :forbidden
        end
      end
      private

      def event_params
        params.require(:event).permit(:title, :description, :venue, :city,
          :starts_at, :ends_at, :category, :max_capacity, :status)
      end
    end
  end
end
