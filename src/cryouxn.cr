require "./cryouxn/types"
require "./cryouxn/**"

if path = ARGV[0]?
  if File.exists? path
    vm = Cryouxn::VM.new
    vm.load(path).run
  else
    STDERR.puts "No such file: '#{path}'"
    exit 1
  end
else
  STDERR.puts "usage: #{PROGRAM_NAME} <foo.rom/tal> [args...]"
  exit 1
end
