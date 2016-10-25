require 'rake'
require 'rake/clean'
require 'tmpdir'

RAW_FILES = Rake::FileList.new("*features.csv.raw")
STRIP_FILES = RAW_FILES.ext(".strip")
TRANS_FILES = STRIP_FILES.ext(".trans")
SORT_FILES = TRANS_FILES.ext(".sort")
PROCESSED_FILES = SORT_FILES.ext("")
WORDS_TO_DROP = %W(bowling crow rain)

FEATURE_FILES = Rake::FileList.new("*_features.csv")
MODEL_FILES_TO_BUILD = FEATURE_FILES.sub("features","norm_model")
MODEL_FILES = Rake::FileList.new("*_{next,norm}_model.csv")

STRIP_FILES.zip(RAW_FILES).each do |target, source|
  file target  => [source] do |t|
    bn = File.basename(source,".csv.raw")
    sh "sed '1,2d' #{source} > tmp01"
    sh "cut -d',' -f3- tmp01 > tmp02"
    sh "head -1 tmp02|cut -d',' -f2- | tr ',' '\\n' > #{bn}_words.txt.unsorted"
    sh "sed '1d' tmp02 > tmp03"
    sh "cut -d',' -f1 tmp03 > #{bn}_features.txt"
    sh "cut -d',' -f2- tmp03 > #{target}"
    rm "tmp01"
    rm "tmp02"
    rm "tmp03"
  end
end
TRANS_FILES.zip(STRIP_FILES).each do |target, source|
  file target  => [source] do |t|
    features = []
    File.foreach(source) do |line|
      features.push(line.chomp.split(','))
    end
    File.open(target, 'w') do |f|
      features.transpose.each do |row|
        f.write(row.join(',')+"\n")
      end
    end
  end
end
SORT_FILES.zip(TRANS_FILES).each do |target, source|
  file target  => [source] do |t|
    bn = File.basename(source,".csv.trans")
    words_unsorted = "#{bn}_words.txt.unsorted"
    words = "#{bn}_words.txt"
    sh "paste -d',' #{words_unsorted} #{source}|sort>#{target}"
    sh "sort #{words_unsorted} > #{words}"
  end
end
PROCESSED_FILES.zip(SORT_FILES).each do |target, source|
  file target  => [source] do |t|
    dropExpressions = []
    WORDS_TO_DROP.each do |w|
      dropExpressions.push("-e '/^#{w}/d'")
    end
    sh "sed #{dropExpressions.join(' ')}  #{source} > #{target}"
  end
end
file "combined_features.csv" => PROCESSED_FILES do |f|
  combList = []
  PROCESSED_FILES.each_with_index do |p,i|
    if (i==0) then
      combList.push(p)
    else
      sh("cut -d, -f2- #{p} > #{p.ext(".tmp")}")
      combList.push(p.ext(".tmp"))
    end
  end
  sh("paste -d, #{combList.join(' ')} > #{f.name}")
  combList.shift()
  combList.each do |c|
    rm_rf c
  end
end

desc "Preprocess the feature norm files"
task :process => ["combine","clean"]

desc "Remove junk rows and columns from raw files."
task :strip => STRIP_FILES

desc "Transpose feature by word to word by feature."
task :transpose => TRANS_FILES

desc "Sort rows alphabetically by word"
task :sort => SORT_FILES

desc "Drop rows corresponding to words_to_drop"
task :drop => PROCESSED_FILES

desc "Combine transposed feature files, columnwise."
task :combine => "combined_features.csv"

task :default => [:combine]

CLEAN.include(STRIP_FILES)
CLEAN.include(TRANS_FILES)
CLEAN.include(SORT_FILES)
CLOBBER.include(PROCESSED_FILES)
CLOBBER.include("combined_features.csv")
