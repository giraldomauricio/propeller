require "propeller/version"
require 'parallel'
require 'yaml'
require 'httparty'
require 'benchmark'

module Propeller

  def self.argumentsHelp

    puts "propeller -f:YAML_File [-output:'screen,junit'] [-help]"
    puts "-help : This help screen."
    puts "-f : Configuration file."

  end

  def self.tester
    res = ""
    results = Parallel.map(['a','b','c'], :in_threads=>3) do |one_letter|
      res = res + one_letter
    end
    res
  end

  def self.run args

    path_to_yaml = nil

    output = "screen"

    output_file = "results.xml"

    if args
      args.each do|argument|

        arg = argument.split(':')


        case arg[0]
          when "-f"
            path_to_yaml = arg[1]
          when "-help"
            argumentsHelp
          when "-output"
            output = arg[1]
          when "-output_file"
            output_file = arg[1]
        end

      end

      if(path_to_yaml && File.exists?(path_to_yaml))

        suites = {errors: 0, failures: 0, skipped: 0, tests: 0, time: 0, timestamp: 0, suite:[]}
        suite = {errors: 0, failures: 0, skipped: 0, tests: 0, time: 0, name: 'Propeller Test', testcases: []}

        params = load_params(path_to_yaml)
        runs = 0
        url = params['Resources']['url']
        success = 0
        fails = 0
        ok = 0
        not_found = 0
        error = 0
        url_response = nil
        code = 200
        time = Benchmark.realtime {
          Parallel.in_processes(params['Resources']['threads']) do
            #begin
              Parallel.map(params['Resources']['urls']) do |address|
                runs = runs + 1
                elapsed_time = Benchmark.realtime {
                  if(params['Resources']['params'])
                    begin
                      url_response = HTTParty.post(address, :body => params['Resources']['params'], :verify => false)
                      code = url_response.code
                    rescue
                      code = 700
                    end
                  else
                    begin
                      url_response = HTTParty.get(address, :verify => false)
                      code = url_response.code
                    rescue
                      code = 700
                    end

                  end
                }
                testcase = {name: address, time: elapsed_time, failures: []}
                case code
                  when 200
                    ok = ok + 1
                    success = success + 1
                  when 404
                    not_found = not_found + 1
                    failure = {message:"Page not found", detail: address}
                    testcase[:failures] << failure
                  when 500...600
                    error = error + 1
                    failure = {message:"Error page", detail:"Error " + url_response.code.to_s}
                    testcase[:failures] << failure
                  when 700
                    error = error + 1
                    failure = {message:"Timeout", detail:"Timeout: " + address}
                    testcase[:failures] << failure
                end

                if(params['Resources']['assert'])
                  if(params['Resources']['assert']['max_time'])
                    if(elapsed_time.to_f > params['Resources']['assert']['max_time'].to_f )
                      failure = {message:"Response time exceeded", detail:"Response time exceeded expected value. Expected max = " + params['Resources']['assert']['max_time'].to_s + ", Received = " + elapsed_time.to_s}
                      #puts failure[:message]
                      error = error + 1
                      fails = fails + 1
                      testcase[:failures] << failure
                      suite[:error] = 1
                      suite[:failures] = 1
                    end
                  end
                end
                suite[:time] = elapsed_time.to_s
                suite[:testcases] << testcase
              end
            #rescue Exception => e
              #puts e.inspect
              #fails = fails + 1
            #end
          end
        }
        suite[:tests] = runs
        suites[:errors] = error
        suites[:failures] = fails
        suites[:tests] = runs
        suites[:time] = time.to_s
        suites[:timestamp] = DateTime.now
        suites[:suite] << suite
        if output == 'junit'
          File.open(output_file, 'w') { |file| file.write(junit_output suites) }
          result = "Results exported to " + output_file
        else
          result = {runs: runs, result: 'Success', success: success, fails: fails, elapsed: time, ok: ok, not_found: not_found, error: error}
        end
      else
        result = 'Propeller requires a configuration file'
      end
    else
      result = 'No arguments provided'
    end
    puts result
    result
  end
  
  def self.verify_params path_to_yaml
    load_params path_to_yaml
  end

  def self.load_params(path_to_yaml)
    params = YAML.load_file(path_to_yaml)
    params
  end

  def self.junit_output suites

    xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    xml = xml + "<testsuites errors=\"#{suites[:errors].to_s}\" failures=\"#{suites[:failures].to_s}\" skipped=\"0\" tests=\"#{suites[:tests].to_s}\" time=\"#{suites[:time].to_s}\" timestamp=\"#{suites[:timestamp].to_s}\">\n"
    xml = xml + "\t<testsuite name=\"Propeller Tests\" tests=\"#{suites[:suite][0][:tests].to_s}\" errors=\"#{suites[:suite][0][:errors].to_s}\" failures=\"#{suites[:suite][0][:failures].to_s}\" skipped=\"0\"><properties/>\n"
    suites[:suite][0][:testcases].each { |test|
      if(test[:failures].length > 0)
        failures = ""
        test[:failures].each { |failure|
          failures = failures + "<failure message='" + failure[:message] + "'>" + failure[:detail] + "</failure>\n"
        }
        xml = xml + "\t\t<testcase name=\"#{test[:name]}\" time=\"#{test[:time]}\">" + failures + "</testcase>\n"
      else
        xml = xml + "\t\t<testcase name=\"#{test[:name]}\" time=\"#{test[:time]}\"></testcase>\n"
      end

    }
    xml = xml + "\t</testsuite>\n"
    xml = xml + "\t</testsuites>\n"
    xml
  end

  private_class_method :load_params

end
