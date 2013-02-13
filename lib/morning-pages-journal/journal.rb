require 'date'
require 'rainbow'

module MorningPagesJournal

    class Page
      attr_reader :file_path

      def initialize(file_path)
        @file_path = file_path
      end

      def date
        return @date if @date

        s = @file_path.split("/")

        year_month = s[s.size-2]
        day = s[s.size-1].split(".")[0]

        @date = Date.parse("#{year_month}-#{day}")
        @date
      end

      def words
        @count ||= `wc -w #{@file_path}`.split(" ")[0]
      end

      def word_count(hash = Hash.new(0))
        content.split.inject(hash) { |h,v| h[v] += 1; h }
      end

      def content
        File.open(@file_path).read
      end

    end

    class Journal

      def initialize(options)
        raise "Base folder is required" unless options[:base_folder]
        @base_folder = options[:base_folder]
      end

      def today_folder
         folder = Date.today.strftime("%Y-%m")
         File.join(@base_folder,folder)
      end

      def today_file
        file_name = Date.today.strftime("%d")
        File.join(today_folder,"#{file_name}.txt")
      end

      def pages
        @pages ||= pages_files.collect { |path| Page.new(path) }.sort { |a, b| a.date <=> a.date }
      end

      def get_page(date)
        @pages.select {|p| p.date == date }.first
      end

      def each_day(range = :month)
        return if pages.empty?
        max = pages.last.date
        min = date_starting_at(max, range)

        min.upto(max).each do |date|
          yield date
        end
      end

      def min_date(range = :month)
        # pages.first.date
        date_starting_at(max_date,range)
      end

      def max_date
        pages.last.date
      end

      def word_count(range=:month)
        hash = Hash.new(0)
        pages_from(min_date(range),max_date).each do |p|
          p.word_count(hash)
        end
        hash
      end

      def average_words
        w = pages.collect {|p| p.words.to_i}
        w.inject(0.0) { |sum, el| sum + el } / w.size
      end

      def pages_from(from,to)
        pages.select do |p|
          p.date >= from && p.date <= to
        end
      end

      private

        def pages_files
          Dir.glob("#{File.expand_path(@base_folder)}/**/*").reject {|fn| File.directory?(fn) }
        end

        def date_starting_at(date,range)
         case range
            when :day then date
            when :week then date - (date.wday-1)
            when :month then date - (date.mday-1)
            when :year then date - (date.yday-1)
          end
        end
    end

    class CLI

      def initialize(command_line_arguments)
        @opts = command_line_arguments
        @opts[:config] = File.expand_path(@opts[:config])
      end

      def opts
        @opts
      end

      def config
        create_config_if_not_exists!

        @config ||= YAML::load(File.open(opts[:config]))
      end


      def config_words
        config["words"] || 750
      end

      def stats_words
        (config["stats"] || 50).to_i
      end

      def open
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])
        editor = config["editor"]

        system "mkdir -p #{journal.today_folder} ; #{editor} #{journal.today_file}"
      end

      def list(options)
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])

        month_name = ""
        total_words = 0
        journal.each_day(options[:range]) do |date|
          if month_name != date.strftime("%B")
            month_name = date.strftime("%B")
            puts month_name
            puts "-" * 100
          end

          page = journal.get_page(date)

          words,color =  if page
                            if page.words.to_i < config_words
                              [page.words.to_i, :red]
                            else
                              [page.words.to_i, :green]
                            end
                          else
                            [0,:yellow]
                          end

          total_words += words
          puts "#{date.strftime('%a, %d')}\t#{words.to_s.color(color)}\t" + ("="* (words/10).to_i).color(color)

          if date.strftime('%a') == "Sat"
            puts ""
          end
        end
      end

      def stat(options)
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])

        min_date = journal.min_date(options[:range])
        days = ((journal.max_date+1) - min_date).to_i
        morning_pages = journal.pages_from(min_date,journal.max_date).size
        missed = days - morning_pages

        puts "Average Words:\t#{journal.average_words.to_i}\n"
        puts "From:\t#{min_date}"
        puts "To:\t#{journal.max_date}"
        puts "Total days:\t#{days}"
        puts "Morning pages:\t#{morning_pages}"
        puts "Missed:\t#{missed}"
        puts "\n"
      end

      def words(options)
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])
        journal.word_count(options[:range]).sort_by {|k,v| v}.reverse.take(stats_words).each do |e|
           puts "#{e[0]}\t#{e[1]}"
        end
      end

      def update_config(key,value)
        c = config
        c[key] = value

        File.open(opts[:config],"w+") do |f|
          f.write YAML::dump(c)
        end
      end

      private

        def create_config_if_not_exists!
          unless File.exists?(opts[:config])
            File.open(opts[:config],"w+") do |f|
              f.write YAML::dump({
                  "editor" => "mate",
                  "folder" => "~/.morning-pages/",
                  "words" => 750,
                  "stats" => 50
                })
            end
          end

        end

    end


end