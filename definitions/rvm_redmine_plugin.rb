#
# Cookbook Name:: rvm-redmine
# Definition:: rvm_redmine_plugin
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

define :rvm_redmine_plugin, :action => :install, :rvm_name => '@redmine', :rvm_home => nil, :user => 'root', :redmine_home => '/usr/local/redmine' do
  plugin_name = params[:name]
  rvm_name = params[:rvm_name]
  rvm_home = params[:rvm_home]
  user = params[:user]
  redmine_home = params[:redmine_home]

  case params[:action]
  when :install

    rvm_shell "rvm_redmine_plugin install #{plugin_name}" do
      ruby_string rvm_name
      user        user
      cwd         redmine_home
      code        "ruby script/plugin install #{plugin_name}"
      notifies    :run,     resources(:rvm_shell => "rvm_redmine bundle install"), :immediately
      notifies    :run,     resources(:rvm_shell => "rvm_redmine db:migrate_plugins"), :immediately
      notifies    :restart, resources(:service => "redmine")
    end

  end

end
