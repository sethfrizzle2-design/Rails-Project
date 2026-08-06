require "test_helper"

class TestsitesControllerTest < ActionDispatch::IntegrationTest
  test "should get pages" do
    get testsites_pages_url
    assert_response :success
  end

  test "should get one" do
    get testsites_one_url
    assert_response :success
  end

  test "should get two" do
    get testsites_two_url
    assert_response :success
  end

  test "should get three" do
    get testsites_three_url
    assert_response :success
  end

  test "should get four" do
    get testsites_four_url
    assert_response :success
  end
end
