require "test_helper"

class TestsitesControllerTest < ActionDispatch::IntegrationTest
    # Every controller inherits require_login, so these generated tests redirect
    # to the login page unless they sign in first.
    setup do
        post login_path, params: { user: { email: users(:tester).email, password: "secret123" } }
    end

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
