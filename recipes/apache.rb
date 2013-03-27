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

include_recipe "openssl"
include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

apache_module 'proxy' do
  # overwrite proxy allow setting
  conf true
end

web_app "redmine" do
  subpath = node.rvm_redmine.url_subpath || '/'

  template 'apache-redmine-proxy.conf.erb'
  server_name node.rvm_redmine.hostname
  server_aliases node.rvm_redmine.hostname_aliases
  docroot "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}/public"
  application_name 'redmine'
  proxy_pass "#{subpath} http://127.0.0.1:#{node.rvm_redmine.unicorn.port}#{subpath}"
  proxy_pass_reverse "#{subpath} http://127.0.0.1:#{node.rvm_redmine.unicorn.port}#{subpath}"
  notifies :reload, "service[apache2]"
end
