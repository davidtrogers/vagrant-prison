require 'vagrant'
require 'vagrant/sandbox/version'
require 'vagrant/sandbox/config_proxy'
require 'fileutils'
require 'tempfile'
require 'erb'

Vagrant::Sandbox::Vagrantfile = <<-EOF
dumped_config = <%= @config.inspect %>

Vagrant::Config.run do |config|
  Marshal.load(dumped_config).eval(config)
end
EOF

class Vagrant::Sandbox
  attr_reader :dir

  #
  # Construct a new Vagrant sandbox. Takes two arguments: (the third should be
  # avoided)
  #
  # * `dir` is a directory name; it will be created for you if it does not
  #   already exist, and if left as nil it will be created using Dir.mktmpdir.
  # * if `cleanup_on_exit` is set to true, vagrant will be told to destroy the
  #   environment and the sandbox directory will be deleted. This occurs when
  #   the program exits, or when this object is garbage collected, which ever
  #   comes first.
  #
  def initialize(dir=nil, cleanup_on_exit=true, env=nil)
    @dir    = dir ||= Dir.mktmpdir
    @initial_config = nil
    @env    = env
    @cleanup_on_exit = cleanup_on_exit
  end

  def self.cleanup(dir, env)
    Vagrant::Sandbox.new(dir, false, env).cleanup
  end

  #
  # Clean up the sandbox. Vagrant will be asked to destroy the environment and
  # the directory will be deleted.
  #
  def cleanup
    destroy
    FileUtils.rm_r(dir)
  end

  #
  # Configures a Vagrantfile.
  #
  # You can do this two ways: either supply a string of Ruby to configure the
  # object, or a block.
  #
  # For example:
  #
  #     obj.configure <<-EOF
  #     Vagrant::Config.run do |config|
  #     config.vm.box = "ubuntu"
  #
  #     config.vm.define :test, :primary => true do |test_config|
  #       test_config.vm.network :hostonly, "192.168.33.10"
  #     end
  #     EOF
  #
  # OR
  #
  #     obj.configure do |config|
  #       config.vm.box = "ubuntu"
  #
  #       config.vm.define :test, :primary => true do |test_config|
  #         test_config.vm.network :hostonly, "192.168.33.10"
  #       end
  #     end
  #
  def configure(arg=nil)
    if arg
      @initial_config = arg
    elsif block_given?
      @initial_config ||= ConfigProxy.new
      yield @initial_config
    else
      raise "You must supply a string of configuration or a block."
    end
  end

  #
  # Construct the sandbox. This:
  #
  # * creates your directory (if necessary)
  # * supplies a pre-built Vagrantfile with your configuration supplied from
  #   the `configure` call
  # * returns a Vagrant::Environment referencing these items
  # * if you set `cleanup_on_exit` in the constructor, runs `cleanup` on
  #   garbage collection of this object or program exit, which ever comes first.
  #
  def construct(env_opts={})
    FileUtils.mkdir_p(dir)

    to_write = if @initial_config.kind_of?(ConfigProxy)
                 @config = Marshal.dump(@initial_config)
                 ERB.new(Vagrant::Sandbox::Vagrantfile).result(binding)
               else
                 @initial_config
               end

    File.binwrite(File.join(dir, "Vagrantfile"), to_write)

    @env = Vagrant::Environment.new(env_opts.merge(:cwd => dir))

    if @cleanup_on_exit
      # clean up after garbage collection or if the system exits
      ObjectSpace.define_finalizer(self) do
        Vagrant::Sandbox.cleanup(dir, env)
      end

      obj = self # look ma, closures

      at_exit do
        obj.cleanup
      end
    end

    return @env
  end

  #
  # Destroy the environment. This does not delete the directory, please see
  # `cleanup` for a one-shot way to orchestrate that.
  #
  def destroy
    Dir.chdir(dir)
    Vagrant::Command::Destroy.new(%w[-f], @env).execute
  end
end
