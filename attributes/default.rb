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

#FIXME: parametelized values is buggy.
default[:rvm_redmine][:rvm_name] = "@redmine"
default[:rvm_redmine][:user] = "www-data"
default[:rvm_redmine][:group] = default[:rvm_redmine][:user]
default[:rvm_redmine][:user_home] = "/var/www/#{default[:rvm_redmine][:user]}"
default[:rvm_redmine][:dl_id]    = "76130"
default[:rvm_redmine][:version] = "1.4.2"
default[:rvm_redmine][:name] = "redmine-#{default[:rvm_redmine][:version]}"
default[:rvm_redmine][:file] = "#{default[:rvm_redmine][:name]}.tar.gz"
default[:rvm_redmine][:archive] = "#{default[:rvm_redmine][:user_home]}/#{node.redmine.file}"
default[:rvm_redmine][:path] = "#{default[:rvm_redmine][:user_home]}/#{node.redmine.name}"

default[:rvm_redmine][:db][:type]     = "mysql"
default[:rvm_redmine][:db][:user]     = "root"
default[:rvm_redmine][:db][:password] = pw
default[:rvm_redmine][:db][:hostname] = "localhost"

default[:rvm_redmine][:unicorn_port] = '10080'

# for recipes/apache.rb
default[:rvm_redmine][:hostname]         = 'localhost'
default[:rvm_redmine][:hostname_aliases] = []

