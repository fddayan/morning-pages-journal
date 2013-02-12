require 'date'
require 'rainbow'

module MorningPagesJournal

    class Page
      attr_reader :file_path

      def initialize(file_path)
        @file_path = file_path
      end

      def date
        s = @file_path.split("/")

        year_month = s[s.size-2]
        day = s[s.size-1].split(".")[0]

        Date.parse("#{year_month}-#{day}")
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

      def each_day
        min = pages.first.date
        max = pages.last.date

        min.upto(max).each do |date|
          yield date
        end
      end

      def min_date
        pages.first.date
      end

      def max_date
        pages.last.date
      end

      def word_count
        hash = Hash.new(0)
        pages.each do |p|
          p.word_count(hash)
        end
        hash
      end

      def average_words
        w = pages.collect {|p| p.words.to_i}
        w.inject(0.0) { |sum, el| sum + el } / w.size
      end

      private

        def pages_files
          Dir.glob("#{File.expand_path(@base_folder)}/**/*").reject {|fn| File.directory?(fn) }
        end
    end

    class CLI

      def initialize(command_line_arguments)
        @opts = command_line_arguments
      end

      def opts
        @opts
      end

      def config
        unless File.exists?(opts[:config])
          File.open(opts[:config],"w+") do |f|
            f.write YAML::dump({
                "editor" => "mate",
                "folder" => "~/Documents/journal/"
              })
          end
        end

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

      def list
        puts "Lists"
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])

        month_name = ""
        total_words = 0
        journal.each_day do |date|
          if month_name != date.strftime("%B")
            # if month_name != ""
              # puts "Total #{total_words}"
              # total_words = 0
            # end
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

      def stat
        journal = MorningPagesJournal::Journal.new(:base_folder => config["folder"])

        days = (journal.max_date - journal.min_date).to_i
        missed = days - journal.pages.size

        puts "Average Words:\t#{journal.average_words}\n"
        puts "From:\t#{journal.max_date}"
        puts "To:\t#{journal.min_date}"
        puts "Total days:\t#{days}"
        puts "Morning pages:\t#{journal.pages.size}"
        puts "Missed:\t#{missed}"
        puts "\n"
        journal.word_count.sort_by {|k,v| v}.reverse.take(stats_words).each do |e|
           puts "#{e[0]}\t#{e[1]}"
        end

        # h = Hash.new(0)
        # journal.pages.first.word_count(h)#.each do |e|
        # # .sort_by {|k,v| v}.reverse.each do |e|
        #   # p e
        # #end

        # p h
      end

    end


end