class GaiaOS3 < Oxidized::Model

  # CheckPoint - Gaia OS Model
  
  # Gaia Prompt
  prompt /^([\[\]\w.@:-]+[#>]\s?)$/

  # Comment tag
  comment  '# '

  cmd :all do |cfg|
    cfg = cfg.each_line.to_a[1..-2].join
  end
  
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
    post_login do 
      timeout = @node.timeout
      Oxidized.logger.debug "TIMEOUT: #{@node.name} #{timeout}"
    end
    # post_login 'add backup scp ip 10.1.0.35 path /root/ username root password S_shinka_A'
    if vars :enable
      pre_logout do
        send "expert\n"
        cmd vars(:enable)
        cmd '$FWDIR/bin/upgrade_tools/migrate export -n /home/admin/fwdb_from_oxidized'
        cmd 'scp /home/admin/fwdb_from_oxidized.tgz root@'+vars(:tftp_address)+':/root/', /^[\w]+@.*:\s?$/
        cmd "S_shinka_A"
        cmd 'exit'
      end
    end
    # post_login 
    # pre_logout 'exit'
    pre_logout 'exit'
  end

end
