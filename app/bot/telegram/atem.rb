require_relative 'commands/general'
require_relative 'commands/randomCard'
require_relative 'commands/searchCard'
require_relative 'commands/listCard'
require_relative 'commands/pictCard'

class Atem
  COMMAND_PREFIX = '/'.freeze

  COMMANDS = {
    start: %w[/start /welcome /help],
    info: ['/info'],
    random: ['/random'],
    search: ['/search']
    #searchlist: ['/searchlist']
  }.freeze

  def self.start
    logger = Logger.new($stdout)
    logger.level = Logger::INFO

    Telegram::Bot::Client.run(TOKEN, allowed_updates: ['message']) do |bot|
      bot.listen do |message|
        next unless message.is_a?(Telegram::Bot::Types::Message)
        next unless message.text

        text = message.text.to_s.strip

        handle_message(bot, message, text)

        logger.info "Received from @#{message.from.username}: #{message.text}"
      end
    end
  end

  private

  def self.handle_message(bot, message, text)
    chat_id = message.chat.id

    case
    when COMMANDS[:start].include?(text)
      send_message(bot, chat_id, General.help)
    when COMMANDS[:info].include?(text)
      send_info_message(bot, chat_id)
    when COMMANDS[:random].include?(text)
      hit_random = Random.random_card

      bot.api.send_photo(
        chat_id: chat_id,
        photo: hit_random[:image],
        caption: hit_random[:message],
        parse_mode: 'Markdown'
      )
    when COMMANDS[:search].include?(text)
      send_message(bot, chat_id, '/search <name card>')
      #when COMMANDS[:searchlist].include?(text)
      #send_message(bot, chat_id, '/searchlist <name card>')
    when text.start_with?("#{COMMANDS[:search][0]} ")
      handle_search(bot, chat_id, text.sub("#{COMMANDS[:search][0]} ", ''))
      # when text.start_with?("#{COMMANDS[:searchlist][0]} ")
      #   handle_searchlist(
      #     bot,
      #     chat_id,
      #     text.sub("#{COMMANDS[:searchlist][0]} ", '')
      #   )
    when text.include?('::')
      handle_shorthand_search(bot, chat_id, text)
    end
  end

  def self.send_message(bot, chat_id, text, parse_mode = 'Markdown')
    bot.api.send_message(chat_id: chat_id, text: text, parse_mode: parse_mode)
  end

  def self.send_info_message(bot, chat_id)
    callback = [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Source code',
        url: General.sourcecode
      )
    ]
    markup =
      Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [callback]
      )

    bot.api.send_message(
      chat_id: chat_id,
      text: General.info,
      parse_mode: 'Markdown',
      reply_markup: markup
    )
  end

  def self.handle_search(bot, chat_id, keyword)
    bot.api.send_photo(
      chat_id: chat_id,
      photo: Pict.link(keyword),
      caption: Search.message(keyword),
      parse_mode: 'Markdown'
    )
  end

  def self.handle_searchlist(bot, chat_id, keyword)
    send_message(bot, chat_id, Searchlist.message(keyword))
  end

  def self.handle_shorthand_search(bot, chat_id, text)
    if match = text.match(/::(.+)::/)
      keyword = match[1]
      handle_search(bot, chat_id, keyword)
    end
  end
end
