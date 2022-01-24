#!/usr/local/bin/ruby
# !/usr/local/bin/ruby

# Test of Fetch of the site_angles from the WIKK RPC server.

load '/wikk/etc/wikk.conf'
require 'wikk_json'
require 'wikk_webbrowser'

class RPC
  def initialize(url:, identity: nil, auth: nil)
    @cookies = []
    @url = url
    @identity = identity
    @auth = auth
  end

  def self.rpc(url:, query:, identity: nil, auth: nil)
    WIKK::WebBrowser.https_session(host: 'www.wikarekare.org', verify_cert: false) do |ws|
      response = ws.post_page(query: url,
                              # authorization: wb.bearer_authorization(token: @auth_token),
                              content_type: 'application/json',
                              data: query.to_j
                               # extra_headers: { "x-apikey"=> NIWA_API_KEY }
                             )
      return JSON.parse(response)
    end
  end
end

def dump_site_angles
  begin
    r = RPC.rpc( query: { 'method' => 'Site_Angles.read',
                          'kwparams' => {
                            'select_on' => {},
                            'set' => {},
                            'result' => []
                          },
                          'id' => "#{Time.now.to_i}",
                          'version' => '1.1'
                        },
                 url: 'ruby/rpc.rbx'
               )
    return if r.nil?

    puts '{'
    r['result'].each do |k, v|
      puts "  \"#{k}\": {"
      puts "    distance: #{v['distance']},"
      puts "    min_dec: #{v['min_dec']},"
      puts "    max_dec: #{v['max_dec']},"
      puts "    max_angle: #{v['max_angle']},"
      puts "    best_angle: #{v['best_angle']},"

      puts '    data: ['
      v['data'].each do |v2|
        puts "    { name: \"#{v2['name']}\", type: \"#{v2['type']}\", mode: \"#{v2['mode']}\", line: { color: \"#{v2['line']['color']}\" }, theta: [0,#{v2['theta']}], r: [0,#{v2['r']}] },"
      end
      puts '  ],'

      puts '    data2: ['
      v['data2'].each do |v2|
        puts "    { name: \"#{v2['name']}\", type: \"#{v2['type']}\", mode: \"#{v2['mode']}\", line: { color: \"#{v2['line']['color']}\" }, theta: [0,#{v2['theta']}], r: [0,#{v2['r']}] },"
      end
      puts '    ]'
      puts '  },'
    end
    puts '}'
  rescue StandardError => e
    puts e.message
  end
end

dump_site_angles
