# Return Json formatted Antenna MSI files
class Antenna_msi < RPC
  def initialize(cgi, authenticated = false)
    super(cgi, authenticated)
    @select_acl = []
    @result_acl = []
    @set_acl = []
    @create_acl = []
  end

  # Read the msi file, and return it tagged as JSON
  rmethod :read do |select_on: nil, set: nil, result: nil, order_by: nil, **_args| # rubocop:disable Lint/UnusedBlockArgument"
    antenna = select_on['antenna']
    # Antenna names can only have Alphanumeric _ and -
    raise 'Bad Antenna name' unless antenna.match?(/\A[\w\-_]+\z/)

    begin
      pattern = JSON.parse(File.read("#{WWW_DIR}/Antenna/patterns/#{antenna}.json"))
    rescue Errno::ENOENT => _e
      raise 'Bad Antenna name'
    end
    return pattern
  end

  # antenna of Antennas msi files.
  rmethod :antenna do |select_on: nil, set: nil, result: nil, order_by: nil, **_args| # rubocop:disable Lint/UnusedBlockArgument"
    # Changing antenna means our antennaing doesn't have the full path
    Dir.chdir("#{WWW_DIR}/Antenna/patterns/")
    antenna = Dir.glob('*.json')
    # Drop the .json extensions
    antenna.collect! { |s| s.gsub(/\.json/, '') }
    return { 'antenna' => antenna }
  end
end
