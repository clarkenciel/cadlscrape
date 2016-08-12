require 'selenium-webdriver'

img_dir = File.join File.dirname(__FILE__), 'img'

# Create image directory if it doesn't exist already
if !Dir.exist? img_dir
end

# Collect our credentials from the config file
username, password, depth_limit = nil, nil, nil
if File.exists? 'kad.config'
  File.open('kad.config', 'r') do |file|
    username = file.readline
    password = file.readline
    depth_limit = file.readline.to_i
  end
else
  puts "Please create a 'kad.config' file in this directory.\
  It should include your email, kadenze password, and a depth limit\
  for the search, each on a separate line."
end

# with_wait(timeout_len, WebDriver_instance, lambda(wait, driver))
# method that will run a block that will execute a block
# that takes a wait and a driver after waiting for all animations
# and ajax queries to settle down on a page
def with_wait(n, driver, &block)
  wait = Selenium::WebDriver::Wait.new timeout: n
  wait.until { driver.execute_script('return $(":animated").length == 0 && $.active <= 0') }
  res = block.call wait, driver 
  wait.until { driver.execute_script('return $(":animated").length == 0 && $.active <= 0') }
  res
end

# save_img(WebDriver_instance, image_directory_name)
# Will take a screenshot of the page the WebDriver_instance is currently
# on and store it in the image directory with name image_directory_name.
# Files will be named according to the last part of their url.
def save_img(driver, img_dir)
  with_wait(2, driver) do |wait, d|
    filename = d.current_url
                .gsub(/#/, '') 
                .split('https://www.kadenze.com/')
                .last
    if filename.nil?
      filename = 'root.png'
    else
      filename = filename.split('/')
      if filename.include? 'info'
        filename = filename.slice(-2,2).join('-').concat('.png')
      else
        filename = filename.last.concat('.png')
      end
    end
    puts filename
    d.save_screenshot File.join(img_dir, filename)
  end
end

# get_next_links(WebDriver_instance, integer, [String], [String])
# Will grab all <a> tags on the current page, extract their hrefs
# and filter those hrefs so there are no duplicates of urls in the
# queue or in the list of visited urls and so that the returned
# list of urls has no duplicates.
def get_next_links(driver, current_depth, url_queue, visited)
  with_wait(2, driver) do |w, d|
    w.until { d.find_elements tag_name: 'a' }
      .select { |ele| ele['href'] }
      .map { |ele| ele['href'] }
      .select { |url| url.start_with? 'https://www.kadenze.com/' }
      .reject { |url| url.include?('enroll') || url.include?('sign_out') || url_queue.include?(url) || visited.include?(url) }
      .map { |url| { url: url, depth: current_depth + 1 } }
      .uniq
  end
end

# The main script.
# Essentially a BFS beginning with the course dashboard that is presented ot a user
# after log in.
begin
  start = 'https://kadenze.com/sign_in'
  driver = Selenium::WebDriver.for :chrome
  driver.get start

  with_wait(2, driver) do |wait, d|
    email_field = wait.until { d.find_element id: 'login_user_email' }
    pw_field = wait.until { d.find_element id: 'login_user_password' }
    login_butt = wait.until { d.find_element css: "button[data-test='login-submit-btn']" }

    email_field.send_keys username
    pw_field.send_keys password
    login_butt.click
  end

  save_img driver, img_dir
  current_depth = 0
  visited = ['https://www.kadenze.com/']
  queue = get_next_links(driver, current_depth, [], visited)
  until current_depth >= depth_limit || queue.size == 0
    current = queue.shift
    current_url = current[:url]
    current_depth = current[:depth]
    visited.push current_url
    queue += get_next_links(driver, current_depth, queue.map { |i| i[:url] }, visited)

    driver.get current_url
    save_img driver, img_dir
    puts "#{current_depth}: #{current_url}"
  end

# rescue Exception => e
#     puts e
end

driver.quit
puts "Completed at depth: #{current_depth}"
puts "Collected #{Dir.new(img_dir).size} images"
