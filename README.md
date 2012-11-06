# Vagrant::Prison

Drive vagrant configuration directly from your test suite, rakefiles, etc.

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

# if you don't set :ui_class here, it still works, it just provides no output.
Vagrant::Command::Up.new(
  [], 
  prison.construct(:ui_class => Vagrant::UI::Basic)
).execute

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
