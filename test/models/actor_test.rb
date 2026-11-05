require "test_helper"

class ActorTest < ActiveSupport::TestCase
  test "name must be present and unique" do
    Actor.create!(name: "Nicolas Cage")
    assert_not Actor.new(name: "").valid?
    assert_not Actor.new(name: "Nicolas Cage").valid?
  end

  test "search is a case-insensitive substring match" do
    Actor.create!(name: "Leonardo Di Caprio")
    assert_equal [ "Leonardo Di Caprio" ], Actor.search("caprio").pluck(:name)
  end

  test "search escapes wildcard characters" do
    Actor.create!(name: "100% Cotton")
    assert_empty Actor.search("_").to_a
    assert_equal [ "100% Cotton" ], Actor.search("%").pluck(:name)
  end

  test "search with a blank query returns no results" do
    Actor.create!(name: "Alice")
    assert_empty Actor.search("").to_a
    assert_empty Actor.search(nil).to_a
  end
end
