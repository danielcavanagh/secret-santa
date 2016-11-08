#!/bin/env ruby
# encoding: utf-8

require 'gmail'
require 'json'

$stdout.sync = true

def find_pairs(pairings, santas, recipients)
  if santas.empty? then [pairings, santas, recipients]
  else
    recipients.lazy
      .each_with_index
      .map {|recipient, i|
        santas.first[:email] != recipient[:email] and
        not santas.first[:exclusions].include?(recipient[:email]) and
        find_pairs(pairings + [{ from: santas.first, to: recipient }], santas[1..-1], recipients[0...i] + recipients[i + 1..-1])
      }.find {|r| r }
  end
end

def pair_up(santas)
  find_pairs([], santas, santas.shuffle).first
end

options = {
  pair: false,
  test: false
}

while ARGV.first[0] == '-'
  case ARGV.shift
  when '-p' then options[:pair] = true
  when '-t' then options[:test] = true
  end
end

data = File.open(ARGV.first).read()
santas = JSON.parse(data, symbolize_names: true)
pairings = pair_up(santas)

if options[:pair] or options[:test]
  puts 'pairings:'
  puts pairings.map {|p| p.dig(:from, :email) + ' -> ' + p.dig(:to, :email) }.join("\n")
else puts 'paired'
end

if not options[:pair]
  Gmail.new('danielcavanagh85@gmail.com', '8KLa7gYn1') do |gmail|
    pairings.each do |pair|
      gmail.deliver do
        to options[:test] ? 'danielcavanagh85@gmail.com' : pair.dig(:from, :email)
        subject 'Secret Santa 2016 for ' + pair.dig(:from, :name) + ' (NO PEEKING, PARTNERS)'
        html_part do
          content_type 'text/html; charset=UTF-8'
          body '<p>This year you are secret santa for <strong>' + pair.dig(:to, :name) + '</strong>.</p>' +
               '<p>The present limit is <strong>$100</strong>.</p>' +
               '<p>Remember to put your present ideas up on Facebook to make it easy for your secret santa!</p>' +
               '<p>Good luck, have fun :)</p>' +
               '<p><em>PS: Let Daniel know privately via SMS or Facebook if there is an issue</em></p>'
        end
      end
    end
  end

  puts 'emailed!'
end
