require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/content_controller'

require 'http_mock'

# Re-raise errors caught by the controller.
class Admin::ContentController; def rescue_action(e) raise e end; end

class Admin::ContentControllerTest < Test::Unit::TestCase
  fixtures :contents, :users, :text_filters,
           :blogs

  def setup
    @controller = Admin::ContentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session = { :user => users(:tobi) }
  end

  def test_index
    get :index
    assert_rendered_file 'list'
  end

  def test_list
    get :list
    assert_rendered_file 'list'
    assert_template_has 'articles'
  end

  def test_show
    get :show, 'id' => 1
    assert_rendered_file 'show'
    assert_template_has 'article'
    assert_valid_record 'article'
    assert_not_nil assigns(:article)
  end

  def test_new
    get :new
    assert_rendered_file 'new'
    assert_template_has 'article'
  end

  def test_create_no_comments
    post(:new, 'article' => { :title => "posted via tests!", :body => "You can't comment",
                              :keywords => "tagged",
                              :allow_comments => '0', :allow_pings => '1' },
               'categories' => [1])
    assert !assigns(:article).allow_comments?
    assert  assigns(:article).allow_pings?
    assert  assigns(:article).published?
  end

  def test_create_with_no_pings
    post(:new, 'article' => { :title => "posted via tests!", :body => "You can't ping!",
                              :keywords => "tagged",
                              :allow_comments => '1', :allow_pings => '0' },
               'categories' => [1])
    assert  assigns(:article).allow_comments?
    assert !assigns(:article).allow_pings?
    assert  assigns(:article).published?
  end

  def test_create
    num_articles = this_blog.published_articles.size
    emails = ActionMailer::Base.deliveries
    emails.clear
    tags = ['foo', 'bar', 'baz bliz', 'gorp gack gar']
    post :new, 'article' => { :title => "posted via tests!", :body => "Foo", :keywords => "foo bar 'baz bliz' \"gorp gack gar\""}, 'categories' => [1]
    assert_redirected_to :action => 'show'

    assert_equal num_articles + 1, this_blog.published_articles.size

    new_article = Article.find(:first, :order => "id DESC")
    assert_equal users(:tobi), new_article.user
    assert_equal 4, new_article.tags.size

    assert_equal(1, emails.size)
    assert_equal('randomuser@example.com', emails.first.to[0])
  end

  def test_create_future_article
    num_articles = this_blog.published_articles.size
    post(:new,
         :article => { :title => "News from the future!",
                       :body => "The future's cool!",
                       :published_at => Time.now + 1.hour })
    assert_redirected_to :action => 'show'
    assert ! assigns(:article).published?
    assert_equal num_articles, this_blog.published_articles.size
    assert_equal 1, Trigger.count
  end

  def test_request_fires_triggers
    art = this_blog.articles.create!(:title => 'future article',
                                     :body => 'content',
                                     :published_at => Time.now + 2.seconds,
                                     :published => true)
    assert !art.published?
    sleep 3
    get(:show, :id => art.id)
    assert assigns(:article).published?
  end

  def test_create_filtered
    body = "body via *textile*"
    post :new, 'article' => { :title => "another test", :body => body }
    assert_redirected_to :action => 'show'

    new_article = Article.find(:first, :order => "created_at DESC")
    assert_equal body, new_article.body
    assert_equal "textile", new_article.text_filter.name
    assert_equal "<p>body via <strong>textile</strong></p>", new_article.html(@controller, :body)
  end

  def test_edit
    get :edit, 'id' => 1
    assert_rendered_file 'edit'
    assert_template_has 'article'
    assert_valid_record 'article'
  end

  def test_update
    emails = ActionMailer::Base.deliveries
    emails.clear

    body = "another *textile* test"
    post :edit, 'id' => 1, 'article' => {:body => body, :text_filter => 'textile'}
    assert_redirected_to :action => 'show', :id => 1

    article = Article.find(1)
    assert_equal "textile", article.text_filter.name
    assert_equal body, article.body
    # Deliberately *not* using the mediating protocol, we want to ensure that the
    # body_html got reset to nil.
    assert_nil article.body_html

    assert_equal 0, emails.size
  end

  def test_destroy
    assert_not_nil Article.find(1)

    get :destroy, 'id' => 1
    assert_success

    post :destroy, 'id' => 1
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      article = Article.find(1)
    }
  end

end
