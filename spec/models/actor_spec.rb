require "rails_helper"

RSpec.describe Actor, type: :model do
  describe "validations" do
    it "requires a unique, present name" do
      Actor.create!(name: "Nicolas Cage")

      expect(Actor.new(name: "")).not_to be_valid
      expect(Actor.new(name: "Nicolas Cage")).not_to be_valid
    end
  end

  describe ".search" do
    it "is a case-insensitive substring match" do
      Actor.create!(name: "Leonardo Di Caprio")

      expect(Actor.search("caprio").pluck(:name)).to eq([ "Leonardo Di Caprio" ])
    end

    it "escapes wildcard characters" do
      Actor.create!(name: "100% Cotton")

      expect(Actor.search("_").to_a).to be_empty
      expect(Actor.search("%").pluck(:name)).to eq([ "100% Cotton" ])
    end

    it "returns no results for a blank query" do
      Actor.create!(name: "Alice")

      expect(Actor.search("").to_a).to be_empty
      expect(Actor.search(nil).to_a).to be_empty
    end
  end
end
