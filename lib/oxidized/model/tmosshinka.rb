class TMOSShinka < Oxidized::Model

  # prompt /^\[?[\w:\/\-]*\@?[\w:\/\-]*\]?\s?[\w]*\s?[\w]+\s?[#>]\s?$/
  prompt /^\[?[\w:\/\-]*\@[\w:\s\-\/]*\]?\s?[\w]*\s?[\w]+\s?[#>]\s?$/
  comment  '# '

  cmd :secret do |cfg|
    cfg.gsub!(/^([\s\t]*)secret \S+/, '\1secret <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)password \S+/, '\1password <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)passphrase \S+/, '\1passphrase <secret removed>')
    cfg.gsub!(/community \S+/, 'community <secret removed>')
    cfg.gsub!(/community-name \S+/, 'community-name <secret removed>')
    cfg.gsub!(/^([\s\t]*\S*)encrypted \S+$/, '\1encrypted <secret removed>')
    cfg
  end

  cmd('tmsh -q show sys version') { |cfg| comment cfg }

  cmd('tmsh -q show sys software') { |cfg| comment cfg }

  cmd 'tmsh -q show sys hardware field-fmt' do |cfg|
    cfg.gsub!(/fan-speed (\S+)/, '')
    cfg.gsub!(/temperature (\S+)/, '')
    comment cfg
  end
  
  cmd 'cat /config/bigip.license' do |cfg|
    comment cfg
  end

  expect /^[#-]+\[?[\w:\/\-]*\@[\w:\s\-\/]*\]?\s?[\w]*\s?[\w]+\s?[#>]\s?$/ do |data, re|
    send "\n"
    data.sub re, ''
  end

  cmd 'tmsh -q list' do |cfg|
    cfg.gsub!(/state (up|down|checking|irule-down)/, '')
    cfg.gsub!(/errors (\d+)/, '')
    cfg
  end

  cmd('tmsh -q list net route all') { |cfg| comment cfg }

  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.crt') { |cfg| comment cfg }

  cmd('/bin/ls --full-time --color=never /config/ssl/ssl.key') { |cfg| comment cfg }

  cmd 'tmsh -q show running-config sys db all-properties' do |cfg|
    cfg.gsub!(/sys db configsync.localconfigtime {[^}]+}/m, '')
    cfg.gsub!(/sys db gtm.configtime {[^}]+}/m, '')
    cfg.gsub!(/sys db ltm.configtime {[^}]+}/m, '')
    comment cfg
  end

  cmd('cat /config/partitions/*/bigip.conf') { |cfg| comment cfg }

  cfg :ssh do
    if vars :push_files
      post_login do
        filename = @node.name
        filename = filename.gsub(/[^0-9A-Za-z.\-]/, '')
        filename.downcase!
        filename += '_ucs_'
        filename += Time.now.strftime('%Y%m%d%H%M%S')
        filename
        Oxidized.logger.debug "push push push #{filename}"
        cmd "tmsh save /sys ucs #{filename}.ucs"
        cmd "scp /var/local/ucs/#{filename}.ucs #{vars(:push_user)}@#{vars(:push_address)}:#{vars(:push_path)}#{filename}.ucs", /^[\w]+@.*:\s?$/
        cmd vars(:push_pass)
      end
    end
    pre_logout "exit"
    # end
    # exec true  # don't run shell, run each command in exec channel
  end

end