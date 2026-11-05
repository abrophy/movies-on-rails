class FilmingLocation < ApplicationRecord
  has_many :appearances, dependent: :destroy
  has_many :movies, -> { distinct }, through: :appearances
  has_many :actors, -> { distinct }, through: :appearances

  validates :name, presence: true
  validates :country, presence: true
  validates :name, uniqueness: { scope: :country }
end
