module Cryouxn
  class Device
    class_getter devices = Hash(Symbol, Device).new
    getter listeners = Hash(Byte, Listener).new
    getter reporters = Hash(Byte, Reporter).new

    def initialize(name)
      @@devices[name] = self
      yield self
    end

    def listen(*addrs, &body : Listener)
      addrs.each { |a| @listeners[0u8 | a] = body }
    end

    def report(*addrs, &body : Reporter)
      addrs.each { |a| @reporters[0u8 | a] = body }
    end

    def self.[](name)
      @@devices[name]
    end

    def self.all
      @@devices.keys
    end
  end
end
