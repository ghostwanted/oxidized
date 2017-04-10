class GaiaOSAddBackupExp < Oxidized::Model

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

  cmd 'clish -c "show asset all"' do |cfg|
    comment cfg
  end

  cmd 'clish -c "show version all"' do |cfg|
    comment cfg
  end

  cmd 'clish -c "show configuration"' do |cfg|
    cfg.gsub! /^# Exported by \S+ on .*/, '# '
    cfg
  end

  cmd 'cat $FWDIR/boot/modules/fwkern.conf' do |cfg|
    comment cfg
  end

  cmd 'cat $PPKDIR/boot/modules/simkern.conf' do |cfg|
    comment cfg
  end

  cfg :ssh do
    # User shell must be /etc/cli.sh
    # post_login 'set clienv rows 0'
    if vars :enable
      post_login do
        send "expert\n"
        cmd vars(:enable)
	send "TMOUT=0\n"
      end
    end
    if vars(:push_files)
      pre_logout do
        # send "expert\n"
        # cmd vars(:enable)
        filename = @node.name
        filename = filename.gsub(/[^0-9A-Za-z.\-]/, '')
        filename.downcase!
        filename += '_addbackup_'
        filename += Time.now.strftime('%Y%m%d%H%M%S')
        filename
        cmd "backup -f #{filename}.tgz", /^.*\[y\]\?\s?$/
        cmd "y"
        cmd "scp /var/log/CPbackup/backups/#{filename}.tgz #{vars(:push_user)}@#{vars(:push_address)}:#{vars(:push_path)}", /^.*password:\s?$/
        cmd "#{vars(:push_pass)}"
        send "find /var/log/CPbackup/backups/*\".tgz\" -mtime +3 -exec rm {} \\;\n"
        send "exit\n"
        
        # expect /^There are no backup packages to remove.\s?$/ do |data, re|
        #   send "exit\n"
        # end
        # expect /^.*\[y\]\?\s?$/ do |data, re|
        #   send "y\n"
        # end
        # cmd "y"
        
        # cmd "backup --scp #{vars(:push_address)} #{vars(:push_user)} #{vars(:push_pass)} -path #{vars(:push_path)} #{filename}.tgz", /^.*\[y\]\?\s?$/
        # cmd "y\n"
        # cmd 'exit' 
        # cmd "add backup scp ip #{vars(:push_address)} path #{vars(:push_path)} username #{vars(:push_user)} password #{vars(:push_pass)}"
      end
    end
    pre_logout 'exit'
  end
end
