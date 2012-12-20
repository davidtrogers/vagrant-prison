# Vagrant::Prison

Drive vagrant configuration directly from your test suite, rakefiles, etc.
Basically anywhere you can write ruby, you can drive Vagrant.

## Reasoning and Use Cases

When you create and configure a `Vagrantfile`, the internals of Vagrant coerce
this into a `Vagrant::Environment` object that has a number of properties.
Unfortunately, much of Vagrant's design runs under the expectation that all
this data comes from a `Vagrantfile` on disk in the current working directory,
and therefore `Vagrant::Environment` objects can't be created programmatically
-- a problem when you have a desire to create them dynamically and templating
Vagrantfiles all over the place isn't really a solution. 

For example, if you want to maintain parity between configuration supplied to
Vagrant and your tool that uses Vagrant, or if you want to allow the user to
supply additional code to be injected into Vagrantfiles and ensure the code is
not only syntactically correct, but is evaluated in the right context. 
Additionally prison objects can be modified and appended to post hoc, which has
some nice advantages from a flexibility standpoint.

You can also marshal `Vagrant::Prison` objects -- something you can't do with
`Vagrant::Environment`. What this is good for is left as an exercise to the
reader.

Vagrant::Prison is to Vagrant what unix jails are ... to unix. It fakes out
Vagrant well enough to think it's working with a traditional `Vagrantfile`, but
it's actually working with something emulating one, without actually modifying
the internals of Vagrant itself. It accomplishes this with recording proxies
that are played back to Vagrant when it starts.

Vagrant::Prison is **not** threadsafe. This is actually a limitation of
Vagrant, but there's nothing we can or will do to work around it.

## Installation

Add this line to your application's Gemfile:

    gem 'vagrant-prison'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vagrant-prison

## Usage

See the documentation for Vagrant::Prison for extended usage, but here's an
example!

```ruby
# construct a vagrant environment from the configuration and start all the
# boxes within it. Upon exiting (via ^C), destroy the boxes and the directory.

require 'vagrant/prison'
prison = Vagrant::Prison.new

prison.configure do |config|
  config.vm.box = "ubuntu"

  config.vm.define :test, :primary => true do |test_config|
    test_config.vm.network :hostonly, "192.168.33.10"
  end
end

# here's a basic way to start your vms:

prison.start

# If you need more flexibility, all the internal Vagrant tooling works -- it
# has no idea it's working with a facsimile.
#
# note that if you don't set :ui_class here, it still works, it just provides
# no output.
Vagrant::Command::Up.new(
  [], 
  prison.construct(:ui_class => Vagrant::UI::Basic)
).execute

#
# Since we've configured it to destroy on exit here, sleep until someone hits
# ^C.
#
begin
  sleep
rescue Interrupt
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
