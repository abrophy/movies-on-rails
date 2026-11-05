class Actor < ApplicationRecord
  has_many :appearances, dependent: :destroy
  has_many :movies, -> { distinct }, through: :appearances
  has_many :filming_locations, -> { distinct }, through: :appearances

  validates :name, presence: true, uniqueness: true

  # Case-insensitive substring search. The wildcard characters in the user
  # input are escaped (and the ESCAPE clause makes that honored on SQLite,
  # which has no default LIKE escape) so a user can't turn a search into an
  # arbitrary pattern.
  def self.search(query)
    return none if query.blank?

    where("name LIKE ? ESCAPE '\\'", "%#{sanitize_sql_like(query)}%")
  end
end
