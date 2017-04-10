class GaiaOSAddBackup < Oxidized::Model

  # CheckPoint - Gaia OS Model
  
  # Gaia Prompt
  prompt /^([\[\]\w.@:-]+[#>]\s?)$/

  # Comment tag
  comment  '# '


  cmd :all do |cfg|
    cfg = cfg.each_line.to_a[1..-2].join
  end
  
  # send 'add backup scp ' 
  
  cmd :secret do |cfg|
    cfg.gsub! /^(set expert-password-hash ).*/, '\1<EXPERT PASSWORD REMOVED>'
    cfg.gsub! /^(set user \S+ password-hash ).*/,'\1<USER PASSWORD REMOVED>'
    cfg.gsub! /^(set ospf .* secret ).*/,'\1<OSPF KEY REMOVED>'
    cfg.gsub! /^(set snmp community )(.*)( read-only.*)/,'\1<SNMP COMMUNITY REMOVED>\3'
    cfg.gsub! /^(add snmp .* community )(.*)(\S?.*)/,'\1<SNMP COMMUNITY REMOVED>\3'
    cfg.gsub! /(auth|privacy)(-pass-phrase-hashed )(\S*)/,'\1-pass-phrase-hashed <SNMP PASS-PHRASE REMOVED>'
    cfg
  end

  cmd 'show asset all' do |cfg|
    comment cfg
  end

  cmd 'show version all' do |cfg|
    comment cfg
  end

  cmd 'show configuration' do |cfg|
    cfg.gsub! /^# Exported by \S+ on .*/, '# '
    cfg
  end

  cfg :ssh do
    # User shell must be /etc/cli.sh
    post_login 'set clienv rows 0'
    if vars(:push_files)
      pre_logout do
        filename = @node.name
        filename = filename.gsub(/[^0-9A-Za-z.\-]/, '')
        filename.downcase!
        filename += '_addbackup_'
        filename += Time.now.strftime('%Y%m%d%H%M%S')
        filename
        cmd "add backup scp ip #{vars(:push_address)} path #{vars(:push_path)} username #{vars(:push_user)} password #{vars(:push_pass)}"
      end
    end
    pre_logout 'exit'
  end
end