require 'cinch'
require 'redditkit'
require 'thread'

$triggers = []
$triggered = []
$bot = "lol"

bot_thread = Thread.new do
  $bot = Cinch::Bot.new do
    configure do |c|
      c.nick = "reddit"
      c.realname = "reddit"
      c.server = "irc.amazdong.com"
      c.channels = [ "#reddit" ]
    end

    on :message, /reddit: watch for \/([^\/]+)\// do |m, message|
      if $triggers.include? message
        m.reply "I'm already watching for /#{message}/"
      else
        $triggers << message
        m.reply "Okay, I'll watch for /#{message}/"
      end
    end

    on :message, /reddit: stop watching \/([^\/]+)\// do |m, message|
      if $triggers.include? message
        m.reply "Okay, I'll stop watching /#{message}/"
        $triggers.delete message
      else
        m.reply "I wasn't watching for /#{message}/, silly"
      end
    end
  end

  $bot.start
end

sleep 15; puts "IRC initialized"

reddit_thread = Thread.new do
  reddit = RedditKit::Client.new 'wizard_of_dong', 'dongdong'
  $bot.channels.first.send "Ready to start watching reddit! :)"
  while true
    comments = reddit.front_page.flat_map { |link| reddit.comments link }
    comments.compact.each do |comment|
      next if $triggered.include? comment.id

      $triggers.each do |trigger|
        if comment.body =~ /#{trigger}/
          $bot.channels.first.send "A comment by #{comment.author} matched /#{trigger}/: #{comment.body.truncate(100)}"
          $triggered << comment.id
        end
      end
    end

    sleep 60
  end
end

[bot_thread, reddit_thread].each { |thread| thread.join }