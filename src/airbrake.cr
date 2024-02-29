require "json"
require "http/client"

require "./airbrake/*"

module Airbrake
  module Backtrace
    # Examples:
    #   *raise<String>:NoReturn +70 [0]
    #   *Crystal::CodeGenVisitor#visit<Crystal::CodeGenVisitor, Crystal::Assign>:(Nil | Bool) +534 [0]
    STACKFRAME_TEMPLATE = /\A(.+)? \+(\d+)/

    def self.parse(exception)
      backtrace = exception.backtrace? ? exception.backtrace : [] of String
      backtrace.map do |stackframe|
        pp stackframe
        if m = stackframe.match(STACKFRAME_TEMPLATE)
          { file: m[1]? || "<crystal>" , line: m[2]?.try(&.to_i) || 0, function: "<file>" }
        else
          { file: "<crystal>", line: 0, function: "<file>" }
        end
      end
    end
  end

  class Notice
    property payload : NamedTuple(notifier: NamedTuple(name: String, version: String, url: String), errors: Array(NamedTuple(type: String, message: String | Nil, backtrace: Array(NamedTuple(file: String, line: Int32, function: String)))), context: NamedTuple(os: String, language: String), environment: Hash(Symbol, Hash(String, String)), params: Hash(String, Hash(String, String)))

    def initialize(exception)
      @payload = {
        notifier: {
          name: "Airbrake Crystal",
          version: Airbrake::VERSION,
          url: "https://github.com/TGFerox/airbrake-cr",
        },
        errors: [{ type: exception.class.name,
                   message: exception.message,
                   backtrace: Backtrace.parse(exception) }],
        context: {
          os: {{`uname -a`.stringify}},
          language: {{`crystal -v`.stringify}}
        },
        environment: {} of Symbol => Hash(String, String),
        params: {} of String => Hash(String, String)
      }
    end

    def to_json(io)
      @payload.to_json(io)
    end
  end

  class Config
    property project_id : Int32?
    property project_key : String?
    property endpoint : String?

    def uri
      self.endpoint ||= "https://airbrake.io"

      uri       = URI.parse(endpoint.to_s)
      uri.path  = "/api/v3/projects/#{project_id}/notices"
      uri.query = "key=#{project_key}"
      uri
    end
  end

  module Sender
    def self.send(notice)
      response = HTTP::Client.post(
        Airbrake.config.uri,
        headers: HTTP::Headers{ "Content-Type" => "application/json",
                                "User-Agent" => "Airbrake Crystal" },
        body: notice.to_json)

      Hash(String, String).from_json(response.body)
    end
  end

  class AirbrakeError < Exception
  end

  def self.notify(exception)
    unless [config.project_id, config.project_key].all?
      raise AirbrakeError.new("both :project_id and :project_key are required")
    end
    send_payload(build_notice(exception))
  end

  def self.build_notice(exception)
    Notice.new(exception)
  end

  def self.send_payload(notice)
    Sender.send(notice)
  end

  def self.configure
    @@configuration = Config.new
    yield config
  end

  def self.config
    @@configuration ||= Config.new
  end
end
