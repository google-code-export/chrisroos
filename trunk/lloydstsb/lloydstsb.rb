require 'lloydstsb_credentials'

require 'rubygems'
require 'hpricot'

def execute_curl(cmd)
  `#{cmd}`
end

COOKIE_LOCATION = '/Users/chrisroos/lloydstsb_cookie'
DOWNLOADED_STATEMENT_LOCATION = '/Users/chrisroos/Desktop/lloyds.qif'

# Store some cookies for later
curl_cmd = %[curl -s -c"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/customer.ibc"]
html = execute_curl(curl_cmd)

# Obtain the key that we need to POST along with our Username and Password
doc = Hpricot(html)
key = (doc/'input[@name=Key]').first.attributes['value']

# POST the key, userid and password
curl_cmd = %[curl -s -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/logon.ibc" -d"Java=Off" -d"Key=#{key}" -d"UserId1=#{USERID}" -d"Password=#{PASSWORD}"]
html = execute_curl(curl_cmd)

# Obtain the three characters from our memorable info that we need to POST
doc = Hpricot(html)
position_of_char1 = Integer((doc/'input[@name=ResponseKey0]').first.attributes['value'])
position_of_char2 = Integer((doc/'input[@name=ResponseKey1]').first.attributes['value'])
position_of_char3 = Integer((doc/'input[@name=ResponseKey2]').first.attributes['value'])
char1 = MEMORABLE.split('')[position_of_char1 - 1]
char2 = MEMORABLE.split('')[position_of_char2 - 1]
char3 = MEMORABLE.split('')[position_of_char3 - 1]

# POST our memorable info
curl_cmd = %[curl -s -L -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/miheld.ibc" -d"ResponseKey0=#{position_of_char1}" -d"ResponseValue0=#{char1}" -d"ResponseKey1=#{position_of_char2}" -d"ResponseValue1=#{char2}" -d"ResponseKey2=#{position_of_char3}" -d"ResponseValue2=#{char3}"]
execute_curl curl_cmd

# SELECT OUR ACCOUNT
curl_cmd = %[curl -s -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/account.ibc?Account=#{SORT_CODE_AND_ACCOUNT_NUMBER}"]
execute_curl curl_cmd

# GET OUR MOST RECENT TRANSACTIONS
curl_cmd = %[curl -s -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/statement.ibc?Account=#{SORT_CODE_AND_ACCOUNT_NUMBER}&PageRequired=MostRecent"]
execute_curl curl_cmd

# GET THE DOWNLOAD STATEMENT FORM
curl_cmd = %[curl -s -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/statement.ibc?Account=#{SORT_CODE_AND_ACCOUNT_NUMBER}&selectbox=6"]
execute_curl curl_cmd

# DOWNLOAD THE MOST RECENT TRANSACTIONS IN QIF FORMAT
curl_cmd = %[curl -s -L -b"#{COOKIE_LOCATION}" "https://online.lloydstsb.co.uk/statementdownload.ibc?Account=#{SORT_CODE_AND_ACCOUNT_NUMBER}&Download=DownloadLatest&Format=104" -o"#{DOWNLOADED_STATEMENT_LOCATION}"]
execute_curl curl_cmd

# Remove the cookie
`rm #{COOKIE_LOCATION}`