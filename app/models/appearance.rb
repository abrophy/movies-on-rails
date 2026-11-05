class Appearance < ApplicationRecord
  belongs_to :movie
  belongs_to :actor
  belongs_to :filming_location

  # Backed by a unique DB index as well, so idempotent bulk imports are safe.
  validates :movie_id, uniqueness: { scope: [ :actor_id, :filming_location_id ] }
end
