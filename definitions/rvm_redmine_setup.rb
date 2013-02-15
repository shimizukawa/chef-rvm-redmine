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

define :rvm_redmine_setup, :action => :setup, :rvm_name => '@redmine', :rvm_home => nil, :owner => 'root', :group => 'root', :install_prefix => '/usr/local', :archive_file => 'redmine-1.4.2.tar.gz' do
  name = params[:name]
  rvm_name = params[:rvm_name]
  rvm_home = params[:rvm_home]
  owner = params[:owner]
  group = params[:group]
  install_prefix = params[:install_prefix]
  path = "#{install_prefix}/#{name}"
  archive_dir = Chef::Config[:file_cache_path]
  archive_file = params[:archive_file]
  install_target = "#{install_prefix}/#{path}/redmine.sh"

  if node.rvm_redmine.archive_url_base
    archive_src = "#{node.rvm_redmine.archive_url_base}/#{archive_file}"
  else
    archive_src = "http://rubyforge.org/frs/download.php/#{node.rvm_redmine.dl_id}/#{archive_file}"
  end


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
      notifies :run, "execute[extract-#{name}]"
    end

    execute "extract-#{name}" do
      #action :nothing
      user owner
      cwd install_prefix
      command "tar zxf #{archive_dir}/#{archive_file}"
      not_if "test -d #{path} -o -f #{install_target}"
      notifies :create, "template[place-#{name}-database.yml]"
    end


    template "place-#{name}-database.yml" do
      #action :nothing
      owner owner
      group group
      source "database.yml.erb"
      path "#{path}/config/database.yml"
      mode "0644"
      notifies :create, "template[place-#{name}-Gemfile.local]"
    end

    template "place-#{name}-Gemfile.local" do
      #action :nothing
      owner owner
      group group
      source "Gemfile.local"
      path "#{path}/Gemfile.local"
      mode "0644"
      notifies :create, "template[place-#{name}-additional_environment.rb]"
    end

    template "place-#{name}-additional_environment.rb" do
      #action :nothing
      owner owner
      group group
      source "additional_environment.rb"
      path "#{path}/config/additional_environment.rb"
      mode "0644"
      notifies :run, "rvm_shell[bundle install #{name}]"
    end

    rvm_shell "bundle install #{name}" do
      #action :nothing
      ruby_string rvm_name
      cwd   path
      code "bundle install --without development test pg postgresql sqlite rmagick"
      #not_if TODO
      notifies :run, "rvm_shell[setup #{name}]"
    end

    rvm_shell "setup #{name}" do
      #action :nothing
      ruby_string rvm_name
      user owner
      cwd   path

      #environment({'RAILS_ENV' => 'production', 'REDMINE_LANG' => 'ja'})  #this work only with use_rvm! see https://github.com/fnichol/chef-rvm/blob/master/providers/shell.rb#L78
      code <<-EOH
      gem -v
      export RAILS_ENV=production
      export REDMINE_LANG=ja
      rake --trace db:create
      rake --trace generate_session_store
      EOH
      #not_if TODO
      notifies :run, "rvm_shell[#{name} db:migrate]", :immediately
      notifies :create, "template[place-#{name}-unicorn.config.rb]"
    end

    template "place-#{name}-unicorn.config.rb" do
      #action :nothing
      owner owner
      group group
      source "unicorn.config.rb.erb"
      path "#{path}/config/unicorn.config.rb"
      mode "0644"
      variables({
        :path => path
      })
      notifies :create, "template[place-#{name}-redmine.sh]"
    end

    template "place-#{name}-redmine.sh" do
      #action :nothing
      owner owner
      group group
      source "redmine.sh.erb"
      path "#{path}/redmine.sh"
      mode "0755"
      variables({
        :path => path,
        :rvm_name => rvm_name
      })
      notifies :create, "template[place-#{name}-init.d]"
    end

    template "place-#{name}-init.d" do
      #action :nothing
      path "/etc/init.d/redmine"
      source "init.d.redmine.erb"
      owner "root"
      group "root"
      mode "0755"
      variables({
        :path => path,
        :user => owner,
        :user_home => rvm_home
      })
      notifies :enable, "service[redmine]", :immediately
      notifies :start, "service[redmine]"
    end

  end

end
