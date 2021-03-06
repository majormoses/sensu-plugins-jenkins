#! /usr/bin/env ruby
#
#   check-jenkins
#
# DESCRIPTION:
#   This plugin checks that the Jenkins Metrics healthcheck is healthy throughout
#   See the Jenkins Metric plugin: https://wiki.jenkins-ci.org/display/JENKINS/Metrics+Plugin
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#   gem: json
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2015, Cornel Foltea cornel.foltea@gmail.com
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'rest-client'
require 'json'

#
# Jenkins Metrics Health Check
#
class JenkinsMetricsHealthChecker < Sensu::Plugin::Check::CLI
  option :server,
         description: 'Jenkins Host',
         short: '-s SERVER',
         long: '--server SERVER',
         default: 'localhost'

  option :port,
         description: 'Jenkins Port',
         short: 'p PORT',
         long: '--port PORT',
         default: '8080'

  option :uri,
         description: 'Jenkins Metrics Healthcheck URI',
         short: '-u URI',
         long: '--uri URI',
         default: '/metrics/currentUser/healthcheck'

  option :https,
         short: '-h',
         long: '--https',
         boolean: true,
         description: 'Enabling https connections',
         default: false

  def run
    https ||= config[:https] ? 'https' : 'http'
    r = RestClient::Resource.new("#{https}://#{config[:server]}:#{config[:port]}#{config[:uri]}", timeout: 5).get
    if r.code == 200
      healthchecks = JSON.parse(r)
      healthchecks.each do |healthcheck, healthcheck_hash_value|
        if healthcheck_hash_value['healthy'] != true
          critical "Jenkins Health Parameters not OK: #{r}, #{healthcheck}"
        end
      end
      ok 'Jenkins Health Parameters are OK'
    else
      critical "Jenkins Service is not replying with a 200 response:#{r.code}, #{r.body}"
    end
  rescue Errno::ECONNREFUSED => e
    critical "Jenkins Service is not responding: #{e}"
  rescue RestClient::RequestTimeout => e
    critical "Jenkins Service Connection timed out: #{e}"
  end
end
