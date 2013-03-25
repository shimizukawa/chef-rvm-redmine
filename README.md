rvm-redmine (rvm aware) Cookbook
==================================

This cookbook install redmine into rvm environment.

Requirements
------------

#### cookbook
- `apache2`
- `imagemagick`
- `rvm`

Attributes
----------
environment

`node['rvm_redmine']['rvm_name']` - default is "@redmine"
`node['rvm_redmine']['user']` - default is "www-data"
`node['rvm_redmine']['group']` - default is "www-data"
`node['rvm_redmine']['user_home']` - default is "/var/www/www-data"
`node['rvm_redmine']['dl_id']   ` - default is "76130"
`node['rvm_redmine']['version']` - default is "1.4.2"
`node['rvm_redmine']['name']` - default is "redmine-1.4.2"
`node['rvm_redmine']['file']` - default is "redmine-1.4.2.tar.gz"
`node['rvm_redmine']['archive']` - default is "/var/www/www-data/redmine-1.4.2.tar.gz"
`node['rvm_redmine']['path']` - default is "/var/www/www-data/redmine-1.4.2"

database connection

`node['rvm_redmine']['db']['type']` - default is "mysql"
`node['rvm_redmine']['db']['user']` - default is "root"
`node['rvm_redmine']['db']['password']` - default is auto generated password that store into database.yml
`node['rvm_redmine']['db']['hostname']` - default is "localhost"
`node['rvm_redmine']['db']['dbname']` - default is "redmine"

apache

`node['rvm_redmine']['hostname']` - default is 'localhost'
`node['rvm_redmine']['hostname_aliases']` - default is []

unicorn (see also https://github.com/opscode-cookbooks/unicorn )

`node['rvm_redmine']['unicorn']['port']` - default is '10080'
`node["rvm_redmine"]["unicorn"]["options"]` - default is `[["tcp_nopush", "true"], ["backlog", "64"]]`
`node['rvm_redmine']['unicorn']['worker_timeout']` - default is '30'
`node['rvm_redmine']['unicorn']['worker_processes']` - default is '4'
`node['rvm_redmine']['unicorn']['preload_app']` - default is true
`node['rvm_redmine']['unicorn']['unicorn_command_line']` - default is nil
`node['rvm_redmine']['unicorn']['forked_user']` - default is nil
`node['rvm_redmine']['unicorn']['forked_group']` - default is nil
`node['rvm_redmine']['unicorn']['before_exec']` - default is `'self[:logger].formatter = proc{|severity, datetime, progname, message| "#{datetime}: #{message}\n"}'`
`node['rvm_redmine']['unicorn']['before_fork']` - default is `'defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!'`
`node['rvm_redmine']['unicorn']['after_fork']` - default is `'defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection'`
`node['rvm_redmine']['unicorn']['copy_on_write']` - default is nil
`node['rvm_redmine']['unicorn']['enable_stats']` - default is nil


Usage
-----
#### rvm-redmine::default

Include `rvm-redmine` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[rvm-redmine]"
  ]
}
```

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: Takayuki Shimizukawa
License: Apache 2.0
