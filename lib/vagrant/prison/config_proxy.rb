class Vagrant::Prison
  # this is a sort-of proc-to-ast with certain constraints only available to
  # "dsls" which configure things
  #
  # * blocks yielded to never care about the return value
  # * blocks only yield one argument
  # * it's presumed the yielded argument will be acted on through method calls
  # * method chains can be re-evaluated in any order, as long as the chain is
  #   preserved
  class ConfigProxy
    def initialize
      @hash = { }
    end

    def method_missing(sym, *args)
      @hash[sym] ||= []
      yield_proxy = ConfigProxy.new
      new_proxy   = ConfigProxy.new
      @hash[sym].push(
        { 
          :args => args,
          :yields => yield_proxy, 
          :retval => new_proxy 
        }
      )

      if block_given?
        yield yield_proxy
      end

      return new_proxy
    end

    def eval(object)
      @hash.each do |key, values|
        values.each do |value|
          retval =  if value[:yields].__has_statements__
                      object.send(key, *value[:args]) do |obj|
                        value[:yields].eval(obj)
                      end
                    else
                      object.send(key, *value[:args])
                    end

          if value[:retval].__has_statements__
            value[:retval].eval(retval)
          end
        end
      end
    end

    def __has_statements__
      @hash.keys.count > 0
    end

    def inspect(indent = 0)
      ret_str = ""
      do_indent = " " * indent
      @hash.each do |key, values|
        ret_str += do_indent + key.inspect
        ret_str += do_indent + " => [\n"
        values.each do |value|
          ret_str += do_indent + "{\n"
          if value[:args]
            ret_str += do_indent + " " + :args.inspect + " => " + value[:args].inspect + "\n"
          end
          [:yields, :retval].each do |blah|
            if value[blah].__has_statements__
              ret_str += do_indent + " " + blah.inspect + " =>\n" + value[blah].inspect(indent + 3) + "\n"
            end
          end
          ret_str += do_indent + "}\n"
        end
      end

      return ret_str
    end
  end
end
