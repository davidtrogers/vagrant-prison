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

  def initialize(dir=nil, cleanup_on_exit=true, env=nil)
    @dir    = dir ||= Dir.mktmpdir
    puts @dir
    @initial_config = nil
    @env    = env
    @cleanup_on_exit = cleanup_on_exit
  end

  def self.cleanup(dir, env)
    Vagrant::Sandbox.new(dir, false, env).cleanup
  end

  def cleanup
    destroy
    FileUtils.rm_r(dir)
  end

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

  def destroy
    Dir.chdir(dir)
    Vagrant::Command::Destroy.new(%w[-f], @env).execute
  end
end
