require 'selenium-webdriver'

img_dir = File.join File.dirname(__FILE__), 'img'

username, password = nil, nil
if File.exists? 'kad.config'
  File.open('kad.config', 'r') do |file|
    username = file.readline
    password = file.readline
    depth_limit = file.readline.to_i
  end
else
  puts "Please create a 'kad.config' file in this directory.\
  It should include your email and kadenze password"
end

start = 'https://kadenze.com/sign_in'

driver = Selenium::WebDriver.for :chrome

def with_wait(n, driver, &block)
  wait = Selenium::WebDriver::Wait.new timeout: n
  wait.until { driver.execute_script('return $(":animated").length == 0 && $.active <= 0') }
  res = block.call wait, driver 
  wait.until { driver.execute_script('return $(":animated").length == 0 && $.active <= 0') }
  res
end

def save_img(driver, img_dir)
  with_wait(2, driver) do |wait, d|
    filename = d.current_url
                .split('https://www.kadenze.com/').last
    filename = filename.nil? ? 'root.png' : filename.split('/').last.concat('.png')
    puts filename
    d.save_screenshot File.join(img_dir, filename)
  end
end

def get_next_links(driver, current_depth, url_queue, visited)
  with_wait(2, driver) do |w, d|
    w.until { d.find_elements tag_name: 'a' }
      .select { |ele| ele['href'] }
      .map { |ele| ele['href'] }
      .select { |url| url.start_with? 'https://www.kadenze.com/' }
      .reject { |url| url_queue.include?(url) || visited.include?(url) }
      .map { |url| { url: url, depth: current_depth + 1 } }
  end
end

begin
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

rescue Exception => e
    puts e

end

driver.quit
puts "Completed at depth: #{current_depth}"
puts "Collected #{Dir.new(img_idr).size} images"
