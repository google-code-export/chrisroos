class Blog < ActiveRecord::Base
  include ConfigManager

  has_many :contents
  has_many :trackbacks
  has_many :articles
  has_many :comments
  has_many :pages, :order => "id DESC"
  has_many(:published_articles, :class_name => "Article",
           :conditions => ["published = ?", true],
           :include => [:tags],
           :order => "contents.created_at DESC") do
    def before(date = Time.now)
      find(:all, :conditions => ["contents.created_at < ?", date])
    end
  end

  has_many :pages
  has_many :comments

  serialize :settings, Hash

  # Description
  setting :blog_name,                  :string, 'My Shiny Weblog!'
  setting :canonical_server_url,       :string, ''

  # Spam
  setting :sp_global,                  :boolean, false
  setting :sp_article_auto_close,      :integer, 0
  setting :sp_allow_non_ajax_comments, :boolean, true
  setting :sp_url_limit,               :integer, 0
  setting :sp_akismet_key,             :string, ''

  # Mostly Behaviour
  setting :text_filter,                :string, ''
  setting :comment_text_filter,        :string, ''
  setting :limit_article_display,      :integer, 10
  setting :limit_rss_display,          :integer, 10
  setting :ping_urls,                  :string, "http://rpc.technorati.com/rpc/ping\nhttp://ping.blo.gs/\nhttp://rpc.weblogs.com/RPC2"
  setting :send_outbound_pings,        :boolean, true

  def find_already_published(content_type)
    self.send(content_type).find_already_published
  end

  def ping_article!(settings)
    settings[:blog_id] = self.id
    article_id = settings[:id]
    settings.delete(:id)
    trackback = published_articles.find(article_id).trackbacks.create!(settings)
  end


  def is_ok?
    settings.has_key?('blog_name')
  end

  def [](key)
    self.send(key)
  end

  def []=(key, value)
    self.send("#{key}=", value)
  end

  def has_key?(key)
    self.class.fields.has_key?(key.to_s)
  end

  def initialize(*args)
    super
    self.settings ||= { }
  end

  def self.default
    find(:first, :order => 'id')
  end

  @@controller_stack = []
  cattr_accessor :controller_stack

  def self.before(controller)
    controller_stack << controller
  end

  def self.after(controller)
    unless controller_stack.last == controller
      raise "Controller stack got out of kilter!"
    end
    controller_stack.pop
  end

  def controller
    controller_stack.last
  end

  def url_for(options = {}, *extra_params)
    case options
    when String then options
    when Hash
      options.reverse_merge!(:only_path => true, :controller => '/articles',
                             :action => 'permalink')
      url = ActionController::UrlRewriter.new(request, {})
      url.rewrite(options)
    else
      options.location(*extra_params)
    end
  end

  def article_url(article, only_path = true, anchor = nil)
    url_for(:year => article.published_at.year,
            :month => sprintf("%.2d", article.published_at.month),
            :day => sprintf("%.2d", article.published_at.day),
            :title => article.permalink, :anchor => anchor,
            :only_path => only_path,
            :controller => '/articles')
  end

  def server_url
    if controller
      controller.send :url_for, :only_path => false, :controller => "/articles"
    else
      settings[:canonical_server_url]
    end
  end

  private

  def request
    controller.request rescue ActionController::TestRequest.new
  end
end