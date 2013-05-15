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
      #'i',
      'ii', 'iii', 'iv', 'v',
      # 'vi', 'vii', 'viii', 'ix', 'x', 'xi', 'xii', 'xiii', 'xiv', 'xv', 'xvi', 'xvii', 'xviii', 'xix', 'xx',
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
      'do', 'd.o.', 'd.o', 'dds', 'd.d.s.',
      'esq', 'esq.',
      'md', 'm.d.', 'm.d',
      'mr.', 'ms.', 'mrs.',
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
      'dean.',
      'dir.', 'dr', 'dr.',
      'exec.',
      'general', 'gen', 'gen.',
      'honorable', 'hon', 'hon.', 'honret.',
      'interim', 'instructor',  # va law
      'judge', 'justice', 'chiefjustice',
      'lieutenant', 'lcdr', 'lt', 'lt.', 'ltc', 'ltc.', 'ltcol.', 'ltcol', 'ltjg', 
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
    
    def parse_fullname(name)
      first_name  = nil
      middle_name = nil
      last_name   = nil
      prefix      = nil
      suffix      = nil
      
      # replace "’" to "'"
      name = name.gsub(/’/, "'")
      # remove strings which contain and include in parentheses
      # ex. 'Susan M. (Scully) Schultz'  =>  'Susan M. Schultz'
      #     'Jay (Jung) Heum Kim'        =>  'Jay Heum Kim'
      name = name.gsub(/\(.*?\)/, ' ').gsub(/\(|\)/, '')
      # remove quoted strings 
      # Darin "Derry" Ronald Anderson    => 'Darin Ronald Anderson'
      # Nancy M. "Shelli" Egger          => 'Nancy M. Egger'  
      # Nicole 'nikki' Adame             => 'Nicole Adame'                  
      name = name.gsub(/".*?"/, ' ').gsub(/'.*?'/i, ' ')
  
      # remove curly brackets
      # Henry C.{Harry} Wilson           => 'Henry C. Wilson'
      # Cellestine {Steen} Armstrong     => 'Cellestine Armstrong'
      name = name.gsub(/\{.*?\}/, ' ')
      # remove exceptional names
      # ex. "William . D. 'Bill' Beard"  =>  "William D. 'Bill' Beard"
      # also this regexp can remove 
      name = name.gsub(/\s+[^a-zA-Z]+\s+/, ' ')
      # Why we use substitute(sub) comma to whitespace, not global substitute(gsub).
      # the reason is the substitution applies for suffix splitting, not for replacing
      # bad data. As we want, convert "Marvene A Gordon, JD" to "Marvene A Gordon JD", 
      # so that the suffix will get into the split array.
      # and, standardize suffix as '2nd' => 'II', '3rd' => 'III'
      nameSplit   = name.gsub(',', ' ').strip.split(/\s+/).map{ |n| CONVERSION[n.downcase] || n }
  
      return { :last=>name } if nameSplit.length <= 1
      
      suffix_arr  = []
      while (nameSplit.length > 1)
        if IGNORABLE_SUFFIXES.include?(nameSplit.last.downcase)
          suffix_arr.unshift([nameSplit.pop, false])
        elsif SUFFIX_LIST.include?(nameSplit.last.downcase) || GLOBAL_SUFFIX_LIST.include?(nameSplit.last.downcase)
          suffix_arr.unshift([nameSplit.pop, true])
        else
          break
        end
      end
  
      # Loop around until we run into a name that is not contained in the PREFIX_LIST
      # ex(FL): 'Lt Col Marvene A Gordon', 'The Honorable Dexter F George'
      prefix_arr      = []
      while (nameSplit.length > 1)
        if IGNORABLE_PREFIXS.include?(nameSplit.first.downcase)
          nameSplit.shift
        elsif PREFIX_LIST.include?(nameSplit.first.downcase)
          prefix_arr.push(nameSplit.shift)
        else
          break
        end
      end
      prefix = prefix_arr.join(' ') if prefix_arr.size > 0
  
      # Loop around until we run into a name that is not contained in the LAST_NAME_EXTENSIONS
      last_name_arr  = []
      last_name_arr.push(nameSplit.pop)
      last_name_arr.push(nameSplit.pop) while nameSplit.length > 1 && LAST_NAME_EXTENSIONS.include?(nameSplit.last.downcase)
      last_name = last_name_arr.reverse.join(' ') if last_name_arr.size > 0
  
      first_name  = nameSplit.shift     if nameSplit.length >= 1
      middle_name = nameSplit.join(' ') if nameSplit.length > 0
      if first_name.nil? && prefix
        first_name = prefix
        prefix     = nil
      end
      
      if first_name.nil? && suffix_arr.any? && SUFFIX_CAN_BE_LASTNAME.include?(suffix_arr.first.first.downcase)
        first_name = last_name
        last_name = suffix_arr.shift.first
      end
      if last_name =~ /^[A-Z]\.?$/i && suffix_arr.any? && SUFFIX_CAN_BE_LASTNAME.include?(suffix_arr.first.first.downcase)
        middle_name = [middle_name, last_name].compact.join(' ')
        last_name = suffix_arr.shift.first
      end
      suffix_arr.delete_if{|a, b| !b}
      suffix = suffix_arr.size == 0 ? nil : suffix_arr.first.first # only return first suffix
      return { :last => last_name, :middle => middle_name, :first => first_name, :prefix => prefix, :suffix => suffix }
    end # << parse_fullname
    extend self
  end
end
