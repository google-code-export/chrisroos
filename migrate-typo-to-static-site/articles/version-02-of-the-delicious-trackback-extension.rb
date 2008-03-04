require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require 'article'

attributes = {
  :title => 'Version 0.2 of the del.icio.us trackback extension',
  :body => DATA.read,
  :guid => 'd1b7bcd5-eed9-410e-8d2f-3232aca73d04',
  :published_at => Time.parse('2008-03-04 09:30:00')
}

if article = Article.find_by_title(attributes[:title])
  p 'Article already exists, skipping'
  article.destroy
else
  Article.create!(attributes)
  p 'Article created'
end

__END__
I finally got round to compiling the "del.icio.us trackback extension":http://blog.seagul.co.uk/articles/2008/02/04/sending-trackbacks-to-the-sites-that-you-bookmark-in-del-icio-us I wrote about a while back.

You can install it from the installation.html[1] page on the "del.icio.us trackbacks google group":http://groups.google.com/group/delicious-trackbacks.  Feel free to use that group to post any questions you have too.

Current features:

* Scans the html of the page you're bookmarking looking for a link (anchor) with a rel attribute whose value is trackback.
* Sends a request to the trackback URI if it was found.
* Records (by adding the 'dtb-sent' tag) the sending of the trackback so that we can avoid sending multiple trackbacks to the same site.
* Records the success ('dtb-success' tag) or failure ('dtb-failure') of the trackback request.

That's all for now.

fn1. I don't appear to be able to link directly to that page which is a bit odd.