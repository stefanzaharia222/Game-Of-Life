require "test_helper"

class GameOfLifeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get game_of_life_index_url
    assert_response :success
  end
end
