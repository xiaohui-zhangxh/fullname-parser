# encoding: utf-8
require File.expand_path('../parser/version', __FILE__)

module Fullname
  module Parser
  
    # When "II" or "III" or even "IV" appear in the Middle Name/Suffix slot, it can safely be assumed that they are Suffixes. 
    # (John Smith has a son named John Smith II, who has a son named John Smith III, etc.) However, nobody (except a king) 
    # puts "I" after their name to indicate that they are the "first." If anything, they put "Sr." Therefore, a letter "I" 
    # appearing in the Middle Name/Suffix slot can be assumed to be their Middle Initial.
    # So here 'i' will be removed from the GENERATION_LIST
    #
    # Also almost nobody will reach to 'v'(except a king), so all suffixes later than 'v' we won't use.
    GENERATION_LIST = [
      'ii', 'iii', 'iv', 'v', 'vi'
      # 'vii', 'viii', 'ix', 'x', 'xi', 'xii', 'xiii', 'xiv', 'xv', 'xvi', 'xvii', 'xviii', 'xix', 'xx',
    ] unless const_defined?(:GENERATION_LIST)
    
    GLOBAL_SUFFIX_LIST = GENERATION_LIST + [
      'jr', 'jr.',
      'sr', 'sr.',
    ] unless const_defined?(:GLOBAL_SUFFIX_LIST)
    
    SUFFIX_LIST = [
      'b.a.',
      'capt.', 'col.', 'cfa', 'c.f.a', 'c.f.a.', 'cpa', 'c.p.a', 'c.p.a.',
      'edd', 'ed.d',
      'mph',
      'pc', 'p.c.', 'psyd', 'psyd.', 'psy.d', 'phd', 'phd.', 'ph.d', 'ph.d.',
      'r.s.m.',
      'usn',
    ] unless const_defined?(:SUFFIX_LIST)
  
    IGNORABLE_SUFFIXES = [
      'do', 'd.o.', 'd.o', 'dds', 'd.d.s.', 'dr', 'dr.',
      'esq', 'esq.',
      # Doctor suffixes
      # http://books.google.com/books?id=J6kLNKw5baYC&pg=PA336&lpg=PA336&dq=faafp+faan+facaai&source=bl&ots=BJ4AvvSF9e&sig=Xj950-otl-X-tX_2I5DvGY4_uuE&hl=en&sa=X&ei=_9DHUdT2MOn6iwKR1oGAAw&ved=0CCoQ6AEwAA#v=onepage&q=faafp%20faan%20facaai&f=false
      'faafp', 'faan', 'facaai', 'facc', 'facd', 'facg', 'faap', 'facog', 'facp', 'facpm', 'facs', 'facsm', 'fama', 'faota', 'fapa', 'fapha', 'fcap', 'fccp', 'fcps', 'fds', 'faao', 'fics',
      'md', 'm.d.', 'm.d',
      'mr.', 'ms.', 'mrs.',
      'od', 'o.d.',
      'pa', 'p.a.', 'ps', 'p.s.',
      'jd', 'jd.', 'j.d.',
      'retd', 'ret.', 'retd.',
      'usmc',
    ] unless const_defined?(:IGNORABLE_SUFFIXES)
  
    SUFFIX_CAN_BE_LASTNAME = [
      'do',
    ] unless const_defined?(:SUFFIX_CAN_BE_LASTNAME)
    
    PREFIX_LIST = [ 
      'asst.',
      'assoc.', 'associate',  # va law
      'asst. dean', 'associate dean', 'interim dean',  # va law
      'attorney', 'atty.',
      'bg', 'bg.', 'brig', 'brig.', 'gen',
      'colonel', 'cardinal', 'capt', 'capt.', 'captain', 'cdr', 'col' , 'col.', 'congressman', 'cpt', 'cpt.', 'comm.',
      'dean.', 'dentist', 'dir.', 'doctor', 'dr', 'dr.',
      'exec.',
      'general', 'gen', 'gen.',
      'honorable', 'hon', 'hon.', 'honret.',
      'interim', 'instructor',  # va law
      'judge', 'justice', 'chiefjustice',
      'lawyer', 'lieutenant', 'lcdr', 'lt', 'lt.', 'ltc', 'ltc.', 'ltcol.', 'ltcol', 'ltjg', 
      'm/g', 'mr', 'mr.', 'mr..', 'ms', 'ms.', 'mrs', 'mrs.', 'maj', 'maj.', 'major', 'miss', 'miss.',
      'president', 'prof', 'prof.', 'professor',
      'rabbi',
      'reverend', 'rev', 'rev.',
      'sheriff',
      'sis.', 'sr', 'sr.'
    ] unless const_defined?(:PREFIX_LIST)

    IGNORABLE_PREFIXS = [
      'the',
    ] unless const_defined?(:IGNORABLE_PREFIXS)
  
    
    # These will be considered part of the last name
    LAST_NAME_EXTENSIONS = [    
      'bar', 'ben',
      'da', 'dal', 'dan', 'de', 'del', 'den', 'der', 'des', 'dela', 'della', 'di', 'do', 'du',
      'el',
      'la', 'le', 'lo',
      'mac', 'mc',
      'san',
      'st', 'st.', 'sta', 'sta.',
      'van','von', 'ver', 'vanden', 'vander'
    ] unless const_defined?(:LAST_NAME_EXTENSIONS)
    
    CONVERSION = {
      '1st' => 'I', 
      '2nd' => 'II', 
      '3rd' => 'III', 
      '4th' => 'IV',
      '5th' => 'V',
      '6th' => 'VI',
      '7th' => 'VII',
      '8th' => 'VIII',
      '9th' => 'IX',
    } unless const_defined?(:CONVERSION)
    
    class Error < StandardError; end
    class Identifier
      attr_reader :name, :original_name, :prefix, :firstname, :middlename, :lastname, :suffix
      def initialize(name)
        @original_name = name.dup
        @name = name.dup
        @prefix_list = []
        @suffix_list = []
        sanitize!
        flip_parts!
        breakup!
      end

      private

      def sanitize!
        # replace "’" to "'"
        name.gsub!(/’/, "'")
        # remove strings which contain and include in parentheses
        # ex. 'Susan M. (Scully) Schultz'  =>  'Susan M. Schultz'
        #     'Jay (Jung) Heum Kim'        =>  'Jay Heum Kim'
        name.gsub!(/\(.*?\)/, ' ')
        name.gsub!(/\(|\)/, '')
        # remove quoted strings 
        # Darin "Derry" Ronald Anderson    => 'Darin Ronald Anderson'
        # Nancy M. "Shelli" Egger          => 'Nancy M. Egger'  
        # Nicole 'nikki' Adame             => 'Nicole Adame'                  
        name.gsub!(/".*?"/, ' ')
        name.gsub!(/'.*?'/i, ' ')
    
        # remove curly brackets
        # Henry C.{Harry} Wilson           => 'Henry C. Wilson'
        # Cellestine {Steen} Armstrong     => 'Cellestine Armstrong'
        name.gsub!(/\{.*?\}/, ' ')
        
        # remove exceptional names
        # ex. "William . D. 'Bill' Beard"  =>  "William D. 'Bill' Beard"
        # also this regexp can remove 
        name.gsub!(/\s+[^a-zA-Z,]+\s+/, ' ')
        # Why we use substitute(sub) comma to whitespace, not global substitute(gsub).
        # the reason is the substitution applies for suffix splitting, not for replacing
        # bad data. As we want, convert "Marvene A Gordon, JD" to "Marvene A Gordon JD", 
        # so that the suffix will get into the split array.
        # and, standardize suffix as '2nd' => 'II', '3rd' => 'III'
        CONVERSION.each_pair do |finder, replacer|
          name.gsub!(Regexp.new("\\b#{Regexp.escape(finder)}\\b", true), replacer)
        end
      end

      def extract_suffix(str)
        list = []
        loop do
          m = /(.*)[, ](.+)/.match(str)
          break unless m
          remaining = m[1]
          last_part = m[2].strip
          last_part_downcase = last_part.downcase
          if IGNORABLE_SUFFIXES.include?(last_part_downcase)
            list.unshift([last_part, false])
          elsif SUFFIX_LIST.include?(last_part_downcase) || GLOBAL_SUFFIX_LIST.include?(last_part_downcase)
            list.unshift([last_part, true])
          else
            break
          end
          str = remaining.gsub(/[, ]+$/, '').strip
        end
        [str, list]
      end

      def extract_prefix(str)
        list = []
        loop do
          m = /(.+?)[, ](.+)/.match(str)
          break unless m
          remining = m[2]
          first_part = m[1]
          first_part_downcase = first_part.downcase
          if IGNORABLE_PREFIXS.include?(first_part_downcase)
            # skip words
          elsif PREFIX_LIST.include?(first_part_downcase)
            list.push(first_part)
          else
            break
          end
          str = remining.gsub(/^[, ]+/, '').strip
        end
        [str, list]
      end

      def extract_suffix_before_flipping_parts
        remaining, list = extract_suffix(name)
        @name = remaining
        @suffix_list += list
      end

      def flip_parts!
        extract_suffix_before_flipping_parts
        parts = name.split(/,/)
        case parts.size
        when 1
        when 2
          remining, list = extract_suffix(parts[0])
          @name = [parts[1], remining].join(' ').strip.gsub(/ +/, ' ')
          @suffix_list += list
        when 3
          remining, list = extract_suffix(parts[0..1].join(' '))
          @name = [parts[2], remining].join(' ').strip.gsub(/ +/, ' ')
          @suffix_list += list
        else
          fail Error.new("name [ #{name} ] has >2 commas, don't know how to parse")
        end

        extract_prefix_after_flipping_parts
      end

      def extract_prefix_after_flipping_parts
        remaining, list = extract_prefix(name)
        @name = remaining
        @prefix_list += list
      end

      def breakup!
        parts = name.split(/[, ]+/)

        # process prefix
        @prefix = @prefix_list.join(' ') if @prefix_list.any?

        # process lastname
        # Loop around until we run into a name that is not contained in the LAST_NAME_EXTENSIONS
        last_name_arr  = []
        last_name_arr.push(parts.pop)
        last_name_arr.push(parts.pop) while parts.length > 1 && LAST_NAME_EXTENSIONS.include?(parts.last.downcase)
        @lastname = last_name_arr.reverse.join(' ')

        # process firstname and middlename
        @firstname  = parts.shift if parts.length >= 1
        @middlename = parts.join(' ') if parts.length > 0
        if firstname.nil? && prefix
          @firstname = prefix
          @prefix    = nil
        end

        # move lastname to firstname, move first suffix to lastname
        if firstname.nil? && @suffix_list.any? && SUFFIX_CAN_BE_LASTNAME.include?(@suffix_list.first.first.downcase)
          @firstname = lastname
          @lastname = @suffix_list.shift.first
        end

        # move lastname to middlename, move first suffix to lastname
        if lastname =~ /^[A-Z]\.?$/i && @suffix_list.any? && SUFFIX_CAN_BE_LASTNAME.include?(@suffix_list.first.first.downcase)
          @middlename = [middlename, lastname].compact.join(' ')
          @lastname = @suffix_list.shift.first
        end

        # process suffix
        @suffix_list.delete_if { |_, ignore_able| !ignore_able }
        @suffix = @suffix_list.any? ? @suffix_list.first.first : nil
      end
    end

    def parse_fullname(name.strip)
      i = Identifier.new(name)
      return {
        prefix: i.prefix,
        first: i.firstname,
        middle: i.middlename,
        last: i.lastname,
        suffix: i.suffix
      }
    end # << parse_fullname
    extend self
  end
end
