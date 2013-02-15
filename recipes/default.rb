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
include_recipe "imagemagick" #need for redmine gantt
include_recipe "imagemagick::devel" #need for redmine gantt
include_recipe "rvm::system"
include_recipe "rvm::gem_package"


directory node.rvm_redmine.install_prefix do
  owner node.rvm_redmine.user
  group node.rvm_redmine.group
  recursive true
end

file "#{node.rvm_redmine.user_home}/.gemrc" do
  # for ignore rdoc and ri
  action :create
  owner node.rvm_redmine.user
  group node.rvm_redmine.group
  content "gem: --no-ri --no-rdoc"
end

#rvm_install "#{node.rvm.ruby_version} -C --with-iconv-dir=$rvm_usr_path --with-openssl-dir=$rvm_usr_path -C --with-zlib-dir=$rvm_usr_path --with-readline-dir=$rvm_usr_path"
rvm_environment node.rvm_redmine.rvm_name

rvm_gem 'rubygems-update' do
  ruby_string node.rvm_redmine.rvm_name
  version '1.3.7'
end
rvm_shell 'update_rubygems' do
  #not_if "test `gem -v` = 1.3.7"
  ruby_string node.rvm_redmine.rvm_name
end
rvm_gem 'rdoc' do
  ruby_string node.rvm_redmine.rvm_name
end
rvm_gem 'rmagick' do
  ruby_string node.rvm_redmine.rvm_name
  version '1.15.17'
end
rvm_gem 'bundler' do
  ruby_string node.rvm_redmine.rvm_name
  version '1.2.1'
end

rvm_redmine_setup 'redmine-1.4.2' do
  rvm_name node.rvm_redmine.rvm_name
  rvm_home node.rvm_redmine.user_home
  owner node.rvm_redmine.user
  group node.rvm_redmine.group
  archive_file = node.rvm_redmine.file
  install_prefix node.rvm_redmine.install_prefix
  notifies :run, "rvm_shell[rvm_redmine load_default_data]", :immediately
end

rvm_shell "rvm_redmine bundle install" do
  action :nothing
  ruby_string node.rvm_redmine.rvm_name
  cwd "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
  code "bundle install --without development test pg postgresql sqlite rmagick"
end

rvm_shell "rvm_redmine db:migrate" do
  action      :nothing
  ruby_string node.rvm_redmine.rvm_name
  user        node.rvm_redmine.user
  cwd         "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"

  #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with use_rvm! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
  code <<-EOH
  export RAILS_ENV=production
  export REDMINE_LANG=ja
  rake --trace db:migrate
  EOH
end

rvm_shell "rvm_redmine db:migrate_plugins" do
  action      :nothing
  ruby_string node.rvm_redmine.rvm_name
  user        node.rvm_redmine.user
  cwd         "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"

  code <<-EOH
    export RAILS_ENV=production
    export REDMINE_LANG=ja
    rake --trace db:migrate_plugins
  EOH
end

rvm_shell "rvm_redmine load_default_data" do
  action :nothing
  ruby_string node.rvm_redmine.rvm_name
  user  node.rvm_redmine.user
  group node.rvm_redmine.group
  cwd   "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
  #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with use_rvm! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
  code <<-EOH
  export RAILS_ENV=production
  export REDMINE_LANG=ja
  rake --trace redmine:load_default_data
  EOH
  #not_if TODO
end

service "redmine" do
  action :nothing
  supports :restart => true, :start => true, :stop => true, :reload => true
end
