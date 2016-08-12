# cadlscrape
A little script that uses Selenium to scrape the kadenze.com website for screenshots
to generate a data set for kadenze.com's [Tensorflow course](https://www.kadenze.com/courses/creative-applications-of-deep-learning-with-tensorflow-i/info).

## Setup

### Dependencies
* [Ruby >= 2.2.2](https://www.ruby-lang.org/en/downloads/)
* [Chrome Webdriver](https://sites.google.com/a/chromium.org/chromedriver/downloads) installed.
* [RubyGems](https://rubygems.org/pages/download)
* [Bundler](http://bundler.io/)

### Install
`bundle install`

### Config File
The script assumes the presence of a `kad.config` file in the directory where it is run.
This config file should have the following format:
`
kadenze@email.com
kadenze_password
depth_limit
`

## Running
Once all the setup is complete, you should be able to simply run: `ruby scrape.rb` and watch the magic happen.
Screenshots will be stored in an `img` directory in the directory where you ran the script.
