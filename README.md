# Rubyric

Rubyric is an online tool in which you can create courses and assignments,
receive submissions and assess them by using rubrics. More information about
Rubyric and how to use it can be found [here](doc/rubyric.md).

## Environment
Install ruby 2.3.1 or higher. One way of installing these versions in Linux is
by using one of the following Ruby version management tools,
[rvm or rbenv](https://linuxize.com/post/how-to-install-ruby-on-ubuntu-20-04/).

If you followed the guides provided in the above link. You would find yourself
adding some scripts to the `~/.bashrc` file. However, you can use your favourite
shell.

You can always verify your default shell by typing the following command in your
terminal

```sh
ls -l /proc/$$/exe
```

or

```sh
echo $SHELL
```

### Ruby and rails environment

Update the RubyGems version

```sh
sudo gem install rubygems-update
```

Install rails with the following command

```sh
gem install rails -v 5.0.2
```

or

```sh
sudo gem install rails -v 5.0.2
```

Before you start *installing any Gem*, it is important to check the Bundler
version. The current version of Rubyric requires a Bundler version (>= 1.3.0,
< 2.0). In addition, it is worth noting that Rubyric requires a version
<= 1.4.X of the [big-decimal](https://github.com/ruby/bigdecimal) gem.

Verify Bundler version
```sh
bundler -v
```
and/or
```sh
gem list bundler
```

If you have a different Bundler version which is not compatible with the Rubyric
ecosystem, you must uninstall it and install a compatible version. The command
for installing the Bundler is similar to the one below. However, you can choose
the most suitable [version](https://rubygems.org/gems/bundler/versions) for you.

```sh
gem install bundler -v 1.17.3
```

### Database

Rubyric uses a PostgreSQL database. Therefore, you must install PostgreSQL and
create a user.

```sh
sudo apt-get install postgresql
sudo -u postgres createuser --interactive
```

### Additional packages

Rubyric also requires pdfinfo, ghostscript and libpq-dev to work.
```sh
sudo apt-get install poppler-utils ghostscript libpq-dev
```

## Download Rubyric and Install Gems

### Clone the Rubyric project

Now it is time to clone the Rubyric project and install the required gems. First,
clone the project from [Github](https://github.com/Aalto-LeTech/rubyric). You can
use either SSH or HTTPS.

```sh
git clone git@github.com:Aalto-LeTech/rubyric.git && cd rubyric
```

or

```sh
git clone https://github.com/Aalto-LeTech/rubyric.git && cd rubyric
```

### Install gems

Once you have a copy of the Rubyric project, you can proceed to install the
required gems.

```sh
bundle install
```

**Side note:** Some packages will require manual installation, and some other
will require some manual intervention related to compatibility issues. You can
find some of the most recurrent problems in the
[Troubleshooting section](#troubleshooting)


## Configure Rubyric

### Local configuration

Now that you have installed  the required software and tools, you must configure
your Rubyric project to run in your computer.

```sh
cp config/initializers/secret_token.rb.base config/initializers/secret_token.rb
cp config/initializers/settings.rb.base config/initializers/settings.rb
cp config/database.yml.base config/database.yml
```

### Create a database and username

The first step is to create the database and the rails user
```sh
sudo -u postgres createdb -O rails rubyric
```

Now, we will create a user called "rails" with password "rails". This particular
user is used for testing purposes.

```sh
sudo -u postgres psql
```
The PostgreSQL console is indicated by `postgres=#` prompt. At the PostgreSQL
console enter the following command, which will assist you in assigning the
password to the "rails" user.

```sh
postgres=# \password rails
```
Enter the desired password (in this case, your password should be "rails") at
the prompt, and confirm it.

Now you may need to exit the PostgreSQL console by entering the `\q` command and
pressing the enter key.

```sh
postgres=# \q
```

It is necessary to know that we are using the "rails" user only for developing
purposes. In a production environment, it is better to use other means to improve
security during the [database authentication](https://www.postgresql.org/docs/9.6/auth-methods.html).

**Side note:** The rails user can be also modified in the [database.yaml.base](config/database.yml.base)
file, and subsequently in the [database.yaml file](#local-configuration) if you wish.

### Initialize database

```sh
rails db:setup
```

It is possible that the following error appears, while running the above command.

```sh
undefined method `yaml_as` for ActiveRecord::Base::Class
Did you mean? yaml_tag
```
Therefore, you may run the following command and try again.

```sh
bundle update delayed_job
```

### Make user Rubyric admin
Open rails console
```sh
rails c
```
Find a user and update admin attribute. You can find user by their user id with
User.find(id) or by some other attributes with User.find_by(attribute: value).
```sh
User.find(id).update_attributes(admin: '1')
```
or you can create a new user as admin
```sh
User.create(email: email, password: password, admin: '1')
```

## Run Rubyric

In order to run Rubyric on your computer, you should start the server by typing
the following command.

```sh
bin/delayed_job start
rails server
```

Once the server is started, you can now initialise Rubyric at http://localhost:3000.

If you are planning to run Rubyric along with A+, you may prefer to run Rubyric
in a different port than the port 3000, e.g. using port 3030. More information
about local development with A can be found in the
[Documentation.](https://github.com/Aalto-LeTech/rubyric/blob/master/doc/user_guide.md#a-connected-courses-and-exercises)

```sh
bin/delayed_job start
rails server -p 3030
```

You can now access Rubyric at http://localhost:3030.

## Troubleshooting

* If you find the following error while trying to run Rubyric.

  ```sh
  Bundler could not find compatible versions for gem "bundler":
    In Gemfile:
      rails (= 5.0.2) was resolved to 5.0.2, which depends on
        bundler (>= 1.3.0, < 2.0)

    Current Bundler version:
      bundler (2.1.2)

  This Gemfile requires a different version of Bundler.
  Perhaps you need to update Bundler by running `gem install bundler`?

  Could not find gem 'bundler (>= 1.3.0, < 2.0)', which is required by gem  'rails (= 5.0.2)', in any of the sources.
  ```

  You should try to [uninstall the incompatible Bundler and install one of the recommended ones](https://stackoverflow.com/questions/54901077/bundle-install-could-not-find-compatible-versions-for-gem-bundler).

  ```
  gem install bundler -v 1.17.3
  gem uninstall bundler -v 2.0.1
  bundle update --bundler
  bundle install
  ```

* If the following error appears

  ```sh
  undefined method `yaml_as` for ActiveRecord::Base::Class
  Did you mean? yaml_tag
  ```
  you may run the following command.

  ```sh
  bundle update delayed_job
  ```

  In addition, you could google this compatibility issue, and try to find the
  version of the `delayed_job` that solves this issue.

* Another common error is related to the **bigdecimal** gem. As mentioned above,
  you should install the ruby compatible versions. The bigdecimal versions allowed
  in Rubyric are any version from [1.3.5](https://rubygems.org/gems/bigdecimal/versions/1.3.5) to
  [1.4.4](https://rubygems.org/gems/bigdecimal/versions/1.4.4). Therefore, if
  the following error appears.

  ```sh
  NoMethodError: undefined method `new' for BigDecimal:Class
  ```

  you should install one of the ruby compatible versions.


  | version | characteristics | Supported ruby version range |
  | ------- | --------------- | ----------------------- |
  | 2.0.0   | You cannot use BigDecimal.new and do subclassing | 2.4 .. |
  | 1.4.x   | BigDecimal.new and subclassing always prints a warning. | 2.3 .. 2.6 |
  | 1.3.5   | You can use BigDecimal.new and subclassing without warning | .. 2.5 |

  For example, you could install the bigdecimal version 1.3.5.

  ```sh
  gem install bigdecimal -v 1.3.5
  ```

* In case you are having trouble with the version of the bundle you can
  [verify and delete the extra bundlers](https://stackoverflow.com/questions/57306611/how-can-i-remove-default-version-of-bundler)

* Another common problem that can appear while trying to run Rubyric locally is
  related to the [i18n](https://rubygems.org/gems/i18n/versions/0.9.5) gem. If
  you cross with the following error message.
  ```sh
  Could not find i18n-0.9.5 in any of the sources
  Run `bundle install` to install missing gems.
  ```
  Try installing the i18n gem version `i18n-0.9.5`.
  ```sh
  gem install i18n -v 0.9.5
  ```
### Tested environments

If you are having issues with version and compatibility of packages, you can try
to set up the following environments which have been tested.

Tested in Ubuntu 20.04 and 18.04.
```
About your application's environment
Rails version             5.0.2
Ruby version              2.5.8-p224 (x86_64-linux)
RubyGems version          3.1.4
Rack version              2.0.1
```

You can check the different version of the packages in which you intend to run
Rubyric by using the `rake about` command.

```sh
rake about
```

or

```sh
bundle exec rake about
```
