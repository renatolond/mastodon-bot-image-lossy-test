# frozen_string_literal: true

require_relative "environment"

Environment.load

require "uri"

module Mastodon
  # Monkey-patch the client class for allowing overwriting the user-agent
  class Client
    attr_writer :user_agent
  end
end

ATTEMPT_NUMBER_RE = /(?<=#)[0-9]+/

# @param mastodon_client [Object]
# @param media [Mastodon::Entities::Media]
# @param file [Tempfile] The temp file containing the media to be uploaded
# @param retries [Integer] Number of retries in case of HTTP failure
# @return [Integer] The id of the newly updated media
def upload_media(mastodon_client, media, file, retries = 3)
  opts = {}
  if media.description
    opts[:description] = media.description
    attempt_number = opts[:description].match(ATTEMPT_NUMBER_RE)[0].to_i
    opts[:description].gsub!("##{attempt_number}", "##{attempt_number + 1}")
  end
  returned_media = mastodon_client.upload_media(file, opts)
  returned_media.id
rescue HTTP::Error => e
  retry unless (retries -= 1).zero?
  raise e
end

mc = Mastodon::REST::Client.new(base_url: ENV.fetch("MASTODON_DOMAIN", nil), bearer_token: ENV.fetch("TOKEN", nil), timeout: { read: 20 })
mc.user_agent = "#{mc.user_agent} (mastodon-bot-image-lossy-test)"
if ENV.fetch("MASTODON_USER_ID", nil).nil?
  puts "Your user id is #{mc.verify_credentials.id}. Add this to your .env file as MASTODON_USER_ID."
  exit(-99)
end
mastodon_user_id = ENV.fetch("MASTODON_USER_ID")
toot = mc.statuses(mastodon_user_id)
         .first

text = toot.content
text.gsub!(%r{(^<p>|</p>$)}, "")

attempt_number = text.match(ATTEMPT_NUMBER_RE)[0].to_i
text.gsub!("##{attempt_number}", "##{attempt_number + 1}")

idempotency_key = toot.id
media_ids = []
# Download file
toot.media_attachments.each do |media|
  url = URI.parse(media.url)
  url.query = nil
  url.to_s

  file = Tempfile.new(["media", File.extname(url)], "./tmp")
  file.binmode

  file.write HTTParty.get(media.url).body
  file.rewind

  media_ids << upload_media(mc, media, file)
end

opts = { media_ids: }
opts[:headers] = { "Idempotency-Key" => idempotency_key }
mc.create_status(text, opts)
