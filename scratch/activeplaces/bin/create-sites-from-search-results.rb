require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require File.join(File.dirname(__FILE__), 'active_places_helper')
include ActivePlacesHelper

search_result_html_file = File.join(SEARCH_RESULTS_DIRECTORY, "search-results-CT12-all.html")
html = File.read(search_result_html_file)

doc = Hpricot(html)
(doc/'table').each do |table|
  table_rows = (table/'tr')
  next unless table_rows.length == 5
  
  name = (table/'tr:nth(0) td').inner_text[/\d+\.(.*)/, 1].strip
  id = Integer((table/'tr:nth(1) td:nth(0)').inner_text.strip)
  distance = (table/'tr:nth(1) td:nth(1)').inner_text.strip
  telephone = (table/'tr:nth(3) td:nth(0)').inner_text.sub(/^Tel:/, '').strip
  address = (table/'tr:nth(4) td:nth(0)').inner_text.strip
  site_link = (table/'tr:nth(4) td:nth(1) a:nth(0)').first['href']
  ward_id = Integer(site_link[/wardId=(\d+)/, 1])
  
  attrs = {
    'id' => id,
    'name' => name,
    'telephone' => telephone.blank? ? 'NA' : telephone,
    'address' => address,
    'ward_id' => ward_id
  }
  
  if existing_site = Site.find_by_id(id)
    puts "Duplicate site: Id: #{id} and name: #{name}"
    existing_attrs = {
      'id' => existing_site.attributes['id'],
      'name' => existing_site.attributes['name'],
      'telephone' => existing_site.attributes['telephone'],
      'address' => existing_site.attributes['address'],
      'ward_id' => existing_site.attributes['ward_id']
    }
    unless existing_attrs == attrs
      raise "There's already a record for the site with Id: #{id}.  Unfortunately the existing attributes don't match the new attributes.  This is probably bad."
    end
  else
    site = Site.new(attrs)
    site.id = id
    if site.save
      puts "Created site: Id: #{id} and name: #{name}"
    else
      raise "*** ERRORS ON SAVE (#{id}, #{name}): #{site.errors.full_messages}"
    end
  end
end