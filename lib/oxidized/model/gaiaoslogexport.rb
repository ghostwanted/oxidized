class GaiaOSLogExport < Oxidized::Model

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
    if vars :enable
      post_login do
        send "expert\n"
        cmd vars(:enable)
        send "TMOUT=0\n"
      end
    end
    if vars(:push_files)
      pre_logout do
        filename = @node.name
        filename = filename.gsub(/[^0-9A-Za-z.\-]/, '')
        filename.downcase!
        logname = filename
        timestamp = Time.now.strftime('%Y%m%d%H%M%S')
        logname += '_logs_'
        logname += timestamp
        cmd "find $FWDIR/log/\`/bin/date --date='yesterday' +%Y-%m-%d\`* -exec tar -uvf #{logname}.tar {} \\;"
        cmd "gzip #{logname}.tar"
        cmd "scp ./#{logname}.tar.gz #{vars(:push_user)}@#{vars(:push_address)}:#{vars(:push_path)}", /^.*password:\s?$/
        cmd "#{vars(:push_pass)}"
        cmd "rm ./#{logname}.tar.gz"

        cmd "find $FWDIR/log/*\".log\" -mtime +20 -exec rm {} \\;"
        cmd "find $FWDIR/log/*\".logaccount_ptr\" -mtime +20 -exec rm {} \\;"
        cmd "find $FWDIR/log/*\".loginitial_ptr\" -mtime +20 -exec rm {} \\;"
        cmd "find $FWDIR/log/*\".logptr\" -mtime +20 -exec rm {} \\;"
        # cmd "find $FWDIR/log/*\".tar\" -mtime +20 -exec rm {} \\;"
        cmd "find $FWDIR/log/*\".log_stats\" -mtime +20 -exec rm {} \\;"
        cmd "find $FWDIR/log/blob -type d -ctime +20 -exec rm -rf {} \\;"

        send "exit\n"
      end
    end
    pre_logout 'exit'
  end
end