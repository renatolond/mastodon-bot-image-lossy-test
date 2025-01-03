# frozen_string_literal: true

require_relative "environment"

Environment.load

require "uri"

# @param url [URI] The url of the media to calculate the checksum
# @return [String] The digest of the file
def md5sum_of_url(url)
  file = Tempfile.new(["media", File.extname(url)], "./tmp")
  file.binmode

  file.write HTTParty.get(url).body
  file.rewind
  Digest::MD5.hexdigest file.read
end

module Mastodon
  # Monkey-patch the client class for allowing overwriting the user-agent
  class Client
    attr_writer :user_agent
  end
end

mc = Mastodon::REST::Client.new(base_url: ENV.fetch("MASTODON_DOMAIN", nil), bearer_token: ENV.fetch("TOKEN", nil), timeout: { read: 20 })
mc.user_agent = "#{mc.user_agent} (mastodon-bot-image-lossy-test)"
if ENV.fetch("MASTODON_USER_ID", nil).nil?
  puts "Your user id is #{mc.verify_credentials.id}. Add this to your .env file as MASTODON_USER_ID."
  exit(-99)
end
mastodon_user_id = ENV.fetch("MASTODON_USER_ID")
toots = mc.statuses(mastodon_user_id)

md5sums = Hash.new { |h, k| h[k] = {} }

toots.each_cons(2) do |toot1, toot2|
  raise "Unexpected number of images!!" if toot1.media_attachments.size > 1 || toot2.media_attachments.size > 1

  toot1.media_attachments.each do |media|
    next if md5sums[toot1.id][media.id]

    url = URI.parse(media.url)
    url.query = nil
    md5sums[toot1.id] = md5sum_of_url(url)
  end

  toot2.media_attachments.each do |media|
    next if md5sums[toot2.id][media.id]

    url = URI.parse(media.url)
    url.query = nil
    md5sums[toot2.id] = md5sum_of_url(url)
  end
end

md5sums.each_cons(2) do |a, b|
  id_a, checksum_a = a
  _id_b, checksum_b = b

  break unless checksum_a == checksum_b

  mc.destroy_status(id_a)
end
