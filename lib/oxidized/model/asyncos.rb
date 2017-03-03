class AsyncOS < Oxidized::Model
  
  # Cisco AsyncOS - Cisco C100V Email Security Virtual Appliance

  prompt /^[^<][\w*\.]+>\s?$/

  comment  '--- '

  expect /^\[[0-9]\]>\s?$/ do |data, re|
    send "2\n"
    data.sub re, ''
  end

  expect /-Press Any Key For More-\s?$/ do |data, re|
    send ' '
    data.sub re, ''
  end

  cmd :all do |cfg|
    cfg.each_line.to_a[9..-2].join
  end

  cmd 'showconfig' do |cfg|
    cfg
  end

  cfg :ssh do
    pre_logout do
      send "exit\n"
    end
  end

end