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
    puts "Fetching newest front page comments"
    comments = reddit.front_page.flat_map { |link| reddit.comments link }
    puts "Fetched #{comments.length} comments!"
    comments.compact.each do |comment|
      puts "Debug: checking #{comment.body}"
      puts "-"*20
      next if $triggered.include? comment.id

      $triggers.each do |trigger|
        puts "CHECKING TRIGGER #{trigger}"
        if comment.body =~ /#{trigger}/
          puts "FOUND A TRIGGER MATCH"
          $bot.channels.first.send "A comment by #{comment.author} matched /#{trigger}/: #{comment.body.truncate(100)}"
          puts "triggered"
          $triggered << comment.id
          puts "triggered x2"
        end
        puts "No match"
      end
      puts "next comment?"
    end

    puts "Sleepin'"
    sleep 30
    puts "Waking up"
  end
end

[bot_thread, reddit_thread].each { |thread| thread.join }