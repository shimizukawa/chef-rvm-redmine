#
# Cookbook Name:: rvm-redmine
# Definition:: rvm_redmine_setup
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

define :rvm_redmine_setup, :action => :setup, :rvm_name => '@redmine', :owner => 'root', :group => 'root', :install_prefix => '/usr/local', :archive_src => nil, :url_subpath => nil do
  name = params[:name]
  rvm_name = params[:rvm_name]
  owner = params[:owner]
  group = params[:group]
  archive_src = params[:archive_src]
  install_prefix = params[:install_prefix]
  path = "#{install_prefix}/#{name}"
  archive_dir = Chef::Config[:file_cache_path]
  archive_file = archive_src.split('/').last
  install_target = "#{path}/redmine.sh"
  url_subpath = params[:url_subpath]

  case params[:action]
  when :setup
    script "Download #{archive_file}" do
      interpreter "ruby"
      code <<-EOH
        require 'open-uri'
        open("#{archive_src}", 'rb') do |input|
          open("#{archive_dir}/#{archive_file}", 'wb') do |output|
            while data = input.read(8192) do
              output.write(data)
            end
          end
        end
      EOH

      not_if "test -f #{archive_dir}/#{archive_file} -o -f #{install_target}"
      #notifies :run, "execute[extract-#{name}]", :immediately
    end

    execute "extract-#{name}" do
      #action :nothing
      user owner
      cwd install_prefix
      command "tar zxf #{archive_dir}/#{archive_file}"
      not_if "test -f #{install_target}"
      notifies :create, "template[place-#{name}-additional_environment.rb]", :immediately
      notifies :create, "template[place-#{name}-Gemfile.local]", :immediately
      notifies :run, "rvm_shell[rvm_redmine bundle install]", :immediately
      notifies :create, "template[place-#{name}-database.yml]", :immediately
      notifies :run, "rvm_shell[#{name} rake generate_session_store]", :immediately
      notifies :run, "rvm_shell[#{name} rake db:create]", :immediately
      notifies :run, "rvm_shell[rvm_redmine db:migrate]", :immediately
      notifies :run, "rvm_shell[#{name} load_default_data]", :immediately
      notifies :create, "template[place-#{name}-redmine.sh]", :immediately
    end

    template "place-#{name}-Gemfile.local" do
      owner owner
      group group
      source "Gemfile.local"
      path "#{path}/Gemfile.local"
      mode "0644"
      notifies :run, "rvm_shell[rvm_redmine bundle install]"
    end

    template "place-#{name}-additional_environment.rb" do
      owner owner
      group group
      source "additional_environment.rb"
      path "#{path}/config/additional_environment.rb"
      mode "0644"
      notifies :restart, "service[redmine]"
    end

    template "place-#{name}-database.yml" do
      owner 'root'
      group 'root'
      source "database.yml.erb"
      path "#{path}/config/database.yml"
      mode "0600"
      notifies :run, "rvm_shell[rvm_redmine db:migrate]"
    end

    template "place-#{name}-redmine.sh" do
      unicorn_options = "--path=#{url_subpath}" if url_subpath

      owner owner
      group group
      source "redmine.sh.erb"
      path install_target
      mode "0755"
      variables({
        :path => path,
        :name => name,
        :rvm_name => rvm_name,
        :extra_unicorn_options => unicorn_options
      })
      notifies :restart, "service[redmine]"
    end

    rvm_shell "#{name} rake generate_session_store" do
      ruby_string rvm_name
      user 'root'
      cwd path

      #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with `user_rvm`! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
      code <<-EOH
      export RAILS_ENV=production
      export REDMINE_LANG=ja
      rake --trace generate_session_store
      EOH
      not_if "test -f #{path}/config/initializers/session_store.rb"
    end

    rvm_shell "#{name} rake db:create" do
      ruby_string rvm_name
      user 'root'
      cwd path

      #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with `user_rvm`! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
      code <<-EOH
      export RAILS_ENV=production
      export REDMINE_LANG=ja
      rake --trace db:create
      EOH
      not_if "echo show tables|mysql -u root -p#{node.rvm_redmine.db.password} #{node.rvm_redmine.db.dbname}"
    end

    rvm_shell "#{name} load_default_data" do
      action :nothing
      ruby_string rvm_name
      user 'root'
      cwd path

      #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with user_rvm! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
      code <<-EOH
      export RAILS_ENV=production
      export REDMINE_LANG=ja
      rake --trace redmine:load_default_data
      EOH
      #not_if TODO
    end

  end

end
