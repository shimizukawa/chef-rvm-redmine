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
include_recipe "mysql::client" #need for redmine-mysql connection
include_recipe "imagemagick" #need for redmine gantt
include_recipe "imagemagick::devel" #need for redmine gantt
include_recipe "rvm::system"
include_recipe "rvm::gem_package"
include_recipe "unicorn"

# setup dynamic attribute
unless node["rvm_redmine"]["file"]
  node["rvm_redmine"]["file"] = "#{node["rvm_redmine"]["name"]}.tar.gz"
end
unless node['rvm_redmine']['archive_src']
  node['rvm_redmine']['archive_src'] = "http://rubyforge.org/frs/download.php/#{node['rvm_redmine']['dl_id']}/#{node['rvm_redmine']['file']}"
end


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

rvm_environment node.rvm_redmine.rvm_name

rvm_gem 'rubygems-update' do
  ruby_string node.rvm_redmine.rvm_name
  version '1.3.7'
end
rvm_shell 'update_rubygems' do
  ruby_string node.rvm_redmine.rvm_name
  code 'update_rubygems'
  not_if "test `gem -v` = 1.3.7"
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

rvm_redmine_setup node.rvm_redmine.name do
  rvm_name node.rvm_redmine.rvm_name
  owner node.rvm_redmine.user
  group node.rvm_redmine.group
  archive_src node.rvm_redmine.archive_src
  install_prefix node.rvm_redmine.install_prefix
  notifies :run, "rvm_shell[rvm_redmine load_default_data]", :immediately
end

template "/etc/init.d/redmine" do
  source "init.d.redmine.erb"
  owner "root"
  group "root"
  mode "0755"
  variables({
    :path => "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}",
  })
  notifies :enable, "service[redmine]", :immediately
  notifies :start, "service[redmine]"
end


rvm_shell "rvm_redmine bundle install" do
  action      :nothing
  ruby_string node.rvm_redmine.rvm_name
  user        node.rvm_redmine.user
  cwd         "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
  code        "bundle install --path vendor/bundler --without development test pg postgresql sqlite rmagick"
end

rvm_shell "rvm_redmine db:migrate" do
  action      :nothing
  ruby_string node.rvm_redmine.rvm_name
  user        'root'
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
  user        'root'
  cwd         "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"

  code <<-EOH
    export RAILS_ENV=production
    export REDMINE_LANG=ja
    rake --trace db:migrate_plugins
  EOH
end

rvm_shell "rvm_redmine load_default_data" do
  action      :nothing
  ruby_string node.rvm_redmine.rvm_name
  user        node.rvm_redmine.user
  group       node.rvm_redmine.group
  cwd         "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
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

node.rvm_redmine.plugins.each do |plugin|
  rvm_redmine_plugin plugin do
    rvm_name     node.rvm_redmine.rvm_name
    redmine_home "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
    user         node.rvm_redmine.user
  end
end

unicorn_config "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}/config/unicorn.config.rb" do
  listen({node.rvm_redmine.unicorn.port => node.rvm_redmine.unicorn.options})
  working_directory    "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}"
  worker_timeout       node.rvm_redmine.unicorn.worker_timeout
  preload_app          node.rvm_redmine.unicorn.preload_app
  worker_processes     node.rvm_redmine.unicorn.worker_processes
  unicorn_command_line node.rvm_redmine.unicorn.unicorn_command_line
  forked_user          node.rvm_redmine.unicorn.forked_user ||  node.rvm_redmine.user
  forked_group         node.rvm_redmine.unicorn.forked_group || node.rvm_redmine.group
  pid                  "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}/tmp/pids/unicorn.pid"
  before_exec          node.rvm_redmine.unicorn.before_exec || 'self[:logger].formatter = proc{|severity, datetime, progname, message| "#{datetime}: #{message}\n"}'
  before_fork          node.rvm_redmine.unicorn.before_fork || 'defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!'
  after_fork           node.rvm_redmine.unicorn.after_fork || 'defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection'
  stderr_path          "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}/log/unicorn.stderr.log"
  stdout_path          "#{node.rvm_redmine.install_prefix}/#{node.rvm_redmine.name}/log/unicorn.stdout.log"
  notifies             [:reload, "service[redmine]"]
  owner                node.rvm_redmine.user
  group                node.rvm_redmine.group
  mode                 "0644"
  copy_on_write        node.rvm_redmine.unicorn.copy_on_write
  enable_stats         node.rvm_redmine.unicorn.enable_stats
end
