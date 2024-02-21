macro dtf(port, value)
  d.report {{port}} { 0u8 | (Time.local.{{value}}) }
end

Cryouxn::Device.new :datetime do |d|
  dtf 0xc0, year >> 8
  dtf 0xc1, year & 0xff
  dtf 0xc2, month - 1
  dtf 0xc3, day
  dtf 0xc4, hour
  dtf 0xc5, minute
  dtf 0xc6, second
  dtf 0xc7, day_of_week.value
  dtf 0xc8, day_of_year >> 8
  dtf 0xc9, day_of_year & 0xff
  dtf 0xca, zone.dst? ? 1u8 : 0u8
end
