module Cryouxn
  Device.new :system do |d|
    d.listen 0x06 { |b, vm| set_hi vm.metadata, b }
    d.listen 0x07 { |b, vm| set_lo vm.metadata, b }

    {% for addr, i in 0x08..0x0d %}
      d.listen({{addr}}) { |b, vm|
        vm.screen.colors[{{i}}] = b
        vm.screen.update_palette
        {% if i == 5 %} vm.screen.blank {% end %}
      }
    {% end %}

    d.listen 0x0e { |_, vm| vm.uxn.show_stacks }
    d.listen 0x0f { |b, vm| vm.uxn.status = b }
  end
end
