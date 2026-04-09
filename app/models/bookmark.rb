class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :event

  # Application-level uniqueness validation
  validates :event_id, uniqueness: { scope: :user_id, message: "has already been bookmarked" }
  
  # Ensure only attendees can bookmark (Assuming User has a 'role' attribute)
  validate :user_must_be_attendee

  private

  def user_must_be_attendee
    unless user&.attendee? 
      errors.add(:user, "must be an attendee to bookmark events")
    end
  end
end