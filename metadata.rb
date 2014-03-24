maintainer       "Takayuki SHIMIZUKAWA"
maintainer_email "shimizukawa@gmail.com"
license          "Apache 2.0"
description      "Installs/Configures redmine"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"

recipe "rvm-redmine", "install redmine into gem environment."
recipe "rvm-redmine::apache", "install apache and setup proxy to redmine."

depends "openssl"
depends "mysql"
depends "apache2"
depends "imagemagick"
depends "rvm"
depends "unicorn"

supports "ubuntu"
