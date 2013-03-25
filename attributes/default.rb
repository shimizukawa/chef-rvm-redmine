#
# Cookbook Name:: rvm-redmine
# Recipe:: default
#
# Copyright 2013, Takayuki SHIMIZUKAWA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'

pw = String.new

while pw.length < 20
  pw << OpenSSL::Random.random_bytes(1).gsub(/\W/, '')
end

# for recipes/default.rb
default["rvm_redmine"]["rvm_name"] = "@redmine"
default["rvm_redmine"]["user"] = "www-data"
default["rvm_redmine"]["group"] = "root"
default["rvm_redmine"]["user_home"] = "/var/www"
default["rvm_redmine"]["install_prefix"] = "/var/www/www-data"
default["rvm_redmine"]["dl_id"]    = "76130"
default["rvm_redmine"]["name"] = "redmine-1.4.2"
default["rvm_redmine"]["file"] = nil  # auto generate from :name
default["rvm_redmine"]["archive_src"] = nil  # auto generate from :dl_id and :file

default["rvm_redmine"]["db"]["type"]     = "mysql"
default["rvm_redmine"]["db"]["user"]     = "root"
default["rvm_redmine"]["db"]["password"] = pw
default["rvm_redmine"]["db"]["hostname"] = "localhost"
default["rvm_redmine"]["db"]["dbname"]   = "redmine"

default["rvm_redmine"]["plugins"] = []

# for recipes/apache.rb
default["rvm_redmine"]["hostname"]         = 'localhost'
default["rvm_redmine"]["hostname_aliases"] = []

# for unicorn
default["rvm_redmine"]["unicorn"]["port"] = 10080
default["rvm_redmine"]["unicorn"]["options"] = [["tcp_nopush", "true"], ["backlog", "64"]]
default["rvm_redmine"]["unicorn"]["worker_timeout"] = 30
default["rvm_redmine"]["unicorn"]["worker_processes"] = 4
default["rvm_redmine"]["unicorn"]["preload_app"] = true
default["rvm_redmine"]["unicorn"]["unicorn_command_line"] = nil
default["rvm_redmine"]["unicorn"]["forked_user"] = nil
default["rvm_redmine"]["unicorn"]["forked_group"] = nil
default["rvm_redmine"]["unicorn"]["before_exec"] = 'self[:logger].formatter = proc{|severity, datetime, progname, message| "#{datetime}: #{message}\n"}'
default["rvm_redmine"]["unicorn"]["before_fork"] = 'defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!'
default["rvm_redmine"]["unicorn"]["after_fork"] = 'defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection'
default["rvm_redmine"]["unicorn"]["copy_on_write"] = nil
default["rvm_redmine"]["unicorn"]["enable_stats"] = nil
