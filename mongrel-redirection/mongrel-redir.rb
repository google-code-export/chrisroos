require 'mongrel'
require 'redirector'

port = ENV['REDIRECTION_PORT'] || '4000'

HOST_AND_PATH_REDIRECTIONS = {
  'chrisroos.co.uk' => {
    '/amazonwishlist' => 'http://www.amazon.co.uk/gp/registry/IO9HVNCPEWGD'
  }
}
HOST_REDIRECTIONS = {
  'www.chrisroos.co.uk' => 'chrisroos.co.uk'
}

class SimpleHandler < Mongrel::HttpHandler
  def process(request, response)
    redirector = Redirector.new(request, HOST_REDIRECTIONS, HOST_AND_PATH_REDIRECTIONS)
    
    if redirect_to = redirector.redirect_to
      response.start(302) do |head,out|
        head["Location"] = redirect_to
      end
    else
      response.start do |head,out|
        head["Content-Type"] = "text/html"
        results = "<html><body>Your request:<br /><pre>#{request.params.to_yaml}</pre><a href=\"/files\">View the files.</a></body></html>"
        out << results
      end
    end
  end
end

config = Mongrel::Configurator.new :host => '127.0.0.1', :port => port do
  listener do
    uri "/", :handler => SimpleHandler.new
  end

  trap("INT") { stop }
  run
end

config.join